#!/bin/bash

resultDir="."
if [ -n "$1" ]
then
	resultDir=$1
else
	echo "resultDir is not specified"
	echo "Usages: ./extract_result resultDir [apThreads tpThreads wd]"
	exit 1
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

rm -rf $resultDir/throughput_ap.txt
rm -rf $resultDir/throughput_tp.txt
rm -rf $resultDir/avg_latency_ap.txt
rm -rf $resultDir/avg_latency_tp.txt

apThreads="1 5 10 20 30"
for ap in $apThreads
do
  if [ ${ap} -ne 1 ]
  then
    querys="Q6 Q12 Q13 Q14"
  else
    querys="Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21 Q22"
  fi

  for query in $querys
  do
    echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_ap.txt
    grep Throughput result/outputfile_tidb_query_${query}_ap_${ap}_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}' >> $resultDir/throughput_ap.txt
    echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_tp.txt
    grep Throughput result/outputfile_tidb_query_${query}_ap_${ap}_tp/chbenchmark_*.summary.json | awk -F':' '{print $NF}' >> $resultDir/throughput_ap.txt

    grep 'Average Latency' result/outputfile_tidb_query_Q1_ap_1_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}'
    grep '99th' result/outputfile_tidb_query_Q1_ap_1_ap/chbenchmark_*.summary.json | awk -F':' '{print $NF}'
  done
done


for ap in $apThreads
do
	for tp in $tpThreads
	do
		if test $(find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_ap\.summary" | wc -c) -ne 0
		then
			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_ap.txt
			find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_ap\.summary" -exec grep Throughput {} + | awk -F':' '{print $NF}' >> $resultDir/throughput_ap.txt

			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/avg_latency_ap.txt
			find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_ap\.summary" -exec grep "Average Latency" {} + | awk -F':' '{print $NF}' >> $resultDir/avg_latency_ap.txt
		else
			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_ap.txt
			echo "NA" >> $resultDir/throughput_ap.txt

			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/avg_latency_ap.txt
			echo "NA" >> $resultDir/avg_latency_ap.txt
		fi

		if test $(find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_tp\.summary.json" | wc -c) -ne 0
		then
			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_tp.txt
			find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_tp\.summary.json" -exec grep Throughput {} + | awk -F':' '{print $NF}' >> $resultDir/throughput_tp.txt

			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/avg_latency_tp.txt
			find $resultDir/ -name "*ap_${ap}_tp_${tp}_wd_${wd}_tp\.summary.json" -exec grep "Average Latency" {} + | awk -F':' '{print $NF}' >> $resultDir/avg_latency_tp.txt
		else
			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/throughput_tp.txt
			echo "NA" >> $resultDir/throughput_tp.txt

			echo -e "ap-${ap}-tp-${tp}-wd-${wd}: \c" >> $resultDir/avg_latency_tp.txt
			echo "NA" >> $resultDir/avg_latency_tp.txt
		fi

	done
done