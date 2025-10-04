# 🚀 Auto Installer LMS Moodle on LAMP Stack (Ubuntu Server)
<p align="center"><img src="https://tjkt.smkyasmida.sch.id/wp-content/uploads/2025/02/Logo-TJKT-2022-Sampul-Youtube-1.png" width="600"></p>

---

Script otomatis untuk instalasi dan konfigurasi **LMS Moodle** di atas **LAMP Stack (Linux, Apache2, MariaDB, PHP-FPM)** pada **Ubuntu Server**.  
Dikembangkan oleh **Abdur Rozak (SMKS YASMIDA Ambarawa)**.

---

## ✨ Fitur ScriptBash
- 🔑 **Cek Root** → hanya bisa dijalankan sebagai root (sudo).  
- 📝 **Logging** → seluruh proses tercatat di `/var/log/moodle_installer.log`.  
- 🔐 **Verifikasi Password** sebelum instalasi.  
- 🌐 **Auto Deteksi IP Address Server** → bisa pakai IP otomatis atau input manual.  
- 🔄 **Update & Upgrade sistem**.  
- 📦 **Instalasi paket pendukung** (git, unzip, curl, dsb.).  
- ⚙️ **Instalasi LAMP Stack** (Apache2, MariaDB, PHP-FPM dengan ekstensi Moodle).  
- 🔧 **Tuning Apache2 & PHP-FPM** (memory_limit, upload_max_filesize, dll).  
- 🗄️ **Setup Database & Tunning MariaDB** (DB, user, password).  
- ⬇️ **Download Moodle via GitHub** (selalu update via `git pull`).  
- 🌍 **Konfigurasi VirtualHost berbasis IP Address**.  
- 📋 **Ringkasan instalasi** setelah selesai.

---

## 📋 Persyaratan
- Ubuntu Server 22.04 atau lebih baru.  
- Akses root (sudo).  
- Koneksi internet aktif.  
- Minimal **2 GB RAM** (disarankan 4 GB untuk produksi).  

---

## 👨‍🍼PERSEMBAHAN
```bash
Demi pertemuan dengan-Nya
Demi kerinduan kepada utusan-Nya
Demi bakti kepada orangtua
Demi manfaat kepada sesama
Untuk itulah Sharing Ilmu

Semoga niat ini tetap lurus
Semoga menjadi ibadah
Semoga menjadi amal jariyah
Semoga bermanfaat
Aamiin

Tak lupa Script & Tulisan ini saya persembahkan kepada :
Istri saya tercinta
❤️**Siti Nur Holida**
Dan Anaku tersayang
❤️**Zein Khalisa Arivia**
❤️**Muhammad Zain Al-Fatih**
Aku mencintai kalian sepenuh hati.
```
---

## 💖 Donasi

Jika script ini bermanfaat untuk instalasi eRapor SMK, Anda dapat mendukung pengembang melalui:

- **Saweria** : [https://saweria.co/abdurrozakskom](https://saweria.co/abdurrozakskom)  
- **Trakteer** : [https://trakteer.id/abdurrozakskom/gift](https://trakteer.id/abdurrozakskom/gift)  
- **Paypal**  : [https://paypal.me/abdurrozakskom](https://paypal.me/abdurrozakskom)  

Setiap donasi sangat membantu untuk pengembangan fitur baru dan pemeliharaan script.

---

## 🔧 Cara Menggunakan
1. **Clone repo ini**:
   ```bash
   git clone https://github.com/abdurrozakskom/moodle-installer.git
   cd moodle-installer
    ```
2. **Beri izin eksekusi**:
   ```bash
    chmod +x install_moodle.sh
    chmod +x install_moodle_ip.sh
    ```
3. **Jalankan script**:
   ```bash
    sudo ./install_moodle.sh
    sudo ./install_moodle_ip.sh
    ```
4. **Ikuti prompt**:
    - Konfirmasi password instalasi.
    - Pilih IP otomatis atau masukkan manual.
    - Tentukan direktori webroot.
    - Masukkan nama DB, user DB, dan password DB

5. **Beri izin eksekusi**:
   ```bash
    http://<IP-SERVER>
    ```

---

## 📑 **Catatan Tambahan**
Setelah instalasi, lakukan konfigurasi Moodle via browser.

Untuk keamanan, disarankan menambahkan:

- 🔒 HTTPS (gunakan certbot / Let's Encrypt)
- 🛡️ Firewall (UFW/iptables)
- ⚡ Tuning lebih lanjut MariaDB & PHP sesuai kebutuhan

---

## 👨‍💻 Author

**Abdur Rozak**

**SMKS YASMIDA Ambarawa**

## 🌐 Sosial Media

Ikuti saya di sosial media untuk tips, update, dan info terbaru seputar eRapor SMK:

- **GitHub**    : [https://github.com/abdurrozakskom](https://github.com/abdurrozakskom)  
- **Lynk.id**   : [https://lynk.id/abdurrozak.skom](https://lynk.id/abdurrozak.skom)  
- **Instagram** : [https://instagram.com/abdurrozak.skom](https://instagram.com/abdurrozak.skom)  
- **Facebook**  : [https://facebook.com/abdurrozak.skom](https://facebook.com/abdurrozak.skom)  
- **TikTok**   : [https://tiktok.com/abdurrozak.skom](https://tiktok.com/abdurrozak.skom)  
- **YouTube**   : [https://www.youtube.com/@AbdurRozakSKom](https://www.youtube.com/@AbdurRozakSKom)  

---
---

## 📜 Lisensi
Script ini dirilis dengan lisensi MIT License.
Silakan gunakan, modifikasi, dan distribusikan sesuai kebutuhan.
