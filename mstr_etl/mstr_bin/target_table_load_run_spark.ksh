#!/bin/ksh -eu
###################################################################################################################
###################################################################################################################
#
# Title:        Target Table Load Run Spark
# File Name:    target_table_load_run_spark.ksh
# Description:  Handler for Loading Target Tables from staged data
# Developer:    Pramit Mitra
# Created on:   Legacy code re-purposed on 2017-03-01
# Location:     $DW_MASTER_BIN
#
# Usage Notes: UOW_TO and UOW_FROM work in tandem. If one is passed in, then the other must be also.
# Revision History
#
#  Date         Ver#   Modified By(Name)            Change and Reason for Change
# ----------    -----  ---------------------------  ----------------------------------------------------------
# 2011-10-10     1.0   Ryan Wong                    Split main code to target_table_load_run.ksh
#                                                   Allow use of time and a redirect for log
# 2011-12-20     1.1   Ryan Wong                    Change loader_cleanup to use dw_infra.loader_cleanup.ksh
# 2013-07-29     1.2   Jacky Shen                   Add support for hadoop jar job
# 2013-10-04     1.3   Ryan Wong                    Redhat changes
# 2014-08-11     1.4   Ryan Wong                    Fix grep issue for Redhat for DB_TYPE
# 2016-07-13     1.5   Michael Weng                 Add a comment to create a push to PROD
# 2016-07-19     1.6   Michael Weng                 Check on hd* and rename dw_infra.runHadoopJar.ksh
# 2017-03-01     2.0   Pramit Mitra                 Extended the code for Spark Submit added JOB_ENV=sp1
# 2017-04-04     2.1   Pramit Mitra                 Deriving SQLFILE & CFG File from ETL_ID 
# 2017-06-02     2.1   Pramit Mitra                 Watch File name according to BaseScript Name(STT / TTM)
# 2017-06-06     2.2   Michael Weng                 Extract STT working tables back to ETL
###################################################################################################################

. $DW_MASTER_LIB/dw_etl_common_functions.lib

COMP_FILE=$DW_SA_TMP/$TABLE_ID.$BASENAME.${SQL_FILE_BASENAME}${UC4_JOB_NAME_APPEND}.complete

if [ ! -f $COMP_FILE ]
then
     # COMP_FILE does not exist.  1st run for this processing period.
  FIRST_RUN=Y
else
  FIRST_RUN=N
fi

## Setting Touch File name based on Spark Handler type
if [[ ${BASENAME} == target_table_merge_handler ]]
   then
   export TFILE_SUFF=ttm
   elif [[ ${BASENAME} == single_table_transform_handler ]]
   then
   export TFILE_SUFF=stt
fi

# Source the error message handling logic.  On failure, trap will send the contents of the PARENT_ERROR_FILE to the
# subject area designated email addresses.

. $DW_MASTER_LIB/message_handler

# Print standard environment variables
set +u
print_standard_env
set -u

print "
##########################################################################################################
#
# Beginning SparkSQL Execution for ETL_ID: $ETL_ID   `date`
#
##########################################################################################################
"
if [ $FIRST_RUN = Y ]
then
     # Need to run the clean up process since this is the first run for the current processing period.

        print "Running dw_infra.loader_cleanup.ksh for JOB_ENV: $JOB_ENV, JOB_TYPE_ID: $JOB_TYPE_ID  `date`"
        LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.dw_infra.loader_cleanup.${SQL_FILE_BASENAME}${UOW_APPEND}.$CURR_DATETIME.log

        set +e
        $DW_MASTER_BIN/dw_infra.loader_cleanup.ksh $JOB_ENV $JOB_TYPE_ID > $LOG_FILE 2>&1
        rcode=$?
        set -e

        if [ $rcode != 0 ]
        then
        print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
        exit 4
        fi

   > $COMP_FILE
else
  print "dw_infra.loader_cleanup.ksh process already complete"
fi


