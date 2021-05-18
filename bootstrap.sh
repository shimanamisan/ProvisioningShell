#!/bin/bash

# 初回に起動時にCentOSを最新の状態にしておく
function os_update()
{
   if [ -f /home/vagrant/os_update ]; then
      echo "[INFO] CentOSは最新です"
   else

      dnf -y upgrade

      # 処理の終了コードを取得
      RESULT=$?
      # 結果のチェック
      if [ $RESULT -eq 0 ]; then
         echo "[INFO] 最新のCentOSに更新されました。vagrant reloadコマンドを実行して再起動してください。"
         date > /home/vagrant/os_update
         exit 0;
      else
         error "[ERROR] os_updateでエラーが発生 異常終了"
         exit 1;
      fi
   fi
}


# testコマンドを使った書き方
# if test -f /home/vagrant/bootstrapped ; then
if [ -f /home/vagrant/bootstrapped ]; then

echo "[INFO] 全ての設定が完了しています。"

else

touch /home/vagrant/script_logs


# パッケージを更新・インストールする関数
function additional_package()
{
   if [ -f /home/vagrant/additional_package_done ]; then
      echo "[INFO] additional_package 既に設定済みです"
      return 0
   fi

   dnf -y install vim
   dnf -y install git
   dnf -y install wget
   dnf -y install unzip

   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] additional_packageの処理終了"
      date > /home/vagrant/additional_package_done
      return 0
   else
      error "[ERROR] 予期せぬエラーが発生 異常終了"
      return 1
   fi
}


function apache_install_and_setting_do()
{
    if [ -f /home/vagrant/php_install_and_setting_done ]; then
      echo "[INFO] apache_install_and_setting_do 既に設定済みです"
      return 0
   fi
   
   dnf install -y httpd httpd-tools httpd-devel httpd-manual
   systemctl start httpd
   systemctl enable httpd
   cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_old
   sed -i -e "s/#ServerName.*w.*/ServerName www.example.com:80/" /etc/httpd/conf/httpd.conf
   sed -e 's/\(.*\)Indexes\(.*\)/\1\2/g' /etc/httpd/conf/httpd.conf
   
   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] apache_install_and_setting_doの処理終了"
      date > /home/vagrant/apache_install_and_setting_done
      return 0
   else
      error "[ERROR] apache_install_and_setting_doでエラーが発生 異常終了"
      return 1
   fi
}


function php_install_and_setting_do()
{
   if [ -f /home/vagrant/php_install_and_setting_done ]; then
      echo "[INFO] php_install_and_setting_do 既に設定済みです"
      return 0
   fi

   dnf install -y httpd httpd-tools httpd-devel httpd-manual
   cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_old
   dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
   dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
   dnf module disable php
   dnf module install -y php:remi-7.4
   dnf install -y php-mysqlnd php-xmlrpc php-pear php-gd php-pdo php-intl php-mysql php-mbstring
   
   cp /etc/php.ini /etc/php.ini_old

   # ヒアドキュメント
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
   # 検索した文字列の先頭に文字列を追加する（ここではコメントアウトしている）
   sed -i -e "/listen\..*_.*apache/s/^/;/g" /etc/php-fpm.d/www.conf
   # ()で指定した箇所は残して一部分を置き換える
   sed -i -e "s/\(.*\) = 50$/\1 = 25/g" /etc/php-fpm.d/www.conf
   sed -i -e "s/\(.*\) = 5$/\1 = 10/g" /etc/php-fpm.d/www.conf
   sed -i -e "s/\(.*\) = 35$/\1 = 20/g" /etc/php-fpm.d/www.conf

   cat >> /etc/php-fpm.d/www.conf << "EOF"

listen.owner = apache
listen.group = apache
listen.mode = 0660
pm.max_requests = 500
EOF

   systemctl start php-fpm
   systemctl enable php-fpm
   
   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] php_install_and_setting_doの処理終了"
      date > /home/vagrant/php_install_and_setting_done
      return 0
   else
      error "[ERROR] php_install_and_setting_doでエラーが発生 異常終了"
      return 1
   fi
}


function mysql_install_and_setting_do()
{
   if [ -f /home/vagrant/mysql_install_and_setting_done ]; then
      echo "[INFO] mysql_install_and_setting_do 既に設定済みです"
      return 0
   fi

   dnf install -y @mysql
   systemctl start mysqld
   systemctl enable mysqld

   if [ -f /etc/my.cnf.d/common.cnf ]; then
      echo "[INFO] mysqlは既に設定済みです"
   else
      touch /etc/my.cnf.d/common.cnf
      cat >> /etc/my.cnf.d/common.cnf << "EOF"
# 文字コード設定/照合順序設定
[mysqld]
collation_server = utf8mb4_ja_0900_as_cs_ks
EOF

   systemctl restart mysqld
   systemctl status mysqld
   fi

   # パッケージをダウンロード済みの場合は以下の処理を行わない
   if [ -f /home/vagrant/phpMyAdmin-5.0.2-all-languages.zip ]; then
      echo "[INFO] phpMyAdminは既に設定済みです"
      
   else
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
      # 指定した文字列の先頭をコメントアウトする
      sed -i -e "s/.*blowfish_secret.*/\/\/&/g" /usr/share/phpMyAdmin/config.inc.php
      # マッチした文字列の次の行に指定した文字列を追加
      sed -i -e "/.*blowfish_secret.*/a \$cfg['blowfish_secret'] = '任意のパスワードを設定';" /usr/share/phpMyAdmin/config.inc.php
fi


   if [ -f /home/vagrant/file_bundled_sql ]; then
      echo "[INFO] mysql自動接続用のファイルは既に存在しています"
      
   else

      touch /home/vagrant/file_bundled_sql
      cat >> /home/vagrant/file_bundled_sql << "EOF"
use mysql;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'phpMyAdminに設定したパスワードと合わせる';
EOF
   fi

   mysql -u root --password= < '/home/vagrant/file_bundled_sql'
   
   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] mysql_install_and_setting_doの処理終了"
      date > /home/vagrant/mysql_install_and_setting_done
      return 0
   else
      error "[ERROR] mysql_install_and_setting_doでエラーが発生 異常終了"
      return 1
   fi
}


function confirm_service_status()
{
   systemctl restart httpd
   systemctl restart mysqld
   systemctl restart php-fpm

   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] confirm_service_statusの処理終了"
      return 0
   else
      error "[ERROR] confirm_service_statusでエラーが発生 異常終了"
      return 1
   fi
}


function creating_phpinfo_file()
{
   if [ -f /home/vagrant/creating_phpinfo_file_done ]; then
      echo "[INFO] creating_phpinfo_file 既に設定済みです"
      return 0
   fi
   touch /var/www/html/index.php
   cat >> /var/www/html/index.php << "EOF"
   <?php
      phpinfo();
   ?>
EOF

   # 処理の終了コードを取得
   RESULT=$?
   # 結果のチェック
   if [ $RESULT -eq 0 ]; then
      echo "[INFO] creating_phpinfo_fileの処理終了"
      date > /home/vagrant/creating_phpinfo_file_done
      return 0
   else
      error "[ERROR] confirm_service_statusでエラーが発生 異常終了"
      return 1
   fi
}


# 標準出力を標準エラーに上書きしてメッセージを表示
function error()
{
    echo "$@" 1>&2
    exit 1
}


# 関数を実行する
os_update
additional_package
apache_install_and_setting_do
php_install_and_setting_do
mysql_install_and_setting_do
creating_phpinfo_file
confirm_service_status

date > /home/vagrant/bootstrapped
fi