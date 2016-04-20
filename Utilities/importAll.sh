hantec[0]=56580125
hantec[1]=56580595
hantec[2]=56580610
hantec[3]=56580624
hantec[4]=56580627
hantec[5]=56580628

svsfx[0]=101838
svsfx[1]=102020
svsfx[2]=102021
svsfx[3]=102022
svsfx[4]=102499

activ[0]=2007138

wd=`dirname "${BASH_SOURCE-$0}"`
wd=`cd "$wd"; pwd`
fd=/Users/timhsu/Dropbox/外匯交易
cd $wd

hantec_accts=""
for ((i=0; i<=5; i=i+1))
do
   if [ "${hantec[i]}" ]; then
      ./parseTrades.sh $fd/${hantec[i]}.csv
      if [ "${hantec_accts}" ]; then
         hantec_accts=$hantec_accts", "${hantec[i]}
      else
         hantec_accts=${hantec[i]}
      fi
   fi
done

svsfx_accts=""
for ((i=0; i<=5; i=i+1))
do
   if [ "${svsfx[i]}" ]; then
      ./parseTrades.sh $fd/${svsfx[i]}.csv
      if [ "${svsfx_accts}" ]; then
         svsfx_accts=$svsfx_accts", "${svsfx[i]}
      else
         svsfx_accts=${svsfx[i]}
      fi
   fi
done

activ_accts=""
for ((i=0; i<=5; i=i+1))
do
   if [ "${activ[i]}" ]; then
      ./parseTrades.sh $fd/${activ[i]}.csv
      if [ "${activ_accts}" ]; then
         activ_accts=$activ_accts", "${activ[i]}
      else
         activ_accts=${activ[i]}
      fi
   fi
done

if [ $# -lt 1 ]; then
   txdate=`date -v -1d +%Y%m%d`
else
   txdate=$1
fi

./plSummary.sh $txdate
