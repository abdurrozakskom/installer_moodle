#!/bin/bash

# =========================================================
# Auto Installer LMS Moodle on LAMP Stack
# by Abdur Rozak, SMKS YASMIDA Ambarawa
# GitHub: https://github.com/abdurrozakskom
# License: MIT
# =========================================================
# GitHub   : https://github.com/abdurrozakskom
# YouTube  : https://www.youtube.com/@AbdurRozakSKom
# Instagram: https://instagram.com/abdurrozak.skom
# Facebook : https://facebook.com/abdurrozak.skom
# TikTok   : https://tiktok.com/abdurrozak.skom
# Threads  : https://threads.com/@abdurrozak.skom
# Lynk.id  : https://lynk.id/abdurrozak.skom
# Donasi:
# • Saweria  : https://saweria.co/abdurrozakskom
# • Trakteer : https://trakteer.id/abdurrozakskom/gift
# • Paypal   : https://paypal.me/abdurrozakskom
# =========================================================
# ---- Warna ----
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"



# ---- Pastikan root atau verifikasi sudo ----
echo -e "${GREEN}==========================================${RESET}"
echo "🔐 Verifikasi Hak Akses Root"
echo -e "${GREEN}==========================================${RESET}"

if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  Script ini memerlukan hak akses root."
    echo "Silakan masukkan password sudo Anda untuk melanjutkan..."
    sudo -v
    if [ $? -ne 0 ]; then
        echo "❌ Verifikasi sudo gagal. Instalasi dibatalkan."
        exit 1
    else
        echo "✅ Verifikasi sudo berhasil. Melanjutkan instalasi..."
    fi
else
    echo "✅ Anda sudah login sebagai root. Melanjutkan instalasi..."
fi

# ---- Logging ----
LOGFILE="/var/log/moodle_installer.log"
echo -e "${GREEN}==========================================${RESET}"
echo "📜 Log akan disimpan di $LOGFILE"
echo -e "${GREEN}==========================================${RESET}"
exec > >(tee -a $LOGFILE) 2>&1


# Perpanjang sesi sudo selama instalasi
( while true; do sudo -v; sleep 60; done ) &


# ---- Input User ----
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}==========================================${RESET}"
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
echo -e "${GREEN}==========================================${RESET}"
echo

# ---- Update Sistem ----
echo -e "${GREEN}==========================================${RESET}"
echo "[1/10] Update & Upgrade..."
echo -e "${GREEN}==========================================${RESET}"
apt update && apt upgrade -y

# ---- Paket Pendukung ----
echo -e "${GREEN}==========================================${RESET}"
echo "[2/10] Install paket pendukung..."
echo -e "${GREEN}==========================================${RESET}"
apt install -y unzip curl git software-properties-common

# ---- Install LAMP Stack ----
echo -e "${GREEN}==========================================${RESET}"
echo "[3/10] Install Apache, MariaDB, PHP..."
echo -e "${GREEN}==========================================${RESET}"
apt install -y apache2 mariadb-server mariadb-client
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php php-cli php-fpm php-mysql php-xmlrpc php-curl php-gd php-intl php-mbstring php-xml php-zip graphviz aspell ghostscript

# ---- Tuning Apache2 ----
echo -e "${GREEN}==========================================${RESET}"
echo "[4/10] Tuning Apache2..."
echo -e "${GREEN}==========================================${RESET}"
a2enmod proxy_fcgi setenvif rewrite
a2enconf php*-fpm
systemctl restart apache2

# ---- Tuning PHP-FPM ----
echo -e "${GREEN}==========================================${RESET}"
echo "[5/10] Tuning PHP-FPM..."
echo -e "${GREEN}==========================================${RESET}"
PHPVER=$(php -v | head -n 1 | cut -d" " -f2 | cut -d"." -f1,2)
PHPCONF="/etc/php/$PHPVER/fpm/php.ini"
sed -i "s/memory_limit = .*/memory_limit = 512M/" $PHPCONF
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" $PHPCONF
sed -i "s/post_max_size = .*/post_max_size = 100M/" $PHPCONF
systemctl restart php$PHPVER-fpm

