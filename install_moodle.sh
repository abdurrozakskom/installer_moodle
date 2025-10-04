#!/usr/bin/env bash
# Auto installer: Moodle on LAMP (Ubuntu Server)
# Author: Generated for Abdur Rozak, SMKS YASMIDA Ambarawa
# Purpose: otomatis install & konfigurasi Moodle (Apache2 + PHP-FPM + MariaDB)
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
# License: MIT
# =========================================================
# ---- Warna ----
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

set -euo pipefail
IFS=$'\n\t'

LOGFILE="/var/log/moodle_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

function banner() {
  cat <<'BANNER'
====================================================
  Moodle LAMP Auto Installer
  - untuk SMKS YASMIDA Ambarawa (by script)
====================================================
BANNER
}

# ---- Pastikan root ----
if [[ "$EUID" -ne 0 ]]; then
  echo "[ERROR] Script harus dijalankan sebagai root. Gunakan: sudo $0"
  exit 1
fi

banner
echo "Logging ke: $LOGFILE"

# ---- Verifikasi Password Sebelum Instalasi ---
read -s -p "Masukkan password root untuk verifikasi (tidak muncul): " ROOTPW
echo
if ! echo "$ROOTPW" | sudo -S -v &>/dev/null; then
  echo "[ERROR] Verifikasi password gagal. Pastikan password benar dan akun Anda punya hak sudo."
  exit 2
fi

# ---- Input User ----
read -p "Nama domain / servername (contoh: moodle.yasmida.sch.id) : " MOODLE_DOMAIN
read -p "Path instalasi web (default: /var/www/moodle) : " WWWROOT
WWWROOT=${WWWROOT:-/var/www/moodle}
read -p "Lokasi moodledata (default: /var/moodledata) : " MOODLEDATA
MOODLEDATA=${MOODLEDATA:-/var/moodledata}
read -p "Nama database Moodle (default: moodle) : " MYSQL_DB
MYSQL_DB=${MYSQL_DB:-moodle}
read -p "Nama DB user (default: moodleuser) : " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-moodleuser}
read -s -p "Password untuk DB user: " MYSQL_PASS
echo
read -p "Email admin Moodle (default: admin@${MOODLE_DOMAIN:-localhost}) : " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${MOODLE_DOMAIN:-localhost}}

echo
echo "Ringkasan konfigurasi:"
echo "  Domain        : $MOODLE_DOMAIN"
echo "  Web root      : $WWWROOT"
echo "  moodledata    : $MOODLEDATA"
echo "  DB name       : $MYSQL_DB"
echo "  DB user       : $MYSQL_USER"
echo "  Admin email   : $ADMIN_EMAIL"
read -p "Lanjutkan instalasi? (y/n) : " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Dibatalkan oleh pengguna."
  exit 0
fi

# ---- Update Sistem ----
echo "[1/11] Update & upgrade paket..."
apt-get update -y && apt-get upgrade -y

# ---- Paket Pendukung ----
echo "[2/11] Install paket pendukung dasar..."
apt-get install -y curl wget unzip git ca-certificates gnupg lsb-release apt-transport-https software-properties-common

# ---- Install LAMP Stack ----
echo "[3/11] Menginstall Apache2, MariaDB, PHP-FPM dan modul PHP yang umum dibutuhkan Moodle..."
apt-get install -y apache2 mariadb-server libapache2-mod-fcgid php-fpm \
    php-cli php-xml php-intl php-mbstring php-zip php-curl php-gd php-xmlrpc php-soap php-mysql php-pear php-json php-bcmath php-opcache

a2enmod proxy_fcgi setenvif rewrite headers ssl expires mime
systemctl restart apache2

# ---- Tuning Apache2 ---
echo "[4/11] Konfigurasi tuning Apache2 (keepalive, timeout, mpm)..."
APACHE_CONF="/etc/apache2/conf-available/moodle-tuning.conf"
cat > "$APACHE_CONF" <<APC
# Moodle tuning (basic)
ServerSignature Off
ServerTokens Prod
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
APC
ln -sf "$APACHE_CONF" /etc/apache2/conf-enabled/moodle-tuning.conf

# ---- Tuning PHP-FPM ----
echo "[5/11] Tuning PHP-FPM (php.ini & pool)..."
PHPINI="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/fpm/php.ini"
if [[ ! -f "$PHPINI" ]]; then
  PHPINI="/etc/php/8.1/fpm/php.ini" || true
