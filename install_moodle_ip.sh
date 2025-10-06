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

# ---- Input Direktori Web Root ----
read -p "Masukkan direktori web root (default: /var/www/moodle): " WEBROOT
WEBROOT=${WEBROOT:-/var/www/moodle}

# ---- Input Nama Database ----
read -p "Masukkan nama database (default: dbmoodle): " DBNAME
DBNAME=${DBNAME:-dbmoodle}

# ---- Input User Database ----
read -p "Masukkan user database (default: umoodle): " DBUSER
DBUSER=${DBUSER:-umoodle}

# ---- Input Password Database ----
read -s -p "Masukkan password database (default: auto_generate): " DBPASS
echo ""
if [ -z "$DBPASS" ]; then
  DBPASS=$(openssl rand -base64 12)
  echo -e "${YELLOW}🔑 Password database dibuat otomatis: ${DBPASS}${RESET}"
fi

echo -e "${GREEN}==========================================${RESET}"
echo

# ---- Update Sistem ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}🌀 [1/10] Update & Upgrade Sistem...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
# Cek koneksi internet dulu
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}🌐 Koneksi internet terdeteksi.${RESET}"
else
    echo -e "${RED}❌ Tidak ada koneksi internet. Instalasi dibatalkan.${RESET}"
    exit 1
fi

# Jalankan update & upgrade
echo -e "${CYAN}🔄 Memperbarui daftar paket...${RESET}"
apt update -y >/dev/null 2>&1

echo -e "${CYAN}⚙️  Meng-upgrade sistem ke versi terbaru...${RESET}"
apt upgrade -y >/dev/null 2>&1

# Bersihkan paket yang tidak diperlukan
echo -e "${CYAN}🧹 Membersihkan paket lama...${RESET}"
apt autoremove -y >/dev/null 2>&1
apt autoclean -y >/dev/null 2>&1

# Cek status update
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Sistem berhasil diperbarui dan di-upgrade.${RESET}"
else
    echo ""
    echo -e "${RED}⚠️  Gagal memperbarui sistem. Periksa sumber repository Anda.${RESET}"
fi

# Tampilkan versi OS
OS_NAME=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL_VER=$(uname -r)
echo ""
echo -e "💻 Sistem Operasi : ${YELLOW}${OS_NAME}${RESET}"
echo -e "🧠 Kernel Versi   : ${YELLOW}${KERNEL_VER}${RESET}"
echo -e "📦 Update Status  : ${GREEN}Tersinkron dengan repository terbaru${RESET}"

# ---- Paket Pendukung ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}📦 [2/10] Install Paket Pendukung...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
# Update repository
apt update -y >/dev/null 2>&1

# Daftar paket pendukung umum
SUPPORT_PACKAGES=(
  software-properties-common
  lsb-release
  ca-certificates
  apt-transport-https
  curl
  wget
  gnupg
  zip
  unzip
  net-tools
  htop
  nano
  git
  ufw
)

# Install paket
apt install -y "${SUPPORT_PACKAGES[@]}" >/dev/null 2>&1

# Verifikasi hasil instalasi
echo ""
echo -e "${CYAN}🔍 Memverifikasi paket yang terpasang...${RESET}"

SUCCESS_COUNT=0
for pkg in "${SUPPORT_PACKAGES[@]}"; do
  if dpkg -l | grep -qw "$pkg"; then
    echo -e "🧩 ${pkg}   ${GREEN}✔${RESET}"
    ((SUCCESS_COUNT++))
  else
    echo -e "🧩 ${pkg}   ${RED}✖${RESET}"
  fi
done

if [ "$SUCCESS_COUNT" -eq "${#SUPPORT_PACKAGES[@]}" ]; then
  echo ""
  echo -e "${GREEN}✅ Semua paket pendukung berhasil diinstal.${RESET}"
else
  echo ""
  echo -e "${YELLOW}⚠️  Beberapa paket gagal diinstal. Periksa koneksi internet atau repository.${RESET}"
fi

# ---- Install LAMP Stack ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}💽 [3/10] Install Apache2, MariaDB, dan PHP...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
# Install paket inti LAMP + pendukung
apt install -y apache2 mariadb-server php php-fpm php-mysql php-xml php-gd php-curl php-zip php-intl php-soap php-mbstring php-ldap php-json php-bcmath unzip curl git ufw >/dev/null 2>&1