# ---- Setup Database MariaDB ----
echo -e "${GREEN}==========================================${RESET}"
echo "[6/10] Setup Database..."
echo -e "${GREEN}==========================================${RESET}"
mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---- Tuning MariaDB Otomatis ----
echo -e "${GREEN}==========================================${RESET}"
echo "[7/10] Tuning MariaDB otomatis berdasarkan RAM..."
echo -e "${GREEN}==========================================${RESET}"
MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
cp $MARIADB_CONF ${MARIADB_CONF}.bak

# Deteksi RAM dalam MB
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

# Default value
INNODB_BUFFER="256M"
INNODB_LOG="64M"
MAX_CONN="150"

if [ $TOTAL_RAM -ge 16000 ]; then
  # Server >=16GB RAM
  INNODB_BUFFER="8G"
  INNODB_LOG="1G"
  MAX_CONN="500"
elif [ $TOTAL_RAM -ge 8000 ]; then
  # Server >=8GB RAM
  INNODB_BUFFER="4G"
  INNODB_LOG="512M"
  MAX_CONN="400"
elif [ $TOTAL_RAM -ge 4000 ]; then
  # Server >=4GB RAM
  INNODB_BUFFER="2G"
  INNODB_LOG="256M"
  MAX_CONN="300"
elif [ $TOTAL_RAM -ge 2000 ]; then
  # Server >=2GB RAM
  INNODB_BUFFER="1G"
  INNODB_LOG="128M"
  MAX_CONN="200"
else
  # Server kecil <2GB
  INNODB_BUFFER="256M"
  INNODB_LOG="64M"
  MAX_CONN="100"
fi

cat >> $MARIADB_CONF <<EOF

# =====================================
# Custom MariaDB Optimized for Moodle
# Auto-generated by install_moodle_lamp.sh
# Detected RAM: ${TOTAL_RAM}MB
# =====================================
[mysqld]
innodb_buffer_pool_size = $INNODB_BUFFER
innodb_log_file_size    = $INNODB_LOG
innodb_file_per_table   = 1
innodb_flush_log_at_trx_commit = 2
max_connections         = $MAX_CONN
query_cache_type        = 1
query_cache_size        = 64M
tmp_table_size          = 64M
max_heap_table_size     = 64M
EOF

systemctl restart mariadb
echo "MariaDB dituning otomatis: RAM=${TOTAL_RAM}MB, BufferPool=$INNODB_BUFFER, MaxConn=$MAX_CONN"


# ---- Download LMS Moodle via GitHub ----
echo -e "${GREEN}==========================================${RESET}"
echo "[8/10] Download Moodle dari GitHub..."
echo -e "${GREEN}==========================================${RESET}"
if [ ! -d "$WEBROOT" ]; then
  git clone https://github.com/moodle/moodle.git $WEBROOT
else
  cd $WEBROOT && git pull
fi
chown -R www-data:www-data $WEBROOT
chmod -R 755 $WEBROOT

# ---- Konfigurasi VirtualHost ----
echo -e "${GREEN}==========================================${RESET}"
echo "[9/10] Konfigurasi VirtualHost..."
echo -e "${GREEN}==========================================${RESET}"
WEBROOT="$WEBROOT"
cat <<EOF > /etc/apache2/sites-available/moodle.conf
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
EOF

# Aktifkan modul dan site
a2enmod rewrite
a2ensite moodle.conf
a2dissite 000-default.conf

# Tes konfigurasi Apache
echo "🧪 Mengecek konfigurasi Apache..."
apache2ctl configtest
if [ $? -eq 0 ]; then
    echo "✅ Konfigurasi Apache benar."
