SERVERLIST=${1:-ab_serverlist}

while read SN ABH
do
LFILE=/dw/etl/mstr_bin/infra/log/$SN.add_key.$ABH.log

if [ ! -f $LFILE ]
then

      ssh -n $SN 'export AB_HOME=/usr/local/abinitio-V2-15;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 
      ssh -n $SN 'export AB_HOME=/usr/local/abinitio;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 

else
   echo $SN already processed for $ABH
fi
done < $SERVERLIST

exit

/*
if [ ! -f $LFILE ]
then
   if [ $ABH == 'abinitio-V2-16-1' ]
   then
      ssh -n $SN 'export AB_HOME=/usr/local/abinitio-V2-16-1;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 
   elif [ $ABH == 'abinitio-V2-16-2' ]
   then
      ssh -n $SN 'export AB_HOME=/usr/local/abinitio-V2-16-2;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 
   elif [ $ABH == 'abinitio-V3-0-4' ]
   then
      ssh -n $SN 'export AB_HOME=/usr/local/abinitio-V3-0-4/n32;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 
   else
      ssh -n $SN 'export AB_HOME=/usr/local/abinitio;PATH=$AB_HOME/bin:$PATH:;ab-key -y show;ab-key -y add /dw/etl/mstr_bin/key/;ab-key show' > $LFILE 
  fi
else
   echo $SN already processed for $ABH
fi
done < $SERVERLIST
*/