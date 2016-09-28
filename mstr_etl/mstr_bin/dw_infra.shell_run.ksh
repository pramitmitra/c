#!/bin/ksh -eu
#------------------------------------------------------------------------------------------------
# Filename:     dw_infra.shell_run.ksh
#
# Revision History:
#
# Name             Date            Description
# ---------------  --------------  ---------------------------------------------------
# ???              ??/??/????      Initial Creation
# Ryan Wong        10/04/2013      Redhat changes
# John Hackley     06/02/2014      Included $servername as part of log file name, since logs
#                                  are on shared storage and this job runs concurrently on many
#                                  hosts
# John Hackley     07/03/2014      Added options to include host name as part of log file name (for 
#                                  uniqueness), include host name as part of touch file name (for
#                                  uniqueness) and skip creation of touch file altogether
# Kevin Oaks       09/22/2016      Added option to include host name as part of comp file (for uniqueness
#                                  when using shared platform
#
#------------------------------------------------------------------------------------------------

. $DW_MASTER_LIB/dw_etl_common_functions.lib

if [[ $SH_UNIQUE_COMP_FILE -eq 1 ]]
then
   COMP_FILE=$DW_SA_TMP/$TABLE_ID.$JOB_ENV.$servername.${SHELL_EXE_NAME%.ksh}${UC4_JOB_NAME_APPEND}.complete
else
   COMP_FILE=$DW_SA_TMP/$TABLE_ID.$JOB_ENV.${SHELL_EXE_NAME%.ksh}${UC4_JOB_NAME_APPEND}.complete
fi

if [ ! -f $COMP_FILE ]
then
   # COMP_FILE does not exist.  1st run for this processing period.
   FIRST_RUN=Y
else
   FIRST_RUN=N
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
# Beginning target table load for ETL_ID: $ETL_ID   `date`
#
##########################################################################################################
"

if [ $FIRST_RUN = Y ]
then
   # Need to run the clean up process since this is the first run for the current processing period.

   #print "Running dw_infra.loader_cleanup.ksh for JOB_ENV: $JOB_ENV, JOB_TYPE_ID: $JOB_TYPE_ID  `date`"
   #if [[ $SH_UNIQUE_LOG_FILE -eq 1 ]]
   #then
   #   LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.$servername.dw_infra.loader_cleanup.${SHELL_EXE_NAME%.ksh}${UOW_APPEND}.$CURR_DATETIME.log
   #else
   #   LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.dw_infra.loader_cleanup.${SHELL_EXE_NAME%.ksh}${UOW_APPEND}.$CURR_DATETIME.log
   #fi
   #
   #set +e
   #$DW_MASTER_BIN/dw_infra.loader_cleanup.ksh $JOB_ENV $JOB_TYPE_ID > $LOG_FILE 2>&1
   #rcode=$?
   #set -e

   #if [ $rcode != 0 ]
   #then
   #   print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
   #   exit 4
   #fi

   > $COMP_FILE
#else
#   print "dw_infra.loader_cleanup.ksh process already complete"
fi

PROCESS=shell_exe
RCODE=`grepCompFile $PROCESS $COMP_FILE`

if [ $RCODE -eq 1 ]
then

   print "
   ####################################################################################################################
   #
   # Beginning shell handler ETL_ID: $ETL_ID, JOB_ID: $JOB_ENV, SHELL_EXE: $SHELL_EXE   `date`
   #
   ####################################################################################################################
   "
   print "Processing shell script SHELL_EXE: $SHELL_EXE  `date`"
   if [[ $SH_UNIQUE_LOG_FILE -eq 1 ]]
   then
      LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.$servername.${SHELL_EXE_NAME%.ksh}.$CURR_DATETIME.log
   else
      LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.${SHELL_EXE_NAME%.ksh}.$CURR_DATETIME.log
   fi
   
   set +e
   $SHELL_EXE $PARAMS > $LOG_FILE 2>&1
   rcode=$?
   set -e
   
   if [ $rcode != 0 ]
   then
   	print "${0##*/}:  ERROR running $SHELL_EXE_NAME, see log file $LOG_FILE" >&2
   	exit $rcode
   fi
      
   print $PROCESS >> $COMP_FILE

elif [ $RCODE -eq 0 ]
then
   print "$PROCESS already complete"
else
   exit $RCODE
fi 

PROCESS=touch_watchfile
RCODE=`grepCompFile $PROCESS $COMP_FILE`

if [ $RCODE -eq 1 ]
then

   if [[ $SH_UNIQUE_LOG_FILE -eq 1 ]]
   then
      LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.$servername.$PROCESS.${SHELL_EXE_NAME%.ksh}${UOW_APPEND}.$CURR_DATETIME.log
   else
      LOG_FILE=$DW_SA_LOG/$TABLE_ID.$JOB_TYPE_ID.$PROCESS.${SHELL_EXE_NAME%.ksh}${UOW_APPEND}.$CURR_DATETIME.log
   fi

   if [[ $SH_UNIQUE_TOUCH_FILE -eq 1 ]]
   then
     TFILE_NAME=$ETL_ID.$JOB_TYPE.$servername.${SHELL_EXE_NAME%.ksh}.done
   else
     TFILE_NAME=$ETL_ID.$JOB_TYPE.${SHELL_EXE_NAME%.ksh}.done
   fi

   if [[ $SH_SKIP_TOUCH_FILE -ne 1 ]]
   then

      print "Touching Watchfile $TFILE_NAME$UOW_APPEND"

      set +e
      $DW_MASTER_EXE/touchWatchFile.ksh $ETL_ID $JOB_TYPE $JOB_ENV $TFILE_NAME $UOW_PARAM_LIST > $LOG_FILE 2>&1
      rcode=$?
      set -e

      if [ $rcode -ne 0 ]
      then
         print "${0##*/}:  ERROR, see log file $LOG_FILE" >&2
         exit 4
      fi

      print $PROCESS >> $COMP_FILE

   else

      print "Skipped touching Watchfile $TFILE_NAME$UOW_APPEND"

   fi

elif [ $RCODE -eq 0 ]
then
   print "$PROCESS already complete"
else
   exit $RCODE
fi 

print "Removing the complete file  `date`"
rm -f $COMP_FILE


print "
####################################################################################################################
#
# Shell handler for ETL_ID: $ETL_ID, JOB_ID: $JOB_ENV, SHELL_EXE: $SHELL_EXE complete   `date`
#
####################################################################################################################
"

tcode=0
exit
