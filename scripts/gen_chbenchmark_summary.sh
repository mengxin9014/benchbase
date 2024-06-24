#!/bin/bash

resultDir="summary"
if [ -n "$1" ]
then
	resultDir=$1
else
	mkdir summary
fi
apThreads="1"
if [ -n "$2" ]
then
	apThreads=$2
fi
tpThreads="1"
if [ -n "$3" ]
then
	tpThreads=$3
fi
wd=1
if [ -n "$4" ]
then
	wd=$4
fi

rm -rf $resultDir/ch_benchmark_test.txt
rm -rf $resultDir/ch_benchmark_small_query_test.txt

echo -e "workload\tApAvgRT(μs)\tTpP99RT(μs)\tApQPS\tTPS" > $resultDir/ch_benchmark_test.txt
echo -e "\tQ6(QPS)\tQ12(QPS)\tQ13(QPS)\tQ14(QPS)" > $resultDir/ch_benchmark_small_query_test.txt

apThreads="1 5 10 20 30"
for ap in $apThreads
do
  if [ ${ap} -ne 1 ]
  then
    querys="Q6 Q12 Q13 Q14"
  else
    querys="Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21 Q22"
  fi

  qps_line="${ap}_threads: "
  for query in $querys
  do
    if [ ${ap} -ne 1 ]
    then
      qps=$(grep Throughput result/outputfile_tidb_query_${query}_ap_${ap}_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}')
      qps_line="$qps_line$qps\t"
    else
      qps=$(grep Throughput result/outputfile_tidb_query_${query}_ap_${ap}_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}')
      tps=$(grep Throughput result/outputfile_tidb_query_${query}_ap_${ap}_tp/tpcc_*.summary.json | awk -F':' '{print $NF}')
      ap_avg_rt=$(grep "Average Latency" result/outputfile_tidb_query_${query}_ap_${ap}_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}')
      tp_p99_rt=$(grep 99th result/outputfile_tidb_query_${query}_ap_${ap}_tp/tpcc_*.summary.json | awk -F':' '{print $NF}' | sed 's/,//g')

      echo -e "$query\t$ap_avg_rt\t$tp_p99_rt\t$qps\t$tps" >> $resultDir/ch_benchmark_test.txt
    fi
   done
   if [ ${ap} -ne 1 ]
   then
     echo -e "qps_line" >> $resultDir/ch_benchmark_small_query_test.txt
   fi
done