else
    echo "❌ Terdapat error di konfigurasi Apache. Cek manual dengan:"
    echo "   apache2ctl configtest"
    exit 1
fi

# Pastikan Apache aktif
if ! systemctl is-active --quiet apache2; then
    echo "🔧 Apache belum aktif, mencoba menjalankan..."
    systemctl start apache2
fi

# Reload Apache
echo "🔄 Reload Apache service..."
systemctl reload apache2 || systemctl restart apache2


# ---- Summary ----
echo ""
echo -e "${GREEN}==========================================${RESET}"
echo -e "🎉 ${GREEN}Instalasi Moodle Berhasil!${RESET}"
echo -e "${GREEN}==========================================${RESET}"

# Deteksi IP server
SERVER_IP=$(hostname -I | awk '{print $1}')

# Tampilkan link akses (klikable di terminal modern)
echo -e "🌐 Akses Moodle di: \e]8;;http://$SERVER_IP/\a${CYAN}http://$SERVER_IP/${RESET}\e]8;;\a"

# Informasi Database & File
echo -e "🗄️  Database : ${YELLOW}$DBNAME${RESET}"
echo -e "👤 DB User  : ${YELLOW}$DBUSER${RESET}"
echo -e "📂 Webroot  : ${YELLOW}$WEBROOT${RESET}"
echo -e "🪵 Log File : ${YELLOW}$LOGFILE${RESET}"

echo ""
echo -e "${GREEN}==========================================${RESET}"
echo -e "🧠 ${BLUE}Spesifikasi Server${RESET}"
echo -e "${GREEN}==========================================${RESET}"
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:\s*//')
CPU_CORES=$(nproc)
TOTAL_RAM=$(free -h | awk '/^Mem:/{print $2}')
DISK_SIZE=$(df -h / | awk 'NR==2 {print $2}')
OS_NAME=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')

echo -e "🖥️  OS         : ${CYAN}$OS_NAME${RESET}"
echo -e "⚙️  CPU        : ${CYAN}$CPU_MODEL ($CPU_CORES core)${RESET}"
echo -e "💾 RAM        : ${CYAN}$TOTAL_RAM${RESET}"
echo -e "📀 Storage    : ${CYAN}$DISK_SIZE${RESET}"

echo ""
echo -e "${GREEN}==========================================${RESET}"
echo -e "📦 ${BLUE}Paket dan Versi Terinstall${RESET}"
echo -e "${GREEN}==========================================${RESET}"

# Ambil versi setiap paket
APACHE_VERSION=$(apache2 -v | grep "Server version" | awk '{print $3}' | cut -d'/' -f2)
MARIADB_VERSION=$(mariadb --version | awk '{print $5}' | cut -d'-' -f1)
PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}')
MOODLE_VERSION=$(grep "\$release" $WEBROOT/version.php | cut -d"'" -f2)
GIT_VERSION=$(git --version | awk '{print $3}')
CURL_VERSION=$(curl --version | head -n1 | awk '{print $2}')
ZIP_VERSION=$(zip -v | head -n1 | awk '{print $2}')
UNZIP_VERSION=$(unzip -v | head -n1 | awk '{print $2}')
UFW_STATUS=$(ufw status | head -n1)

echo -e "🧩 Apache2   : ${GREEN}v$APACHE_VERSION${RESET}"
echo -e "🧩 MariaDB   : ${GREEN}v$MARIADB_VERSION${RESET}"
echo -e "🧩 PHP-FPM   : ${GREEN}v$PHP_VERSION${RESET}"
echo -e "🧩 Moodle    : ${GREEN}$MOODLE_VERSION${RESET}"
echo -e "🧩 Git       : ${GREEN}v$GIT_VERSION${RESET}"
echo -e "🧩 Curl      : ${GREEN}v$CURL_VERSION${RESET}"
echo -e "🧩 Zip/Unzip : ${GREEN}v$ZIP_VERSION / v$UNZIP_VERSION${RESET}"
echo -e "🧩 Firewall  : ${GREEN}$UFW_STATUS${RESET}"

