# ホームディレクトリにファイルが存在していたら終了
if test -f /home/vagrant/bootstrapped ; then

echo "何もしない"
# rm -rf /home/vagrant/bootstrapped

else

echo "Change Root User"
# rootユーザーに切り替え
sudo -i

echo "Install Package"
dnf -y upgrade
dnf -y install vim
dnf -y install git
dnf -y install wget
dnf -y install unzip
  
echo "Install & Setting httpd"
dnf install -y httpd httpd-tools httpd-devel httpd-manual
systemctl start httpd
systemctl enable httpd
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_old

echo "Install & Setting PHP"
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module disable php
dnf module install -y php:remi-7.4
dnf install -y php-mysqlnd php-xmlrpc php-pear php-gd php-pdo php-intl php-mysql php-mbstring

echo "Install PHP"
php -v
echo " "
cp /etc/php.ini /etc/php.ini_old

cat >> /etc/php.ini << "EOF"

date.timezone = Asia/Tokyo
mbstring.language = Japanese
mbstring.internal_encoding = UTF-8
mbstring.http_input = UTF-8
mbstring.http_output = pass
mbstring.encoding_translation = On
mbstring.detect_order = auto
mbstring.substitute_character = none
upload_max_filesize = 128M
post_max_size = 128M
EOF

cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf_old

cat >> /etc/php-fpm.d/www.conf << "EOF"

listen.owner = apache
listen.group = apache
listen.mode = 0660
pm.max_requests = 500
EOF

systemctl restart httpd
systemctl start php-fpm
systemctl enable php-fpm

echo " "
echo "status: php-fpm"
systemctl status php-fpm
echo " "

echo "Install MySQL"
dnf install -y @mysql
systemctl enable mysqld
systemctl start mysqld

echo " "
echo "status: php-fpm"
systemctl status mysqld
echo " "
touch /etc/my.cnf.d/common.cnf
cat >> /etc/my.cnf.d/common.cnf << "EOF"

# 文字コード設定/照合順序設定
[mysqld]
collation_server = utf8mb4_ja_0900_as_cs_ks
EOF

systemctl restart mysqld
echo " "
echo "status: mysqld"
systemctl status mysqld
echo " "

wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.zip
unzip phpMyAdmin-5.0.2-all-languages.zip
mv phpMyAdmin-5.0.2-all-languages /usr/share/phpMyAdmin
cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
touch /etc/httpd/conf.d/phpMyAdmin.conf
cat >> /etc/httpd/conf.d/phpMyAdmin.conf << "EOF"

Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
AddDefaultCharset UTF-8

   <IfModule mod_authz_core.c>
    #Apache 2.4
    <RequireAny>
     Require all granted
    </RequireAny>
  </IfModule>
</Directory>

<Directory /usr/share/phpMyAdmin/setup/>
   <IfModule mod_authz_core.c>
    #Apache 2.4
    <RequireAny>
     Require all granted
    </RequireAny>
   </IfModule>
</Directory>
EOF

sed -i -e "/.*blowfish_secret.*/d" /usr/share/phpMyAdmin/config.inc.php
cat >> /usr/share/phpMyAdmin/config.inc.php << "EOF"
$cfg['blowfish_secret'] = '';
EOF

systemctl restart httpd
echo " "
echo "status: mysqld"
systemctl status httpd
echo " "

echo "/etc/httpd/conf/httpd.conf を編集する必要があります"
echo "/etc/php-fpm.d/www.conf を編集する必要があります"
echo "/usr/share/phpMyAdmin/config.inc.php を編集する必要があります"
# ホームディレクトリにファイルを作成し2回目以降は起動しないようにする
date > /home/vagrant/bootstrapped
fi