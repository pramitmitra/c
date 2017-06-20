#############
# this section contains exports ONLY for Olympus
#############


#if [[ $ETL_ENV != prod ]]
#      then
#      export SPARK_FS=aressub-lvs-nn-ha
#      export COMPUTE_ENV=olympusqa
#      export HADOOP_CLI_HOST="olympus-sub-lvs-cli-1.vip.ebay.com"
#    else
      export SPARK_FS=ares-lvs-nn-ha
      export COMPUTE_ENV=olympus
      export HADOOP_CLI_HOST="hdc34-lvs01-400-2908-003.stratus.lvs.ebay.com"
#  fi

export JAVA_HOME=/usr/java/latest
export ORIGPATH=$PATH
export MANPATH=$MANPATH:/usr/share/man:/usr/local/man:/usr/local/pssh:/usr/local/pssh/man
export EDITOR=vi
export PS1="[\$(date +%H:%M)]:[\u@\h:\W]\$ "
export HADOOP_HOME=/apache/hadoop_client/${COMPUTE_ENV}/hadoop
export HIVE_HOME=/apache/hadoop_client/${COMPUTE_ENV}/hive
export SPARK_HOME=/apache/hadoop_client/${COMPUTE_ENV}/spark
#export HADOOP_CONF_DIR=$HADOOP_HOME/conf
#export HIVE_CONF_DIR=$HIVE_HOME/conf
#export HADOOP_PID_DIR=$HADOOP_HOME/pids
#export HADOOP_LOG_DIR=$HADOOP_HOME/logs
#export TEZ_HOME=/apache/hadoop_client/${COMPUTE_ENV}/tez
#export TEZ_CONF_DIR=$TEZ_HOME/conf
#export TEZ_JARS=$TEZ_HOME/*:$TEZ_HOME/lib/*
#export JAVA_HOME=/usr/java/latest
#export HISTSIZE=99999
#export HISTFILESIZE=99999
#export HISTTIMEFORMAT="%Y-%m-%d %T -> "
#export HISTCONTROL=erasedups
#export HISTIGNORE="&:ls:l:[bf]g:exit"
# grab our hadoop exports
if [ -f "$HADOOP_CONF_DIR/hadoop-env.sh" ]; then
   . "$HADOOP_CONF_DIR/hadoop-env.sh"
fi
HIVE_ENV_FILE="$HIVE_CONF_DIR/hive-env.sh"
if [ -f "$HIVE_ENV_FILE" ]; then
    source "$HIVE_ENV_FILE"
fi
# do his last as hadoop-env.sh can change $JAVA_HOME
export PATH=$HADOOP_HOME/bin:$HBASE_HOME/bin:$HIVE_HOME/bin:$JAVA_HOME/bin:$PATH:/usr/local/sbin:/usr/local/bin:/usr/local/pssh/bin:$HOME/bin

# Move all NN URLs to etlenv.<env>.teradata_target_variables.lis
export HADOOP_NN_URL=$SP1_NN_URL
#export HADOOP_CLI_HOST="hdc34-lvs01-400-2908-003.stratus.lvs.ebay.com"