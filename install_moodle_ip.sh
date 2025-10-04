#!/bin/bash

# =========================================================
# Auto Installer LMS Moodle on LAMP Stack
# by Abdur Rozak, SMKS YASMIDA Ambarawa
# GitHub: https://github.com/abdurrozakskom
# License: MIT
# =========================================================

# ---- Pastikan root ----
if [ "$(id -u)" -ne 0 ]; then
  echo "Harus dijalankan sebagai root" >&2
  exit 1
fi

# ---- Logging ----
LOGFILE="/var/log/moodle_installer.log"
echo "Log akan disimpan di $LOGFILE"
exec > >(tee -a $LOGFILE) 2>&1

# ---- Verifikasi Password Sebelum Instalasi ---
echo -n "Masukkan password untuk konfirmasi instalasi: "
read -s password1
echo

echo -n "Masukkan ulang password: "
read -s password2
echo

if [ "$password1" != "$password2" ]; then
  echo "Password tidak cocok. Keluar."
  exit 1
fi

# ---- Input User ----
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "IP Server terdeteksi: $SERVER_IP"
echo -n "Gunakan IP ini? [Y/n]: "
read use_detected_ip
if [[ "$use_detected_ip" =~ ^([nN])$ ]]; then
  read -p "Masukkan IP Address server: " SERVER_IP
fi

read -p "Masukkan direktori web root (misalnya /var/www/moodle): " WEBROOT
read -p "Masukkan nama database: " DBNAME
read -p "Masukkan user database: " DBUSER
read -s -p "Masukkan password database: " DBPASS
echo

# ---- Update Sistem ----
echo "[1/9] Update & Upgrade..."
apt update && apt upgrade -y

# ---- Paket Pendukung ----
echo "[2/9] Install paket pendukung..."
apt install -y unzip curl git software-properties-common

# ---- Install LAMP Stack ----
echo "[3/9] Install Apache, MariaDB, PHP..."
apt install -y apache2 mariadb-server mariadb-client
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php php-cli php-fpm php-mysql php-xmlrpc php-curl php-gd php-intl php-mbstring php-xml php-zip graphviz aspell ghostscript

# ---- Tuning Apache2 ----
echo "[4/9] Tuning Apache2..."
a2enmod proxy_fcgi setenvif rewrite
a2enconf php*-fpm
systemctl restart apache2

# ---- Tuning PHP-FPM ----
echo "[5/9] Tuning PHP-FPM..."
PHPVER=$(php -v | head -n 1 | cut -d" " -f2 | cut -d"." -f1,2)
PHPCONF="/etc/php/$PHPVER/fpm/php.ini"
sed -i "s/memory_limit = .*/memory_limit = 512M/" $PHPCONF
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" $PHPCONF
sed -i "s/post_max_size = .*/post_max_size = 100M/" $PHPCONF
systemctl restart php$PHPVER-fpm

# ---- Setup Database MariaDB ----
echo "[6/9] Setup Database..."
mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---- Download LMS Moodle via GitHub ----
echo "[7/9] Download Moodle dari GitHub..."
if [ ! -d "$WEBROOT" ]; then
  git clone https://github.com/moodle/moodle.git $WEBROOT
else
  cd $WEBROOT && git pull
fi
chown -R www-data:www-data $WEBROOT
chmod -R 755 $WEBROOT

# ---- VirtualHost ----
echo "[8/9] Konfigurasi VirtualHost..."
VHOST="/etc/apache2/sites-available/moodle.conf"
cat > $VHOST <<EOF
<VirtualHost *:80>
    ServerAdmin admin@$SERVER_IP
    ServerName $SERVER_IP
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
EOF

a2ensite moodle.conf
a2dissite 000-default.conf
systemctl reload apache2

# ---- Summary ----
echo "[9/9] Instalasi selesai"
echo "============================================="
echo " Moodle berhasil diinstal."
echo " Akses di: http://$SERVER_IP "
echo " Database: $DBNAME"
echo " DB User : $DBUSER"
echo " Webroot : $WEBROOT"
echo " Log file: $LOGFILE"
echo "============================================="
