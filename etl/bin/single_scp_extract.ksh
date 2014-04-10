#!/bin/ksh -eu
#------------------------------------------------------------------------------------------------
# Filename:     single_scp_extract.ksh
#
# Revision History:
#
# Name             Date            Description
# ---------------  --------------  ---------------------------------------------------
# ???              ??/??/????      Initial Creation
# Ryan Wong        10/04/2013      Redhat changes
#
#------------------------------------------------------------------------------------------------

ETL_ID=$1
FILE_ID=$2
SCP_CONN=$3
SOURCE_FILE=$4
TARGET_FILE=$5	

set +e
grep "^$SCP_CONN\>" $DW_LOGINS/scp_logins.dat | read SCP_NAME SCP_HOST SCP_USERNAME SCP_PASSWORD REMOTE_DIR NOT_USED
rcode=$?
set -e

if [ $rcode != 0 ]
then
	print "${0##*/}:  ERROR, failure determining value for SCP_NAME parameter from $DW_LOGINS/scp_logins.dat" >&2
	exit 4
fi

set +e
grep "^CNDTL_COMPRESSION\>" $DW_CFG/$ETL_ID.cfg | read PARAM VALUE COMMENT;  IS_COMPRESS=${VALUE:-0}
rcode=$?
set -e

if [ $rcode != 0 ]
then
  print "${0##*/}: WARNING, failure determining value for CNDTL_COMPRESSION parameter from $DW_CFG/$ETL_ID.cfg" >&2
fi

if [ $IS_COMPRESS = 1 ]
then
  set +e
  grep "^CNDTL_COMPRESSION_SFXN\>" $DW_CFG/$ETL_ID.cfg | read PARAM VALUE COMMENT; COMPRESS_SFX=${VALUE:-".gz"}
  rcode=$?
  set -e

  if [ $rcode != 0 ]
  then
   print "${0##*/}: WARNING, failure determining value for CNDTL_COMPRESSION_SFX parameter from $DW_CFG/$ETL_ID.cfg" >&2
  fi
else
   COMPRESS_SFX=""
fi

SOURCE_FILE_TMP=`print $(eval print $SOURCE_FILE)`
SOURCE_FILE_TMP=$SOURCE_FILE_TMP$COMPRESS_SFX
TARGET_FILE_TMP=`print $(eval print $TARGET_FILE)`
#TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}.$BATCH_SEQ_NUM$COMPRESS_SFX

  if [[ -n $UOW_TO ]]
  then
  	 TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}$COMPRESS_SFX
  else
  	 TARGET_FILE_TMP=${TARGET_FILE_TMP%%$COMPRESS_SFX}.$BATCH_SEQ_NUM$COMPRESS_SFX
  fi

scp -v -B $SCP_USERNAME@$SCP_HOST:$REMOTE_DIR/$SOURCE_FILE_TMP $IN_DIR/$TARGET_FILE_TMP >&2
 
((FILE_REC_COUNT=`ls -l $IN_DIR/$TARGET_FILE_TMP | tr -s ' '| cut -d' ' -f5`/100))

print $FILE_REC_COUNT > $DW_SA_TMP/$TABLE_ID.$JOB_TYPE_ID.$FILE_ID.record_count.dat

if [[ $LAST_EXTRACT_TYPE = "V" ]]
then
	print $TO_EXTRACT_VALUE > $DW_SA_DAT/$TABLE_ID.$FILE_ID.last_extract_value.dat
fi