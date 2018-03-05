#!/bin/bash
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
# 需要安装jq：yum install jq
# 需要安装wget：yum install wget


#需要环境变量
#jenkins_job=Jenkins的任务名称
#
#要部署的war包的maven相关信息
#groupId=com.thunisoft.bjsc
#artifactId=writ-web
#version=2.0.0
#
#appname=writ
#war包备份到什么位置
#packagebase=/BJSC_UPDATE/package
#要发布到的tomcat地址
#tomcatbase=/opt/thunisoft/apache-tomcat-8280-writ


download(){
	JENKINS_PREFIX=http://172.18.10.29:8080/jenkins/job/$jenkins_job
	
	package=war
	
	json=`curl --silent $JENKINS_PREFIX/api/json`
	if [ $? -ne 0 ]; then
		echo -e "\033[31m 【$appname】访问Jenkins服务失败，请检查\033[0m"
		exit 1
	fi
	lastBuildNumber=`jq '.lastBuild.number' <<< $json`
	lastStableBuildNumber=`jq '.lastStableBuild.number' <<< $json`
	lastSuccessfulBuildNumber=`jq '.lastSuccessfulBuild.number' <<< $json`

	
	if [ $lastSuccessfulBuildNumber != $lastBuildNumber ]; then
		echo -e "\033[33m 【$appname】最近构建【编号$lastBuildNumber】不成功，请检查\033[0m"
	elif [ $lastStableBuildNumber != $lastBuildNumber ]; then
		echo -e "\033[33m 【$appname】最近构建【编号$lastBuildNumber】不稳定，请检查\033[0m"
	fi

	echo "【$appname】将部署Jenkins最后一次成功构建"

	package_download_dir=$packagebase/$appname/$lastSuccessfulBuildNumber
	
	package_name=$artifactId-$version.$package

	if [ -f $package_download_dir/$package_name ]; then
		echo -e "\033[31m 【$appname】最近成功的构建【编号$lastSuccessfulBuildNumber】已经部署过，请重新构建\033[0m"
		exit 2
	fi

	echo "【$appname】开始从Jenkins下载最新构建的包【编号$lastSuccessfulBuildNumber】"
	wget -P $package_download_dir $JENKINS_PREFIX/$lastSuccessfulBuildNumber/$groupId\$$artifactId/artifact/$groupId/$artifactId/$version/$package_name
	if [ $? -ne 0 ]; then
		echo -e "\033[31m 【$appname】下载自动构建包失败，请检查\033[0m"
		exit 3
	else
		echo "【$appname】下载最新构建的包成功"
	fi
}



deploy(){
	echo "【$appname】开始部署应用"
	ps -ef | grep $tomcatbase | grep -v grep | awk '{print $2}\' | xargs kill -15
	if [ -d "$tomcatbase/webapps/$appname" ]; then
		find $tomcatbase/webapps/$appname/* -print0 | xargs -0 rm -rf
	else
		`mkdir -p "$tomcatbase/webapps/$appname"`
	fi
	cd "$tomcatbase/webapps/$appname"
	jar xf $1
	find $tomcatbase/logs/* -print0 | xargs -0 rm -rf
	find $tomcatbase/work/* -print0 | xargs -0 rm -rf
	echo "【$appname】部署完成"
}




download

if [ $? -ne 0 ]; then
	if [ $? -ne 1 ]; then
		rm -f $package_download_dir/$package_name
	fi
	echo -e "\033[31m 【$appname】下载自动构建包失败，请检查\033[0m"
	exit
fi

deploy $package_download_dir/$package_name



cd "$tomcatbase/"
bash "$tomcatbase/bin/startup.sh" 2&>1 1>>$packagebase/tomcat.log