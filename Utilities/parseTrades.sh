wd=`dirname "${BASH_SOURCE-$0}"`
wd=`cd "$wd"; pwd`

java -jar $wd/fxtrade.jar $@