echo ""
echo -e "${GREEN}==========================================${RESET}"
echo -e "🚀 ${BLUE}Instalasi Selesai!${RESET}"
echo -e "${GREEN}==========================================${RESET}"
echo -e "Silakan buka Moodle Anda di browser:"
echo -e "➡️  ${YELLOW}http://$SERVER_IP/${RESET}"
echo ""
echo -e "${RED}Untuk keamanan disarankan:${RESET}"
echo -e "🔒 Aktifkan HTTPS (Let's Encrypt / Certbot)"
echo -e "🛡️  Konfigurasi Firewall (UFW)"
echo -e "⚡ Tuning tambahan PHP dan MariaDB jika dibutuhkan"
echo -e "${GREEN}==========================================${RESET}"


# ---- Credit Author ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${CYAN}📌 Credit Author:${RESET}"
echo -e "${YELLOW}Abdur Rozak, SMKS YASMIDA Ambarawa${RESET}"
echo -e "${YELLOW}GitHub : \e]8;;https://github.com/abdurrozakskom\ahttps://github.com/abdurrozakskom\e]8;;\a${RESET}"
echo -e "${YELLOW}YouTube: \e]8;;https://www.youtube.com/@AbdurRozakSKom\ahttps://www.youtube.com/@AbdurRozakSKom\e]8;;\a${RESET}"
echo ""
# ---- Donasi ----
echo -e "${CYAN}💖 Jika script ini bermanfaat, silakan donasi untuk mendukung pengembangan:${RESET}"
echo -e "${YELLOW}• Saweria  : \e]8;;https://saweria.co/abdurrozakskom\ahttps://saweria.co/abdurrozakskom\e]8;;\a${RESET}"
echo -e "${YELLOW}• Trakteer : \e]8;;https://trakteer.id/abdurrozakskom/gift\ahttps://trakteer.id/abdurrozakskom/gift\e]8;;\a${RESET}"
echo -e "${YELLOW}• Paypal   : \e]8;;https://paypal.me/abdurrozakskom\ahttps://paypal.me/abdurrozakskom\e]8;;\a${RESET}"
echo ""
# ---- Sosial Media ----
echo -e "${CYAN}🌐 Ikuti sosial media resmi untuk update & info:${RESET}"
echo -e "${YELLOW}• GitHub    : \e]8;;https://github.com/abdurrozakskom\ahttps://github.com/abdurrozakskom\e]8;;\a${RESET}"
echo -e "${YELLOW}• Lynk.id   : \e]8;;https://lynk.id/abdurrozak.skom\ahttps://lynk.id/abdurrozak.skom\e]8;;\a${RESET}"
echo -e "${YELLOW}• Instagram : \e]8;;https://instagram.com/abdurrozak.skom\ahttps://instagram.com/abdurrozak.skom\e]8;;\a${RESET}"
echo -e "${YELLOW}• Facebook  : \e]8;;https://facebook.com/abdurrozak.skom\ahttps://facebook.com/abdurrozak.skom\e]8;;\a${RESET}"
echo -e "${YELLOW}• TikTok    : \e]8;;https://tiktok.com/abdurrozak.skom\ahttps://tiktok.com/abdurrozak.skom\e]8;;\a${RESET}"
echo -e "${YELLOW}• Threads   : \e]8;;https://threads.com/@abdurrozak.skom\ahttps://threads.com/@abdurrozak.skom\e]8;;\a${RESET}"
echo -e "${YELLOW}• YouTube   : \e]8;;https://www.youtube.com/@AbdurRozakSKom\ahttps://www.youtube.com/@AbdurRozakSKom\e]8;;\a${RESET}"
echo -e "${GREEN}==========================================${RESET}"
