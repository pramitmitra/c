#!/bin/ksh -eu
#------------------------------------------------------------------------------------------------
# Filename:     dw_infra.runHadoopJar.ksh
#
# Revision History:
#
# Name             Date            Description
# ---------------  --------------  ---------------------------------------------------
# ???              ??/??/????      Initial Creation
# Ryan Wong        10/04/2013      Redhat changes
# Ryan Wong        11/21/2013      Update hd login method, consolidate to use dw_adm
#
#------------------------------------------------------------------------------------------------

ETL_ID=$1
JOB_ENV=$2
HADOOP_JAR=$3
shift 3

if [ $# -ge 1 ]
then
PARAM_LIST=$*
fi

PARAM_LIST=${PARAM_LIST:-""}

. $DW_MASTER_LIB/dw_etl_common_functions.lib

# Check if HD_USERNAME has been configured
if [[ -z $HD_USERNAME ]]
  then
    print "INFRA_ERROR: can't not deterine batch account the connect hadoop cluster"
    exit 4
fi

export UC4_JOB_NAME=${UC4_JOB_NAME:-"NA"}
export UC4_PRNT_CNTR_NAME=${UC4_PRNT_CNTR_NAME:-"NA"}
export UC4_TOP_LVL_CNTR_NAME=${UC4_TOP_LVL_CNTR_NAME:-"NA"};
export UC4_JOB_RUN_ID=${UC4_JOB_RUN_ID:-"NA"}

JAVA=$JAVA_HOME/bin/java
DW_JAR=$DW_HOME/jar
DW_HQL=$DW_HOME/hql
JAVA_CMD_OPT=`bash /dw/etl/mstr_lib/hadoop_ext/hadoop.setup`

RUN_SCRIPT=$HADOOP_JAR
RUN_CLASS=${MAIN_CLASS:-"NA"}
DATAPLATFORM_ETL_INFO="ETL_ID=${ETL_ID};UC4_JOB_NAME=${UC4_JOB_NAME};UC4_PRNT_CNTR_NAME=${UC4_PRNT_CNTR_NAME};UC4_TOP_LVL_CNTR_NAME=${UC4_TOP_LVL_CNTR_NAME};UC4_JOB_RUN_ID=${UC4_JOB_RUN_ID};UOW_FROM=${UOW_FROM};UOW_TO=${UOW_TO};RUN_SCRIPT=${RUN_SCRIPT};RUN_CLASS=${RUN_CLASS};"

# if there is too much parameters need to be passed to hadoop jar, using a parameters.lis
dwi_assignTagValue -p USE_JAR_PARAM_LIS -t USE_JAR_PARAM_LIS -f $ETL_CFG_FILE -s N -d 0

if [[ $USE_JAR_PARAM_LIS -eq 1 ]]
  then
    PARAM_LIS_TMP=`eval print $(<$DW_CFG/$ETL_ID.param.lis)`
    PARAM_LIST="$PARAM_LIST $PARAM_LIS_TMP"
  fi

CURR_USER=`whoami`

JOB_EXT=${HADOOP_JAR##*.}
  
if [[ $JOB_EXT == "hql" ]]
then
  print "Submitting HIVE job to Cluster"
  if [[ -n $PARAM_LIST ]]
  then
  for param in $PARAM_LIST
    do
      if [ ${param%=*} = $param ]
      then
         print "${0##*/}: ERROR, parameter definition $param is not of form <PARAM_NAME=PARAM_VALUE>"
         exit 4
      else
         print "Exporting $param"
         export $param
      fi
  done
  fi
  
  print "cat <<EOF" > $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  cat $DW_HQL/$HADOOP_JAR >> $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  print "\nEOF" >> $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  chmod +x $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  set +u
  . $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp >> $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp.2
  set -u
  mv $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp.2 $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  
  
  if [[ $CURR_USER == $HD_USERNAME ]]
    then
      /apache/hive/bin/hive --hiveconf mapred.job.queue.name=$HD_QUEUE \
                            --hiveconf dataplatform.etl.info="$DATAPLATFORM_ETL_INFO" \
                            -f $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  else
    CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`
    CLASSPATH=${CLASSPATH}:$DW_MASTER_LIB/hadoop_ext/DataplatformETLHandlerUtil.jar
    for jar_file in /apache/hive/lib/*.jar
      do
        CLASSPATH=$CLASSPATH:$jar_file
      done
    CLASSPATH=$CLASSPATH:/apache/hive/conf
    HIVE_CLI_JAR=`ls /apache/hive/lib/hive-cli-*.jar`
    exec "$JAVA" -Dproc_jar $JAVA_CMD_OPT -classpath "$CLASSPATH" \
                 DataplatformRunJar sg_adm ~dw_adm/.keytabs/apd.sg_adm.keytab $HD_USERNAME \
                 $HIVE_CLI_JAR org.apache.hadoop.hive.cli.CliDriver \
                 --hiveconf mapred.job.queue.name=$HD_QUEUE \
                 --hiveconf dataplatform.etl.info="$DATAPLATFORM_ETL_INFO" \
                 -f $DW_SA_TMP/$TABLE_ID.ht.$HADOOP_JAR.tmp
  fi

else
  dwi_assignTagValue -p MAPRED_OUTPUT_COMPRESS -t MAPRED_OUTPUT_COMPRESS -f $ETL_CFG_FILE -s N -d 0
  if [[ $MAPRED_OUTPUT_COMPRESS -eq 0 ]]
  then
     MAPRED_OUTPUT_COMPRESS_IND=false
  else
     MAPRED_OUTPUT_COMPRESS_IND=true
  fi 

  if [[ $CURR_USER == $HD_USERNAME ]]
  then

    $HADOOP_HOME/bin/hadoop jar $DW_JAR/$HADOOP_JAR $MAIN_CLASS \
                                -Dmapred.job.queue.name=$HD_QUEUE -Dmapred.output.compress=$MAPRED_OUTPUT_COMPRESS_IND \
                                -Ddataplatform.etl.info="$DATAPLATFORM_ETL_INFO" \
                                $PARAM_LIST


  else
  
    CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`
    
    CLASSPATH=${CLASSPATH}:$DW_MASTER_LIB/hadoop_ext/DataplatformETLHandlerUtil.jar

    print "exec "$JAVA" -Dproc_jar $JAVA_CMD_OPT -classpath "$CLASSPATH" \
                 DataplatformRunJar sg_adm ~dw_adm/.keytabs/apd.sg_adm.keytab $HD_USERNAME \
                 $DW_JAR/$HADOOP_JAR $MAIN_CLASS \
                 -Dmapred.job.queue.name=$HD_QUEUE -Dmapred.output.compress=$MAPRED_OUTPUT_COMPRESS_IND \
                 -Ddataplatform.etl.info="$DATAPLATFORM_ETL_INFO" \
                 $PARAM_LIST"

    exec "$JAVA" -Dproc_jar $JAVA_CMD_OPT -classpath "$CLASSPATH" \
                 DataplatformRunJar dw_adm ~sg_adm/.keytabs/apd.sg_adm.keytab $HD_USERNAME \
                 $DW_JAR/$HADOOP_JAR $MAIN_CLASS \
                 -Dmapred.job.queue.name=$HD_QUEUE -Dmapred.output.compress=$MAPRED_OUTPUT_COMPRESS_IND \
                 -Ddataplatform.etl.info="$DATAPLATFORM_ETL_INFO" \
                 $PARAM_LIST
  fi
fi
