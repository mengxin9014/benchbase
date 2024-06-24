#!/bin/bash

result_dir="write_throughput_summary"
if [ -n "$1" ]
then
	result_dir=$1
else
	mkdir $result_dir
fi

table_number="16"
if [ -n "$2" ]
then
	table_number=$2
fi
table_size="1000000"
if [ -n "$3" ]
then
	table_size=$3
fi

rm -rf $result_dir/write_throughput_test.txt

echo -e "data_size\tApQPS\tRT_P99(μs)" > $result_dir/write_throughput_test.txt

for size in ${table_size}
do
  qps=$(grep Throughput write_throughput_result/write_throughput_table_${table_number}_size_${size}/chbenchmark_*.summary.json | awk -F':' '{print $NF}')
  p99_rt=$(grep 99th write_throughput_result/write_throughput_table_${table_number}_size_${size}/chbenchmark_*.summary.json | awk -F':' '{print $NF}' | sed 's/,//g')
  echo -e "table_number:$table_number, table_size:$table_size\t$qps\t$p99_rt" >> $result_dir/write_throughput_test.txt
done