######################################################################################################
#
#                                Pre target table load processing
#
#  Jobs that need processes executed or variables set before the target table load process runs
#  are handled here.
#
#  To run a pre target table load process, set the TRGT_TBL_LD_PRE_PROC_LIS tag in the
#  $DW_CFG/$ETL_ID.cfg file equal to the pre process list containing the processes to be run.
#
#  This handler will then loop through the specified file and serially evaluate each entry in
#  the file.
#
#  This allows for great flexibility since now either pre processes can be run or list files
#  containing variables and/or functions to export into the environment called that the
#  subsequently executing SQL can leverage.
#
#  To accomodate this flexibility it's understood that some processes would need to re-run even in
#  a restart scenario, while others may not need to run. The entries in in the pre process list
#  must follow the convention of COMP_REC_FLAG COMMAND, where COMP_REC_FLAG determines whether or
#  not the process is stored in the complete flag. A value of 1 indicates yes, therefore if the
#  process completes and there is a subsequent failure, the process will not run again on restart.
#  A value of 0 indicates that this process must run each time the handler runs for that ETL_ID.
#  Always use this in the case of exporting variables, as they will not persist from run to run.
#
######################################################################################################

set +e
grep "^TRGT_TBL_LD_PRE_PROC_LIS\>" $DW_CFG/$ETL_ID.cfg | read PARAM TRGT_TBL_LD_PRE_PROC_LIS PARAM_COMMENT
rcode=$?
TRGT_TBL_LD_PRE_PROC_LIS=$(eval print $TRGT_TBL_LD_PRE_PROC_LIS)
set -e

if [ $rcode != 0 ]
then
     print "No pre-process list exists for this job"
else
  while read COMP_REC_FLAG COMMAND
  do

         set +e
         grep -s "$COMMAND" $COMP_FILE >/dev/null
         rcode=$?
         set -e

        if [ $rcode = 1 ]
        then

           print "Running Pre Process $COMMAND `date`"
           LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.preproccess${UOW_APPEND}.$CURR_DATETIME.log

           set +e
           eval $COMMAND >> $LOG_FILE 2>&1
           rcode=$?
           set -e

          if [ $rcode != 0 ]
          then
          print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
          exit 4
          fi

         if [ $COMP_REC_FLAG = 1 ]
         then
         print "$COMMAND" >> $COMP_FILE
         fi

        elif [ $rcode = 0 ]
         then
         print "$COMMAND already complete"
         continue
         else
         print "${0##*/}: ERROR, $COMP_FILE does not exist."
         exit $rcode
        fi

      done < $TRGT_TBL_LD_PRE_PROC_LIS
fi

set +e
grep -s "target_table_load" $COMP_FILE >/dev/null
RCODE=$?
set -e

