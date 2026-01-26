# Setup Cepat Backend Kinerja Tinggi Nextcloud (HPB) + Coturn + Collabora

Navigasi: [Deutsch](README.md) | [English](README_en.md) | Bahasa Indonesia

Skrip ini menyiapkan backend Nextcloud Talk (HPB), Coturn, dan Collabora di Debian (>=11) secara interaktif atau unattended.

## Opsi instalasi (dalam dialog)
- Collabora (dengan nginx/certbot/ufw).
- HPB signaling (janus, nats, nextcloud-spreed-signaling) + nginx/certbot/ufw (butuh info TURN eksternal: FQDN/port/secret).
- Coturn + certbot + ufw + unattended-upgrades (tanpa nginx; port 443 bisa dipakai TURN).
- HPB signaling + Coturn (stack lengkap dengan nginx/certbot/ufw).

## Fitur penting
- Prompt port TURN (default 5349, bisa 443; jika 443 pastikan tidak bentrok dengan nginx dan butuh CAP_NET_BIND_SERVICE).
- Secret TURN bisa digenerate otomatis saat instal Coturn dan disimpan di file secrets.
- Ringkasan konfigurasi (TURN/STUN, endpoint HPB, secret per domain) dicetak di akhir dan ditulis ke file secrets.
- UFW menyesuaikan port Coturn, dan membuka port 80 untuk HTTP-01 jika certbot dipasang tanpa nginx.
- Konfigurasi signaling dibuat di: `/etc/signaling/server.conf`.
- `internalsecret` dibuat otomatis dan disimpan di file secrets.
- Halaman status runtime: `/hpb-status.json` (dibatasi IP).

## Persyaratan
- Debian 11+ dengan IP publik dan DNS FQDN untuk tiap layanan (Nextcloud, HPB, Coturn).
- Akses root (sudo).
- Port 80/443 bebas untuk certbot/nginx kecuali Anda memilih mode Coturn-only tanpa nginx.

## Cara pakai singkat
1. Jalankan sebagai root: `./setup-nextcloud-hpb.sh` (atau `./setup-nextcloud-hpb.sh settings.sh` untuk unattended).
2. Pilih layanan di checklist sesuai peran host (Coturn dulu jika ingin secret dibagikan, lalu HPB).
3. Masukkan FQDN, email (opsional untuk certbot), port TURN, dan secret TURN (jika tidak auto).
4. Setelah selesai, buka file secrets (path dicetak di output) lalu masukkan nilai-nilainya ke Nextcloud Admin → Talk (STUN/TURN dan HPB).

## Pengaturan penting (settings.sh)
- `SECRETS_FILE_PATH`: default `/opt/fajarlabs/nextcloud-hpb.secrets`.
- `EMAIL_USER_ADDRESS`: email opsional untuk registrasi Certbot (tanpa SMTP).
- `SIGNALING_MAX_STREAM_BITRATE` / `SIGNALING_MAX_SCREEN_BITRATE`: batasi bitrate (bps) untuk koneksi buruk.
- `SIGNALING_INTERNAL_SECRET`: kosongkan agar auto-generate.
- `HPB_STATUS_ALLOWED_IPS`: allowlist IP untuk `/hpb-status.json` (pisahkan dengan koma).
- `USE_CLOUDFLARE_PROXY`: set `true` jika Nginx berada di belakang proxy Cloudflare (orange cloud).

## Lisensi
GPL-2.0. Lihat berkas `LICENSE`.

## Kredit
- Modifikasi opsi instalasi, prompt port Coturn, penyesuaian firewall: **Fajar Budi Setiawan**.