# Verifikasi instalasi
APACHE_VER=$(apache2 -v 2>/dev/null | grep "Server version" | awk '{print $3}')
MARIADB_VER=$(mariadb --version 2>/dev/null | awk '{print $5}')
PHP_VER=$(php -v 2>/dev/null | head -n 1 | awk '{print $2}')

# Cek hasil instalasi
if command -v apache2 >/dev/null && command -v mariadb >/dev/null && command -v php >/dev/null; then
    echo -e "${GREEN}✅ Instalasi LAMP Stack berhasil.${RESET}"
    echo ""
    echo -e "🧩 Apache2  : ${YELLOW}${APACHE_VER}${RESET}"
    echo -e "🧩 MariaDB  : ${YELLOW}${MARIADB_VER}${RESET}"
    echo -e "🧩 PHP-FPM  : ${YELLOW}${PHP_VER}${RESET}"
    echo -e "🧩 Ekstensi : ${YELLOW}xml, gd, curl, zip, intl, soap, mbstring, ldap, json, bcmath${RESET}"
    echo -e "🧩 Tools    : ${YELLOW}git, curl, unzip, ufw${RESET}"
else
    echo -e "${RED}❌ Instalasi gagal. Periksa koneksi internet atau repository.${RESET}"
    exit 1
fi

# Aktifkan layanan
systemctl enable apache2 >/dev/null 2>&1
systemctl enable mariadb >/dev/null 2>&1
systemctl enable php*-fpm >/dev/null 2>&1

# Mulai layanan
systemctl restart apache2
systemctl restart mariadb
systemctl restart php*-fpm

# Tes apakah layanan berjalan
if systemctl is-active --quiet apache2 && systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}🚀 Semua layanan berjalan normal.${RESET}"
else
    echo -e "${RED}⚠️  Salah satu layanan gagal dijalankan. Cek status dengan 'systemctl status'.${RESET}"
fi

# ---- Tuning Apache2 ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}🔧 [4/10] Tuning Apache2...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
# Deteksi file konfigurasi Apache
APACHE_CONF="/etc/apache2/apache2.conf"
MPM_CONF="/etc/apache2/mods-available/mpm_prefork.conf"

# Backup konfigurasi lama
cp "$APACHE_CONF" "${APACHE_CONF}.bak"
cp "$MPM_CONF" "${MPM_CONF}.bak"

# Deteksi total RAM server
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

# Tentukan parameter berdasarkan RAM
if [ "$TOTAL_RAM_MB" -le 1024 ]; then
    MAX_CLIENTS=50
    START_SERVERS=2
    MIN_SPARE=2
    MAX_SPARE=5
elif [ "$TOTAL_RAM_MB" -le 2048 ]; then
    MAX_CLIENTS=100
    START_SERVERS=4
    MIN_SPARE=4
    MAX_SPARE=10
elif [ "$TOTAL_RAM_MB" -le 4096 ]; then
    MAX_CLIENTS=150
    START_SERVERS=6
    MIN_SPARE=6
    MAX_SPARE=15
else
    MAX_CLIENTS=256
    START_SERVERS=10
    MIN_SPARE=10
    MAX_SPARE=25
fi

# Terapkan tuning MPM Prefork (untuk kompatibilitas dengan PHP-FPM)
sed -i "s/^StartServers.*/StartServers ${START_SERVERS}/" "$MPM_CONF"
sed -i "s/^MinSpareServers.*/MinSpareServers ${MIN_SPARE}/" "$MPM_CONF"
sed -i "s/^MaxSpareServers.*/MaxSpareServers ${MAX_SPARE}/" "$MPM_CONF"
sed -i "s/^MaxRequestWorkers.*/MaxRequestWorkers ${MAX_CLIENTS}/" "$MPM_CONF"
sed -i "s/^MaxConnectionsPerChild.*/MaxConnectionsPerChild 1000/" "$MPM_CONF"

# Tambahkan optimasi umum ke apache2.conf
cat <<EOF >> "$APACHE_CONF"

