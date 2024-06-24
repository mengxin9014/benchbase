#!/bin/bash

dbType="tidb"
if [ -n "$1" ]
then
	dbType=$1
fi
#apThreads="2 4 8 16 32 64 0"
apThreads="1 0"
if [ -n "$2" ]
then
	apThreads=$2
fi
#tpThreads="64 128 256 512 1024"
tpThreads="2 4"
if [ -n "$3" ]
then
	tpThreads=$3
fi
wd=1
if [ -n "$4" ]
then
	wd=$4
fi

tmpResultDir="results"
if [ -d "$tmpResultDir" ]
then
	echo $tmpResultDir already exists
	exit 1
fi

for ap in $apThreads
do 
	for tp in $tpThreads
	do
		if [ $dbType = "tidb" ]
		then
#		  cat  config/tidb/chbenchmark_config_base.xml | sed "s/<scalefactor>.*<\/scalefactor>/<scalefactor>${wd}<\/scalefactor>/g" > config/tidb/chbenchmark_config.xml
#			if [ ${ap} -ne 0 ]
#			then
#				java -jar benchbase.jar -b tpcc -c config/tidb/chbenchmark_config.xml --create=true --load=true --execute=false
#			else
#				java -jar benchbase.jar -b tpcc,chbenchmark -c config/tidb/chbenchmark_config.xml --create=true --load=true --execute=false
#			fi

			cat config/tidb/chbenchmark_config.xml | sed "s/<active_terminals bench=\"tpcc\">.*<\/active_terminals>/<active_terminals bench=\"tpcc\">${tp}<\/active_terminals>/g" | sed "s/<terminals>.*<\/terminals>/<terminals>${tp}<\/terminals>/g" > config/tidb/chbenchmark_config_tp_execute.xml
			java -jar benchbase.jar -b tpcc -c config/tidb/chbenchmark_config_tp_execute.xml --create=false --load=false --execute=true -d outputfile_tidb_ap_${ap}_tp_${tp}_wd_${wd}_tp &
			if [ ${ap} -ne 0 ]
			then
				cat config/tidb/chbenchmark_config.xml | sed "s/<active_terminals bench=\"chbenchmark\">.*<\/active_terminals>/<active_terminals bench=\"chbenchmark\">${ap}<\/active_terminals>/g" | sed "s/<terminals>.*<\/terminals>/<terminals>${ap}<\/terminals>/g" > config/tidb/chbenchmark_config_ap_execute.xml
				java -jar benchbase.jar -b chbenchmark -c config/tidb/chbenchmark_config_ap_execute.xml --create=false --load=false --execute=true -d outputfile_tidb_ap_${ap}_tp_${tp}_wd_${wd}_ap &
			fi
			wait

			echo "TiDB count of order_line after ap_${ap}_tp_${tp}_wd_${wd}" >> $resultDir/row_count
#			mysql -uroot -P 4000 -h 172.16.4.75 -e "select count(*) from chbenchmark.order_line" >> $resultDir/row_count
		else
			echo "dbType should be tidb"
		fi
	done
done

if [ -d "$tmpResultDir" ]
then 
	mv $tmpResultDir $resultDir
else
	echo "Failed to find result files, dir $tmpResultDir not exists"
	exit 1
fi