#!/bin/bash

# ==============================================================================
# recon-auto.sh
#
# Skrip otomatisasi recon untuk enumerasi subdomain dan pengecekan host live.
# Dibuat untuk proyek recon-automation-lief.
#
# Tools yang Dibutuhkan: subfinder, anew, httpx
# ==============================================================================

# --- 1. Konfigurasi Path dan Setup ---

# Menentukan direktori root project berdasarkan lokasi skrip
# Ini membuat skrip dapat dijalankan dari mana saja
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)

# Tentukan semua path file dan direktori
INPUT_FILE="$PROJECT_ROOT/input/domains.txt"
OUTPUT_SUBDOMAINS="$PROJECT_ROOT/output/all-subdomains.txt"
OUTPUT_LIVE="$PROJECT_ROOT/output/live.txt"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/progress.log"
ERROR_LOG="$LOG_DIR/errors.log"

# Buat direktori dan file yang diperlukan jika belum ada
mkdir -p "$PROJECT_ROOT/input" "$PROJECT_ROOT/output" "$LOG_DIR"
touch "$INPUT_FILE" "$OUTPUT_SUBDOMAINS" "$OUTPUT_LIVE" "$LOG_FILE" "$ERROR_LOG"

# --- 2. Fungsi Logging ---

# Fungsi ini akan mencatat pesan ke stdout (layar) DAN ke file progress.log
# Ini memenuhi persyaratan untuk menggunakan tee dengan timestamp.
log() {
    local MESSAGE="[$(date +'%Y-%m-%d %H:%M:%S')] - $1"
    # Menggunakan tee -a untuk menambahkan log ke file tanpa menimpa
    echo -e "$MESSAGE" | tee -a "$LOG_FILE"
}

# --- 3. Setup Awal dan Pengecekan Dependensi ---

log "===== Skrip Recon Otomatis Dimulai ====="

# Cek dependensi (tools yang dibutuhkan)
log "Mengecek dependensi (subfinder, anew, httpx)..."
for tool in subfinder anew httpx; do
    if ! command -v "$tool" &> /dev/null; then
        # === PERBAIKAN: Menghapus 'local' dari baris ini ===
        ERROR_MSG="FATAL: Alat '$tool' tidak ditemukan. Silakan install."
        log "$ERROR_MSG"
        # Catat error fatal ini juga di errors.log
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $ERROR_MSG" >> "$ERROR_LOG"
        exit 1
    fi
done
log "Semua dependensi ditemukan."

# Cek apakah file input ada dan tidak kosong
if [ ! -s "$INPUT_FILE" ]; then
    # === PERBAIKAN: Menghapus 'local' dari baris ini ===
    ERROR_MSG="FATAL: File input '$INPUT_FILE' tidak ada atau kosong."
    log "$ERROR_MSG"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $ERROR_MSG" >> "$ERROR_LOG"
    exit 1
fi

# Mengatur 'pipefail'
# Ini memastikan bahwa jika ada perintah dalam pipeline (misal: subfinder) gagal,
# seluruh pipeline akan mengembalikan kode error.
set -o pipefail

# --- 4. Proses Enumerasi Subdomain ---

log "Memulai enumerasi subdomain dari $INPUT_FILE..."

while IFS= read -r domain || [[ -n "$domain" ]]; do
    if [[ -n "$domain" ]]; then
        log "Memproses domain: $domain"
        
        # Menjalankan subfinder dan mengalirkannya ke anew
        # 1. subfinder -d "$domain" -silent: Menjalankan subfinder.
        # 2. 2>> "$ERROR_LOG": Mengirim semua pesan error (stderr) dari subfinder ke errors.log.
        # 3. |: Mengalirkan hasil (stdout) subfinder ke perintah berikutnya.
        # 4. anew "$OUTPUT_SUBDOMAINS": Menerima stdin, membandingkan dengan file,
        #    menambahkan baris baru ke file, dan mencetak baris baru tersebut ke stdout.
        # 5. 2>> "$ERROR_LOG": Mengirim error dari anew ke errors.log.
        
        subfinder -d "$domain" -silent 2>> "$ERROR_LOG" | anew "$OUTPUT_SUBDOMAINS" 2>> "$ERROR_LOG"
        
        # Memeriksa exit code dari subfinder (perintah pertama di pipeline)
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            log "PERINGATAN: Subfinder mungkin gagal untuk domain '$domain'. Cek '$ERROR_LOG'."
        fi
    fi
done < "$INPUT_FILE"

log "Enumerasi subdomain selesai."

# --- 5. Proses Pengecekan Live Host ---

log "Memulai pengecekan live host (httpx)..."

# Cek dulu jika file subdomain kosong
if [ ! -s "$OUTPUT_SUBDOMAINS" ]; then
    log "Tidak ada subdomain yang ditemukan di $OUTPUT_SUBDOMAINS. Melewatkan pengecekan live host."
else
    # Menjalankan httpx
    # -l: Baca daftar host dari file
    # -silent: Hanya tampilkan hasil (URL yang hidup)
    # -o: Simpan output ke file
    # 2>> "$ERROR_LOG": Kirim error ke errors.log
    httpx -l "$OUTPUT_SUBDOMAINS" -silent -o "$OUTPUT_LIVE" 2>> "$ERROR_LOG"
    
    if [ $? -ne 0 ]; then
        log "PERINGATAN: httpx mungkin mengalami error saat berjalan. Cek '$ERROR_LOG'."
    fi
    log "Pengecekan live host selesai. Hasil disimpan di $OUTPUT_LIVE."
fi

# Matikan pipefail
set +o pipefail

# --- 6. Laporan Akhir ---

log "===== Laporan Hasil Recon ====="

# Hitung jumlah baris di file output
# Menggunakan wc -l < "file" adalah cara aman untuk mendapatkan jumlah baris
subdomain_count=0
if [ -f "$OUTPUT_SUBDOMAINS" ]; then
    subdomain_count=$(wc -l < "$OUTPUT_SUBDOMAINS")
fi

live_host_count=0
if [ -f "$OUTPUT_LIVE" ]; then
    live_host_count=$(wc -l < "$OUTPUT_LIVE")
fi

log "Total subdomain unik ditemukan: ${subdomain_count}"
log "Total host live ditemukan     : ${live_host_count}"
log "===== Skrip Recon Otomatis Selesai ====="