# ==============================
# 💨 Optimasi Apache2 Otomatis
# ==============================
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 3

ServerTokens Prod
ServerSignature Off
HostnameLookups Off
Timeout 60

# Kompresi Gzip
<IfModule mod_deflate.c>
 AddOutputFilterByType DEFLATE text/plain text/html text/xml text/css application/javascript application/json
</IfModule>

# Cache dasar
<IfModule mod_expires.c>
 ExpiresActive On
 ExpiresDefault "access plus 1 month"
</IfModule>
EOF

# Aktifkan modul penting
a2enmod rewrite deflate expires headers env dir mime > /dev/null 2>&1

# Restart Apache
if systemctl restart apache2; then
    echo -e "${GREEN}✅ Apache2 berhasil dituning dan direstart.${RESET}"
    echo ""
    echo -e "💾 Total RAM Server   : ${YELLOW}${TOTAL_RAM_MB} MB${RESET}"
    echo -e "⚙️  StartServers       : ${YELLOW}${START_SERVERS}${RESET}"
    echo -e "⚙️  MinSpareServers    : ${YELLOW}${MIN_SPARE}${RESET}"
    echo -e "⚙️  MaxSpareServers    : ${YELLOW}${MAX_SPARE}${RESET}"
    echo -e "⚙️  MaxRequestWorkers  : ${YELLOW}${MAX_CLIENTS}${RESET}"
    echo -e "⏱️  KeepAliveTimeout   : ${YELLOW}3 detik${RESET}"
    echo -e "🔒 ServerTokens        : ${YELLOW}Prod${RESET}"
    echo -e "💨 Modul Aktif         : ${YELLOW}rewrite, deflate, expires, headers${RESET}"
else
    echo -e "${RED}❌ Gagal me-restart Apache2. Periksa konfigurasi Anda.${RESET}"
    echo -e "${YELLOW}Gunakan perintah:${RESET} journalctl -xeu apache2.service"
    exit 1
fi

a2enmod proxy_fcgi setenvif rewrite
a2enconf php*-fpm
systemctl restart apache2

# ---- Tuning PHP-FPM ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}⚙️  [5/10] Tuning PHP-FPM...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
PHPVER=$(php -v | head -n 1 | cut -d" " -f2 | cut -d"." -f1,2)
PHPCONF="/etc/php/$PHPVER/fpm/php.ini"
sed -i "s/memory_limit = .*/memory_limit = 512M/" $PHPCONF
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" $PHPCONF
sed -i "s/post_max_size = .*/post_max_size = 100M/" $PHPCONF
systemctl restart php$PHPVER-fpm

# ---- Setup Database MariaDB ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}🗄️  [6/10] Setup Database MariaDB...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---- Tuning MariaDB Otomatis ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}🧠 [7/10] Tuning MariaDB otomatis berdasarkan RAM...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
cp $MARIADB_CONF ${MARIADB_CONF}.bak

# Deteksi RAM dalam MB
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

# Tentukan nilai konfigurasi berdasarkan kapasitas RAM
if [ "$TOTAL_RAM" -le 1024 ]; then
    INNODB_BUFFER_POOL_SIZE="128M"
    QUERY_CACHE_SIZE="16M"
    MAX_CONNECTIONS="50"
elif [ "$TOTAL_RAM" -le 2048 ]; then
    INNODB_BUFFER_POOL_SIZE="256M"
    QUERY_CACHE_SIZE="32M"
    MAX_CONNECTIONS="100"
elif [ "$TOTAL_RAM" -le 4096 ]; then
    INNODB_BUFFER_POOL_SIZE="512M"
    QUERY_CACHE_SIZE="64M"
    MAX_CONNECTIONS="200"
else
    INNODB_BUFFER_POOL_SIZE="1G"
    QUERY_CACHE_SIZE="128M"
    MAX_CONNECTIONS="400"
fi

# Backup konfigurasi MariaDB lama
MARIADB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
cp $MARIADB_CONF ${MARIADB_CONF}.bak