fi
if [[ -f "$PHPINI" ]]; then
  sed -i "s/^;\?upload_max_filesize = .*/upload_max_filesize = 100M/" "$PHPINI"
  sed -i "s/^;\?post_max_size = .*/post_max_size = 100M/" "$PHPINI"
  sed -i "s/^;\?max_execution_time = .*/max_execution_time = 300/" "$PHPINI"
  sed -i "s/^;\?memory_limit = .*/memory_limit = 512M/" "$PHPINI"
fi

PHP_POOL="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/fpm/pool.d/www.conf"
if [[ ! -f "$PHP_POOL" ]]; then
  PHP_POOL="/etc/php/8.1/fpm/pool.d/www.conf" || true
fi
if [[ -f "$PHP_POOL" ]]; then
  sed -i "s/^pm = .*/pm = dynamic/" "$PHP_POOL" || true
  sed -i "s/^pm.max_children = .*/pm.max_children = 50/" "$PHP_POOL" || true
  sed -i "s/^pm.start_servers = .*/pm.start_servers = 5/" "$PHP_POOL" || true
  sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/" "$PHP_POOL" || true
  sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = 35/" "$PHP_POOL" || true
fi
systemctl restart php*-fpm || true

# ---- Setup Database MariaDB ----
echo "[6/11] Mengamankan MariaDB & membuat database Moodle..."
mysql -e "CREATE DATABASE IF NOT EXISTS \\`$MYSQL_DB\\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON \\`$MYSQL_DB\\`.* TO '$MYSQL_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---- Tuning MariaDB Otomatis ----
echo "[7/11] Tuning MariaDB otomatis berdasarkan RAM..."

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


# ---- Download LMS Moodle dari GitHub ----
echo "[8/11] Clone Moodle dari GitHub ke $WWWROOT ..."
rm -rf "$WWWROOT"
mkdir -p "$WWWROOT"

if [ ! -d "/tmp/moodle" ]; then
  git clone https://github.com/moodle/moodle.git /tmp/moodle
else
  cd /tmp/moodle && git pull origin master
fi

rsync -a /tmp/moodle/ "$WWWROOT/"
chown -R www-data:www-data "$WWWROOT"
chmod -R 0755 "$WWWROOT"

mkdir -p "$MOODLEDATA"
chown -R www-data:www-data "$MOODLEDATA"
chmod 0770 "$MOODLEDATA"

# ---- VirtualHost ----
echo "[9/11] Membuat VirtualHost Apache untuk $MOODLE_DOMAIN ..."
APACHE_VHOST="/etc/apache2/sites-available/${MOODLE_DOMAIN}.conf"
cat > "$APACHE_VHOST" <<VHOST
<VirtualHost *:80>
    ServerName ${MOODLE_DOMAIN}
    DocumentRoot ${WWWROOT}

    <Directory ${WWWROOT}>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/${MOODLE_DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${MOODLE_DOMAIN}_access.log combined
</VirtualHost>
VHOST

a2ensite "${MOODLE_DOMAIN}.conf" || true
systemctl reload apache2 || true

# ---- Cron for Moodle ----
echo "[10/11] Menambahkan cron job untuk Moodle (cron.php)"
CRONLINE="*/1 * * * * www-data /usr/bin/php ${WWWROOT}/admin/cron.php >/dev/null 2>&1"
if ! crontab -u www-data -l 2>/dev/null | grep -F "${WWWROOT}/admin/cron.php" >/dev/null; then
  ( crontab -u www-data -l 2>/dev/null; echo "$CRONLINE" ) | crontab -u www-data -
fi

# ---- Summary ----
echo "[11/11] Selesai — ringkasan tindakan:"
echo "  - Web root      : $WWWROOT"
echo "  - moodledata    : $MOODLEDATA"
echo "  - Database      : $MYSQL_DB (user: $MYSQL_USER)"
echo "  - Apache vhost  : /etc/apache2/sites-available/${MOODLE_DOMAIN}.conf"
echo "  - Cron          : sudah ditambahkan untuk www-data (cron.php setiap menit)"
echo
echo "Silakan buka: http://$MOODLE_DOMAIN untuk melanjutkan instalasi lewat web (setup GUI Moodle)."
echo "Log lengkap: $LOGFILE"

echo "Catatan penting:"
echo " - Pastikan DNS mengarah ke server ini atau tambahkan /etc/hosts di mesin client untuk pengujian."
echo " - Jika ingin HTTPS, aktifkan certbot/letsencrypt setelah verifikasi domain."

echo "Terima kasih — skrip ini membuat lingkungan dasar. Sesuaikan pengaturan php & mysql untuk performa produksi."
echo ""
echo -e "${GREEN}==========================================${RESET}"
# ---- Credit Author ----
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
exit 0
