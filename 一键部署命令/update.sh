#!/bin/bash
echo ">>>>>>>>>>清理目录>>>>>>>>>>>>>>"
basePath=/BJSC_UPDATE
sourcePath=$basePath/source

if [ ! -d "$sourcePath" ];then
	mkdir -p "$sourcePath"
else
	rm -rf $sourcePath/*
fi

echo ">>>>>>>>>>检出holiday>>>>>>>>>>>>>>"
svn export https://172.18.10.10/svn/JCW_BJHD_BA_XBA/40_源码/holiday  --username xingxm $sourcePath/holiday > $sourcePath/export.log 2>$sourcePath/export_err.log
echo ">>>>>>>>>>检出number>>>>>>>>>>>>>>"
svn export https://172.18.10.10/svn/JCW_BJHD_BA_XBA/40_源码/number --username xingxm $sourcePath/number > $sourcePath/export.log 2>$sourcePath/export_err.log
echo ">>>>>>>>>>检出timelimit>>>>>>>>>>>>>>"
svn export https://172.18.10.10/svn/JCW_BJHD_BA_XBA/40_源码/timelimit --username xingxm $sourcePath/timelimit > $sourcePath/export.log 2>$sourcePath/export_err.log
echo ">>>>>>>>>>检出writ>>>>>>>>>>>>>>"
svn export https://172.18.10.10/svn/JCW_BJHD_BA_XBA/40_源码/writ --username xingxm $sourcePath/writ > $sourcePath/export.log 2>$sourcePath/export_err.log

echo ">>>>>>>>>>检出完成>>>>>>>>>>>>>>"

echo "==========打包holiday=========="
cd $sourcePath/holiday
mvn package 2>$sourcePath/package.err 1>>$sourcePath/package.log
echo "==========打包number==========="
cd $sourcePath/number
mvn package 2>$sourcePath/package.err 1>>$sourcePath/package.log
echo "========打包timelimit=========="
cd $sourcePath/timelimit
mvn package 2>$sourcePath/package.err 1>>$sourcePath/package.log
echo "==========打包writ============="
cd $sourcePath/writ/writ-web
mvn package 2>$sourcePath/package.err 1>>$sourcePath/package.log

echo "==========打包完成============="

send=`date '+%Y-%m-%d_%H_%M_%S'`

packagedir=$basePath/升级包/$send
if [ ! -d "$packagedir" ];then
	mkdir -p "$packagedir"
fi

echo "==========备份到$packagedir============="
cp $sourcePath/holiday/holiday-web/target/holiday.war "$packagedir/holiday.war"
cp $sourcePath/number/serial-web/target/number.war $packagedir/number.war
cp $sourcePath/timelimit/timelimit-web/target/timelimit.war $packagedir/timelimit.war
cp $sourcePath/writ/writ-web/target/writ.war $packagedir/writ.war
echo "==========备份完成============="

ps aux | grep apache-tomcat-82 | grep -v grep | cut -c 9-15 | xargs kill -15

deploy(){
	echo "开始部署$2"
	local tomcatbase="/opt/thunisoft/apache-tomcat-$1-$2"
	if [ -d "$tomcatbase/webapps" ]; then
		rm -rf "$tomcatbase/webapps/"
		echo "清理部署目录$tomcatbase/webapps/"
	else
		echo "$tomcatbase/webapps不存在"
	fi
	mkdir -p "$tomcatbase/webapps/$2"
	cd "$tomcatbase/webapps/$2"
	jar xf "$packagedir/$2.war"
	rm -rf "$tomcatbase/logs"
	mkdir -p "$tomcatbase/logs"
	rm -rf "$tomcatbase/work"
	mkdir -p "$tomcatbase/work"
	cd "$tomcatbase/bin/"
	sh "$tomcatbase/bin/startup.sh" 2&>1 1>>$basePath/tomcat.log
	echo "部署$2完成"
}

deploy 8280 writ
deploy 8281 number
deploy 8282 holiday
deploy 8283 timelimit