### Added Condition for Spark Job Submission - pmitra - 2017/03/01
if [[ $JOB_ENV == sp* ]]
then
   HADOOP_JAR=$SQL_FILE
   HADOOP_JAR_BASENAME=${HADOOP_JAR##*/}
   export HADOOP_JAR_BASENAME=${HADOOP_JAR_BASENAME%.*}
   set +u
   if [[ -n $MAIN_CLASS ]]
   then
     CLASS_APPEND=.$MAIN_CLASS
   else
     CLASS_APPEND=""
   fi
   set -u
   LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.target_table_load.${HADOOP_JAR_BASENAME}${CLASS_APPEND}${UOW_APPEND}.$CURR_DATETIME.log

   if [ $RCODE = 1 ]
   then
     set +e
     PARAM_LIST=${PARAM_LIST:-""}
     #$DW_MASTER_BIN/dw_infra.runSparkJob.ksh $ETL_ID $JOB_ENV $HADOOP_JAR $SPARK_CONF > $LOG_FILE 2>&1
     #$DW_MASTER_BIN/dw_infra.runSparkJob.ksh $ETL_ID $JOB_ENV > $LOG_FILE 2>&1     
     $DW_MASTER_BIN/dw_infra.runSparkJob.ksh $ETL_ID $JOB_ENV $BASENAME > $LOG_FILE 2>&1
     rcode=$?
     set -e
     if [ $rcode != 0 ]
     then
     print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
     exit 4
     fi

    print "target_table_load" >> $COMP_FILE

    elif [ $RCODE = 0 ]
    then
    print "target_table_load process already complete"
    else
    exit $RCODE
 fi
####

# Add if..else here to determin if it is a hadoop job
elif [[ $JOB_ENV == hd* ]]
then
  HADOOP_JAR=$SQL_FILE
  HADOOP_JAR_BASENAME=${HADOOP_JAR##*/}
  export HADOOP_JAR_BASENAME=${HADOOP_JAR_BASENAME%.*}
  set +u
  if [[ -n $MAIN_CLASS ]]
  then
    CLASS_APPEND=.$MAIN_CLASS
  else
    CLASS_APPEND=""
  fi
  set -u
  LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.target_table_load.${HADOOP_JAR_BASENAME}${CLASS_APPEND}${UOW_APPEND}.$CURR_DATETIME.log

  if [ $RCODE = 1 ]
  then
  set +e
  PARAM_LIST=${PARAM_LIST:-""}
  $DW_MASTER_BIN/dw_infra.runHadoopJob.ksh $ETL_ID $JOB_ENV $HADOOP_JAR $PARAM_LIST > $LOG_FILE 2>&1
  rcode=$?
  set -e
  if [ $rcode != 0 ]
  then
  print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
  exit 4
  fi

  print "target_table_load" >> $COMP_FILE

  elif [ $RCODE = 0 ]
    then
    print "target_table_load process already complete"
  else
    exit $RCODE
  fi
 else
# determine which database we are using through the DBC file
export JOB_ENV_UPPER
CFG_DBC_PARAM=$(JOB_ENV_UPPER=$(print $JOB_ENV | tr [:lower:] [:upper:]); eval print ${JOB_ENV_UPPER}_DBC)
DEFAULT_DB_NAME=$(JOB_ENV_UPPER=$(print $JOB_ENV | tr [:lower:] [:upper:]); eval print teradata_\$DW_${JOB_ENV_UPPER}_DB)

set +e
DB_NAME=$(grep "^$CFG_DBC_PARAM\>" $DW_CFG/${ETL_ID}.cfg | read PARAM VALUE PARAM_COMMENT; eval print ${VALUE:-$DEFAULT_DB_NAME})
rcode=$?
set -e
if [ $rcode != 0 ]
then
     DB_NAME=$DEFAULT_DB_NAME
   fi

   set +e
   DB_TYPE=$(grep "^dbms\>" $DW_DBC/${DB_NAME}.dbc | tr [:lower:] [:upper:] | read PARAM VALUE PARAM_COMMENT; print ${VALUE:-0})
   rcode=$?
   set -e

   if [ $rcode != 0 ]
   then
   print "${0##*/}:  ERROR, Failure determining dbms value from $DW_DBC/${DB_NAME}.dbc" >&2
   exit 4
   fi

   if [ $RCODE = 1 ]
   then
   print "Processing target table load for TABLE_ID: $TABLE_ID  `date`"

   LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.target_table_load.${SQL_FILE_BASENAME}${UOW_APPEND}.$CURR_DATETIME.log

       if [[ $DB_TYPE == "ORACLE" || $DB_TYPE == "MSSQL" || $DB_TYPE == "MYSQL" ]]
       then
         # target_table_load_all_dbs.ksh is produced from graph target_table_load.ksh
         set +e
         $DW_EXE/target_table_load_all_dbs.ksh $ETL_ID $JOB_ENV $SQL_FILE > $LOG_FILE 2>&1
         rcode=$?
         set -e
         else
         set +e
         $DW_MASTER_BIN/dw_infra.runTDSQL.ksh $ETL_ID $JOB_ENV $SQL_FILE $UOW_PARAM_LIST > $LOG_FILE 2>&1
         rcode=$?
         set -e
      fi

      if [ $rcode != 0 ]
      then
        print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
        exit 4
      fi

     print "target_table_load" >> $COMP_FILE

elif [ $RCODE = 0 ]
then
  print "target_table_load process already complete"
else
  exit $RCODE
fi

fi

######################################################################################################
#
#                                Post target table load processing
#
#  Jobs that need processes executed or variables set after the target table load process runs
#  are handled here.
#
#  To run a post target table load process, set the TRGT_TBL_LD_POST_PROC_LIS tag in the
#  $DW_CFG/$ETL_ID.cfg file equal to the post process list containing the processes to be run.
#
#  This handler will then loop through the specified file and serially evaluate each entry in
#  the file.
#
#  To accomodate this flexibility it's understood that some processes would need to re-run even in
#  a restart scenario, while others may not need to run. The entries in in the post process list
#  must follow the convention of COMP_REC_FLAG COMMAND, where COMP_REC_FLAG determines whether or
#  not the process is stored in the complete flag. A value of 1 indicates yes, therefore if the
#  process completes and there is a subsequent failure, the process will not run again on restart.
#  A value of 0 indicates that this process must run each time the handler runs for that ETL_ID.
#  Always use this in the case of exporting variables, as they will not persist from run to run.
#
######################################################################################################

set +e
grep "^TRGT_TBL_LD_POST_PROC_LIS\>" $DW_CFG/$ETL_ID.cfg | read PARAM TRGT_TBL_LD_POST_PROC_LIS PARAM_COMMENT
rcode=$?
TRGT_TBL_LD_POST_PROC_LIS=$(eval print $TRGT_TBL_LD_POST_PROC_LIS)
set -e

if [ $rcode != 0 ]
then
     print "No post-process list exists for this job"
else
  while read COMP_REC_FLAG COMMAND
  do

     set +e
     grep -s "$COMMAND" $COMP_FILE >/dev/null
     rcode=$?
     set -e

     if [ $rcode = 1 ]
     then

       print "Running Post Process $COMMAND `date`"
       LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.postproccess${UOW_APPEND}.$CURR_DATETIME.log

       set +e
       eval $COMMAND >> $LOG_FILE 2>&1
       rcode=$?
       set -e

       if [ $rcode != 0 ]
          then
          print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
          exit 4
       fi

       if [ $COMP_REC_FLAG = 1 ]
         then
         print "$COMMAND" >> $COMP_FILE
       fi

                                                                                                                                                       elif [ $rcode = 0 ]
     then
         print "$COMMAND already complete"
         continue
     else
         print "${0##*/}: ERROR, $COMP_FILE does not exist."
         exit $rcode
     fi

                                                                                                                                                    done < $TRGT_TBL_LD_POST_PROC_LIS
fi

 PROCESS=touch_watchfile
 RCODE=`grepCompFile $PROCESS $COMP_FILE`

                                                                                                                                                   if [ $RCODE -eq 1 ]
 then

    LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.$PROCESS.${SQL_FILE_BASENAME}${UOW_APPEND}.$CURR_DATETIME.log
    TFILE_NAME=${SQL_FILE_BASENAME}.done

                                                                                                                                                      print "Touching Watchfile $TFILE_NAME$UOW_APPEND"

   set +e
   ##$DW_MASTER_EXE/touchWatchFile.ksh $ETL_ID $JOB_TYPE $JOB_ENV $TFILE_NAME $UOW_PARAM_LIST > $LOG_FILE 2>&1
   $DW_MASTER_EXE/touchWatchFile.ksh $ETL_ID $JOB_TYPE $JOB_ENV ${ETL_ID}.${TFILE_SUFF}.done $UOW_PARAM_LIST > $LOG_FILE 2>&1
   rcode=$?
   set -e

   if [ $rcode -ne 0 ]
   then
        print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
        exit 4
   fi

  print $PROCESS >> $COMP_FILE

 elif [ $RCODE -eq 0 ]
 then
 print "$PROCESS already complete"
 else
  exit $RCODE
fi

print "Removing the complete file  `date`"
rm -f $COMP_FILE

print "
##########################################################################################################
#
# Target table load for ETL_ID: $ETL_ID complete   `date`
#
##########################################################################################################"


######################################################################################################
#
#                                ADPO: copy result to ETL
#
#  If the parameter STT_STAGE_TARGET in $DW_CFG/$ETL_ID.cfg is set to [hd1|hd2|hd3|...], data files 
#  generated from STT job will be copied back to ETL in $DW_IN following the standard extract data 
#  location.
#
######################################################################################################
assignTagValue STT_STAGE_TARGET STT_STAGE_TARGET $ETL_CFG_FILE W ""

set +eu
if [[ -n ${STT_STAGE_TARGET:-""} ]] && [[ $STT_STAGE_TARGET == hd* ]]
then
  CLUSTER=$(JOB_ENV_UPPER=$(print $STT_STAGE_TARGET | tr [:lower:] [:upper:]); eval print \$DW_${JOB_ENV_UPPER}_DB)
  if ! [[ -f $DW_MASTER_CFG/.${CLUSTER}_env.sh ]]
  then
    print "${0##*/}:  ERROR, invalid STT_STAGE_TARGET value in $ETL_CFG_FILE" >&2
    exit 4;
  fi

  . $DW_MASTER_CFG/.${CLUSTER}_env.sh
  . $DW_MASTER_CFG/hadoop.login

  assignTagValue IN_DIR IN_DIR $ETL_CFG_FILE W $DW_IN
  assignTagValue STT_WORKING_PATH STT_WORKING_PATH $ETL_CFG_FILE
  assignTagValue STT_WORKING_TABLE STT_WORKING_TABLE $ETL_CFG_FILE

  STT_SA=${SUBJECT_AREA#*_}

  for TABLE in $(echo $STT_WORKING_TABLE | sed "s/,/ /g")
  do
    ETL_DIR=${IN_DIR}/extract/${SUBJECT_AREA}
    SOURCE_PATH=${STT_WORKING_PATH}/${STT_SA}/${TABLE}

    if [[ X"$UOW_TO" != X ]]
    then
      ETL_DIR=$ETL_DIR/$TABLE/$UOW_TO_DATE/$UOW_TO_HH/$UOW_TO_MI/$UOW_TO_SS
    fi
    print "Copy from HDFS is started. Source: ${SOURCE_PATH}, Destination: ${ETL_DIR}"

    if [[ -d $ETL_DIR ]]
    then
      print "Cleanup destination folder on ETL: $ETL_DIR"
      rm -rf $ETL_DIR/*
    fi

    COMMAND="mkdir -p $ETL_DIR; hadoop fs -copyToLocal $SOURCE_PATH/* $ETL_DIR/"
    set +e
    eval $COMMAND && (print "Extract from HDFS completed: ${SOURCE_PATH}") || (print "INFRA_ERROR - Failure extracting data from HDFS: $SOURCE_PATH")
    set -e

    if [ $? != 0 ]
    then
      print "${0##*/}: INFRA_ERROR - failed to extract data from $CLUSTER: $SOURCE_PATH"
      exit 4
    fi

    print "Renaming data files in the pattern of <TABLE_ID>.#.dat"
    COUNT=0
    for FILE in $(ls $ETL_DIR)
    do
      mv $ETL_DIR/$FILE $ETL_DIR/$TABLE.$COUNT.dat
      COUNT=$((COUNT+1))
    done

    print "Creating record count file as <TABLE_ID>.record_count.dat"
    print "30000" > $ETL_DIR/$TABLE.record_count.dat
  done

  print "
##########################################################################################################
#
# Copy from HDFS for ETL_ID: $ETL_ID, HDFS: $SOURCE_PATH complete `date`
#
##########################################################################################################"
fi


tcode=0
exit
