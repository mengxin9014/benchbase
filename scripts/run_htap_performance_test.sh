#!/bin/bash

function wait_table()
{
  local database="$1"
  local tables="$2"
  local mysql_client="$3"
  local tiflash_replica=1

  if [ -n "$4" ]
  then
  	tiflash_replica=$4
  fi

  for table in $tables
  do
    $mysql_client "alter table benchbase.$table set tiflash replica $tiflash_replica"
    $mysql_client "analyze table benchbase.$table"
  done
	python2 ./scripts/wait_tiflash_table_available.py "$database" $tables "$mysql_client" ; return $?
}

wd=1
if [ -n "$1" ]
then
	wd=$1
fi

resultDir=result
if [ -d "resultDir" ]
then
	echo $resultDir already exists
	exit 1
fi
mkdir $resultDir

ap_threads="1 5 10 20 30"
mysql_info=$(grep url config/tidb/chbenchmark_config_base.xml | sed  's/.*jdbc:mysql:\/\/\(.*\)?.*/\1/g')
info_arr=(${mysql_info//// })
ip_port=${info_arr[0]}
database=${info_arr[1]}
ip_port_arr=(${ip_port//:/ })
ip=${ip_port_arr[0]}
port=${ip_port_arr[1]}

mysql --host $ip --port $port -u root -e "create database if not exists benchbase"


tables="CUSTOMER ITEM HISTORY DISTRICT NEW_ORDER OORDER ORDER_LINE STOCK WAREHOUSE nation region supplier"
for ap in $ap_threads
do
  if [ ${ap} -ne 1 ]
  then
    querys="Q6 Q12 Q13 Q14"
  else
    querys="Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21 Q22"
  fi

  for query in $querys
  do
    cat  config/tidb/chbenchmark_config_base.xml | sed "s/<scalefactor>.*<\/scalefactor>/<scalefactor>${wd}<\/scalefactor>/g" > config/tidb/chbenchmark_config.xml
    java -jar benchbase.jar -b tpcc,chbenchmark -c config/tidb/chbenchmark_config.xml --create=true --load=true --execute=false

    wait_table benchbase "$tables" "mysql --host $ip --port $port -u root -e"

    cat config/tidb/querys/chbenchmark_config_tp_base.xml | sed "s/<scalefactor>.*<\/scalefactor>/<scalefactor>${wd}<\/scalefactor>/g"  > config/tidb/querys/chbenchmark_config_tp.xml
    java -jar benchbase.jar -b tpcc -c config/tidb/querys/chbenchmark_config_tp.xml --create=false --load=false --execute=true -d $resultDir/outputfile_tidb_query_${query}_ap_${ap}_tp &

  	cat config/tidb/querys/chbenchmark_config_ap_base.xml | sed "s/<scalefactor>.*<\/scalefactor>/<scalefactor>${wd}<\/scalefactor>/g" | sed "s/<name>.*<\/name>/<name>${query}<\/name>/g" | sed "s/<active_terminals bench=\"chbenchmark\">.*<\/active_terminals>/<active_terminals bench=\"chbenchmark\">${ap}<\/active_terminals>/g" | sed "s/<terminals>.*<\/terminals>/<terminals>${ap}<\/terminals>/g" > config/tidb/querys/chbenchmark_config_ap_${query}.xml
    java -jar benchbase.jar -b chbenchmark -c config/tidb/querys/chbenchmark_config_ap_${query}.xml --create=false --load=false --execute=true -d $resultDir/outputfile_tidb_query_${query}_ap_${ap}_ap &
    wait
  done
done
