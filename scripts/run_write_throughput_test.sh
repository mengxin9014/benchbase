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
    $mysql_client "alter table sbtest.$table set tiflash replica $tiflash_replica"
    $mysql_client "analyze table sbtest.$table"
  done
	python2 ./scripts/wait_tiflash_table_available.py "$database" $tables "$mysql_client" ; return $?
}

resultDir=write_throughput_result
if [ -d "resultDir" ]
then
	echo $resultDir already exists
else
  mkdir $resultDir
fi

mysql_info=$(grep url config/tidb/chbenchmark_config_base.xml | sed  's/.*jdbc:mysql:\/\/\(.*\)?.*/\1/g')
info_arr=(${mysql_info//// })
ip_port=${info_arr[0]}
database=sbtest
ip_port_arr=(${ip_port//:/ })
ip=${ip_port_arr[0]}
port=${ip_port_arr[1]}
url="jdbc:mysql:\/\/$ip_port\/$database?rewriteBatchedStatements=true"

echo -e "mysql-host=$ip" > ./sysbench.config
echo -e "mysql-port=$port" >> ./sysbench.config
echo -e "mysql-user=root" >> ./sysbench.config
echo -e "mysql-password=" >> ./sysbench.config
echo -e "mysql-db=sbtest" >> ./sysbench.config
echo -e "time=60" >> ./sysbench.config
echo -e "threads=16" >> ./sysbench.config
echo -e "report-interval=10" >> ./sysbench.config
echo -e "db-driver=mysql" >> ./sysbench.config

table_size="1000000"
if [ -n "$1" ]
then
	table_size=$1
fi

table_number=8
if [ -n "$2" ]
then
	table_number=$2
fi

tables="sbtest1"
for ((i=2; i<=$table_number; i++))
do
    tables="$tables sbtest$i"
done

cat config/tidb/querys/chbenchmark_config_sbtest_base.xml  | sed "s/<url>.*<\/url>/<url>${url}<\/url>/g" | sed "s/<tableNumber>.*<\/tableNumber>/<tableNumber>${table_number}<\/tableNumber>/g" > config/tidb/querys/chbenchmark_config_sbtest.xml
for size in ${table_size}
do
  mysql --host $ip --port $port -u root -e "drop database if exists sbtest"
  mysql --host $ip --port $port -u root -e "set global tidb_disable_txn_auto_retry=off"
  mysql --host $ip --port $port -u root -e "create database if not exists sbtest"
  sysbench --config-file=sysbench.config oltp_point_select --tables=$table_number --table-size=$size prepare
  wait_table sbtest "$tables" "mysql --host $ip --port $port -u root -e"

  sysbench --config-file=./sysbench.config oltp_write_only --tables=$table_number --table-size=$size run &
  java -jar benchbase.jar -b chbenchmark -c config/tidb/querys/chbenchmark_config_sbtest.xml  --create=false --load=false --execute=true -d $resultDir/write_throughput_table_${table_number}_size_${size} &
  wait

done
