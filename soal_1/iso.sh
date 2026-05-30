#!/bin/bash
set -e

# ============================================================
# iso.sh - Buat bootable ISO → osboot/farewell.iso
#          dengan pilihan single-user dan multi-user di GRUB
# ============================================================

WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OSBOOT="$WORKDIR/osboot"
ISODIR="$OSBOOT/mylinuxiso"
OUTPUT="$OSBOOT/farewell.iso"

# ------------------------------------------------------------
# 0. Validasi file yang dibutuhkan
# ------------------------------------------------------------
echo "[*] Mengecek file yang dibutuhkan..."

[ -f "$OSBOOT/bzImage" ]    || { echo "[!] ERROR: osboot/bzImage tidak ditemukan. Jalankan kernel.sh dulu."; exit 1; }
[ -f "$OSBOOT/single.gz" ]  || { echo "[!] ERROR: osboot/single.gz tidak ditemukan. Jalankan single.sh dulu."; exit 1; }
[ -f "$OSBOOT/multi.gz" ]   || { echo "[!] ERROR: osboot/multi.gz tidak ditemukan. Jalankan multi.sh dulu."; exit 1; }

# ------------------------------------------------------------
# 1. Cleanup direktori ISO sebelumnya
# ------------------------------------------------------------
echo "[*] Membersihkan build sebelumnya..."
rm -rf "$ISODIR"
rm -f  "$OUTPUT"

# ------------------------------------------------------------
# 2. Buat struktur direktori ISO
# ------------------------------------------------------------
echo "[*] Membuat struktur direktori ISO..."
mkdir -p "$ISODIR/boot/grub"

# ------------------------------------------------------------
# 3. Salin kernel dan kedua filesystem
# ------------------------------------------------------------
echo "[*] Menyalin kernel dan filesystem..."
cp "$OSBOOT/bzImage"   "$ISODIR/boot/bzImage"
cp "$OSBOOT/single.gz" "$ISODIR/boot/single.gz"
cp "$OSBOOT/multi.gz"  "$ISODIR/boot/multi.gz"

# ------------------------------------------------------------
# 4. Buat grub.cfg dengan dua menu entry
# ------------------------------------------------------------
echo "[*] Membuat konfigurasi GRUB..."
cat > "$ISODIR/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "FarewellOS - Single User Mode" {
    linux  /boot/bzImage
    initrd /boot/single.gz
}

menuentry "FarewellOS - Multi User Mode" {
    linux  /boot/bzImage
    initrd /boot/multi.gz
}
EOF

# ------------------------------------------------------------
# 5. Buat ISO bootable dengan grub-mkrescue
# ------------------------------------------------------------
echo "[*] Membuat ISO bootable..."
grub-mkrescue -o "$OUTPUT" "$ISODIR" 2>/dev/null

# ------------------------------------------------------------
# 6. Cleanup direktori ISO sementara
# ------------------------------------------------------------
echo "[*] Membersihkan direktori build..."
rm -rf "$ISODIR"

echo ""
echo "[✓] Selesai! Output: $OUTPUT"
echo "[i] Jalankan dengan: bash qemu.sh"
