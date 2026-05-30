#!/bin/bash
set -e

# backup.sh - Backup hasil build ke ZIP
# Output: osboot/farewell_backup_[DDMMYYYY-HHMMSS].zip

WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OSBOOT="$WORKDIR/osboot"

# 1. Validasi file yang akan di-backup
echo "[*] Mengecek file yang akan di-backup..."

MISSING=0
for f in bzImage single.gz multi.gz farewell.iso; do
    if [ ! -f "$OSBOOT/$f" ]; then
        echo "[!] WARNING: osboot/$f tidak ditemukan, akan dilewati."
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -eq 4 ]; then
    echo "[!] ERROR: Tidak ada file yang bisa di-backup."
    exit 1
fi

# 2. Tentukan nama file ZIP dengan timestamp
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
ZIPNAME="farewell_backup_${TIMESTAMP}.zip"
ZIPPATH="$OSBOOT/$ZIPNAME"

# 3. Buat ZIP dari file yang ada
echo "[*] Membuat $ZIPNAME..."

FILES_TO_ZIP=""
for f in bzImage single.gz multi.gz farewell.iso; do
    [ -f "$OSBOOT/$f" ] && FILES_TO_ZIP="$FILES_TO_ZIP $f"
done

cd "$OSBOOT"
zip "$ZIPPATH" $FILES_TO_ZIP

# 4. Hapus file asli yang sudah diarsip
echo "[*] Menghapus file yang sudah diarsip..."
for f in bzImage single.gz multi.gz farewell.iso; do
    if [ -f "$OSBOOT/$f" ]; then
        rm "$OSBOOT/$f"
        echo "    [-] Dihapus: osboot/$f"
    fi
done

echo ""
echo "[✓] Backup selesai: osboot/$ZIPNAME"
echo "[i] Untuk restore: cd osboot && unzip $ZIPNAME"