# Terapkan tuning otomatis
sed -i "s/^innodb_buffer_pool_size.*/innodb_buffer_pool_size = $INNODB_BUFFER_POOL_SIZE/" $MARIADB_CONF 2>/dev/null || echo "innodb_buffer_pool_size = $INNODB_BUFFER_POOL_SIZE" >> $MARIADB_CONF
sed -i "s/^query_cache_size.*/query_cache_size = $QUERY_CACHE_SIZE/" $MARIADB_CONF 2>/dev/null || echo "query_cache_size = $QUERY_CACHE_SIZE" >> $MARIADB_CONF
sed -i "s/^max_connections.*/max_connections = $MAX_CONNECTIONS/" $MARIADB_CONF 2>/dev/null || echo "max_connections = $MAX_CONNECTIONS" >> $MARIADB_CONF

# Restart MariaDB agar perubahan diterapkan
systemctl restart mariadb

# ✅ Tampilkan hasil tuning
echo -e "${GREEN}✅ Tuning MariaDB selesai berdasarkan spesifikasi sistem${RESET}"
echo -e "${CYAN}-------------------------------------------${RESET}"
echo -e "🧩 Total RAM Terdeteksi : ${YELLOW}${TOTAL_RAM} MB${RESET}"
echo -e "🧩 innodb_buffer_pool_size : ${YELLOW}${INNODB_BUFFER_POOL_SIZE}${RESET}"
echo -e "🧩 query_cache_size        : ${YELLOW}${QUERY_CACHE_SIZE}${RESET}"
echo -e "🧩 max_connections         : ${YELLOW}${MAX_CONNECTIONS}${RESET}"
echo -e "${CYAN}-------------------------------------------${RESET}"

# ---- Download LMS Moodle via GitHub ----
echo -e "${GREEN}==========================================${RESET}"
echo -e "${BLUE}⬇️  [8/10] Download Moodle dari GitHub...${RESET}"
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
echo -e "${BLUE}🌐 [9/10] Konfigurasi VirtualHost...${RESET}"
echo -e "${GREEN}==========================================${RESET}"
WEBROOT="$WEBROOT"
# Pastikan Apache aktif
if ! systemctl is-active --quiet apache2; then
    systemctl start apache2
fi

# Deteksi versi PHP otomatis
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

# File konfigurasi VirtualHost
VHOST_CONF="/etc/apache2/sites-available/moodle.conf"

# Buat konfigurasi VirtualHost dengan PHP-FPM
cat > $VHOST_CONF <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${SERVER_IP}
    DocumentRoot ${WEBROOT}

    <Directory ${WEBROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/moodle_error.log
    CustomLog \${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
EOF

# Nonaktifkan default site & aktifkan Moodle
a2dissite 000-default.conf >/dev/null 2>&1
a2ensite moodle.conf >/dev/null 2>&1

# Aktifkan modul yang dibutuhkan Moodle
a2enmod proxy_fcgi setenvif >/dev/null 2>&1
a2enmod rewrite >/dev/null 2>&1
a2enconf php${PHP_VERSION}-fpm >/dev/null 2>&1

# Restart PHP-FPM & reload Apache
systemctl restart php${PHP_VERSION}-fpm
systemctl reload apache2 || systemctl restart apache2

# Verifikasi status Apache & PHP-FPM
if systemctl is-active --quiet apache2 && systemctl is-active --quiet php${PHP_VERSION}-fpm; then
    echo -e "${GREEN}✅ Konfigurasi VirtualHost Moodle dengan PHP-FPM berhasil diterapkan.${RESET}"
else
    echo -e "${RED}❌ Gagal memuat Apache2 atau PHP-FPM.${RESET}"
    echo -e "   Gunakan perintah: ${YELLOW}systemctl status apache2 php${PHP_VERSION}-fpm${RESET}"
fi


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
echo -e "📂 Web Root      : ${YELLOW}$WEBROOT${RESET}"
echo -e "⚙️  VirtualHost  : ${YELLOW}$VHOST_CONF${RESET}"
echo -e "🧩 PHP-FPM Sock  : ${YELLOW}/run/php/php${PHP_VERSION}-fpm.sock${RESET}"
echo -e "🪵 Error Log     : ${YELLOW}/var/log/apache2/moodle_error.log${RESET}"
echo -e "🪵 Access Log    : ${YELLOW}/var/log/apache2/moodle_access.log${RESET}"

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
