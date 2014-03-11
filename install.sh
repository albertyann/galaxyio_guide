#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

clear

cur_dir=$(pwd)

echo 'GalaxyIO storage system install...'
echo 'yum update && yum upgrade'
#set mysql root password
echo "==========================="

mysqlrootpwd="root"
echo "Please input the root password of mysql:"
read -p "(Default password: root):" mysqlrootpwd
if [ "$mysqlrootpwd" = "" ]; then
	mysqlrootpwd="root"
fi
echo "==========================="
echo "MySQL root password:$mysqlrootpwd"
echo "==========================="

function InitInstall()
{
	#yum update -y
	#yum upgrade -y

	rpm -qa|grep httpd
	rpm -e httpd
	rpm -qa|grep mysql
	rpm -e mysql
	rpm -qa|grep php
	rpm -e php

	yum -y remove httpd*
	yum -y remove php*
	yum -y remove mysql-server mysql
	yum -y remove php-mysql

	#Disable SeLinux
	if [ -s /etc/selinux/config ]; then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	fi

	#for packages in patch make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal nano gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap;
	#do yum -y install $packages; done
}

function InstallLsscsi()
{
	cd $cur_dir
	if [ -s lsscsi-0.27.tgz ]; then
		echo "lsscsi-0.27.tgz [found]"
	else
		echo "Error: lsscsi-0.27.tgz not found! download now ..."
		wget http://sg.danny.cz/scsi/lsscsi-1.27.tgz
	fi

	tar zxvf lsscsi-0.27.tgz
	cd lsscsi-0.27
	./configure --bindir=/usr/bin
	make && make install
	cd ../

	rm -rf lsscsi-0.27
}

function InstallLighttpd()
{
	wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	rpm -ivh epel-release-6-8.noarch.rpm
	yum install -y lighttpd

	/etc/init.d/lighttpd start
}

function InstallZFS()
{
	yum localinstall --nogpgcheck http://archive.zfsonlinux.org/epel/zfs-release-1-3.el6.noarch.rpm
	yum install -y zfs
}

function InstallSamba4()
{
	echo 'intall samba'
	yum remove -y samba-common
	yum install -y samba4.x86_64 samba4-client.x86_64 samba4-common.x86_64 samba4-dc.x86_64 samba4-dc-libs.x86_64 samba4-devel.x86_64 samba4-libs.x86_64 samba4-pidl.x86_64 samba4-python.x86_64 samba4-swat.x86_64

	chkconfig smb on

	mkdir /var/lib/samba/usershares
	chgrp users /var/lib/samba/usershares
	chmod 1770 /var/lib/samba/usershares
}

function InstallPHP()
{
	yum install -y php php-cli php-xml php-common php-gd php-pdo php-pear php-mysql php-php-gettext php-fpm php-mbstring
	if [ -s /etc/php.ini ]; then
		sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php.ini
	fi
}

function InstallMysql()
{
	yum remove  -y mysql mysql-server
	yum install -y mysql mysql-server

	/etc/init.d/mysqld start

	/usr/bin/mysqladmin -u root password $mysqlrootpwd

	cat > /tmp/mysql_sec_script<<EOF
	use mysql;
	update user set password=password('$mysqlrootpwd') where user='root';
	delete from user where not (user='root') ;
	delete from user where user='root' and password='';
	drop database test;
	DROP USER ''@'%';
	flush privileges;
EOF

	/usr/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script

	rm -f /tmp/mysql_sec_script

	/etc/init.d/mysqld restart

	echo "Mysql install success."
}


#InitInstall #2>&1 | tee /root/galaxyio-install.log
#InstallLighttpd #2>&1 | tee /root/galaxyio-install.log
#InstallSamba4 #2>&1 | tee /root/galaxyio-install.log
#InstallLsscsi #2>&1 | tee /root/galaxyio-install.log
#InstallZFS #2>&1 | tee /root/galaxyio-install.log
#InstallPHP #2>&1 | tee /root/galaxyio-install.log
#InstallMysql #2>&1 | tee /root/galaxyio-install.log
echo ""
echo "Install successfully."
echo "Mysql root password "$mysqlrootpwd
echo ""
read -p "reboot now. [Y/N]:" yn
if [ "$yn" == "y" -o  "$yn" == "yes" -o "$yn" = "Y" ]; then
	reboot
fi
