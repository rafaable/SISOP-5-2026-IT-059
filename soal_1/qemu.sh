#!/bin/bash
set -e

WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OSBOOT="$WORKDIR/osboot"

case "$1" in
    --single)
        [ -f "$OSBOOT/bzImage"   ] || { echo "[!] ERROR: osboot/bzImage tidak ditemukan."; exit 1; }
        [ -f "$OSBOOT/single.gz" ] || { echo "[!] ERROR: osboot/single.gz tidak ditemukan. Jalankan single.sh dulu."; exit 1; }
        echo "[*] Booting Single-User Mode..."
        qemu-system-x86_64 \
            -smp 2 \
            -m 512 \
            -display curses \
            -vga std \
            -kernel "$OSBOOT/bzImage" \
            -initrd "$OSBOOT/single.gz" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;

    --multi)
        [ -f "$OSBOOT/bzImage"  ] || { echo "[!] ERROR: osboot/bzImage tidak ditemukan."; exit 1; }
        [ -f "$OSBOOT/multi.gz" ] || { echo "[!] ERROR: osboot/multi.gz tidak ditemukan. Jalankan multi.sh dulu."; exit 1; }
        echo "[*] Booting Multi-User Mode..."
        qemu-system-x86_64 \
            -smp 2 \
            -m 512 \
            -display curses \
            -vga std \
            -kernel "$OSBOOT/bzImage" \
            -initrd "$OSBOOT/multi.gz" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;

    --all)
        [ -f "$OSBOOT/farewell.iso" ] || { echo "[!] ERROR: osboot/farewell.iso tidak ditemukan. Jalankan iso.sh dulu."; exit 1; }
        echo "[*] Booting dari ISO (menu GRUB akan muncul)..."
        echo "[i] Pilih:"
        echo "    [0] FarewellOS - Single User Mode"
        echo "    [1] FarewellOS - Multi User Mode"
        echo ""
        qemu-system-x86_64 \
            -smp 2 \
            -m 512 \
            -display curses \
            -vga std \
            -cdrom "$OSBOOT/farewell.iso" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;

    *)
        echo "Usage: ./qemu.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  --single   Boot langsung ke single-user filesystem"
        echo "  --multi    Boot langsung ke multi-user filesystem"
        echo "  --all      Boot dari ISO dengan pilihan menu GRUB"
        exit 1
        ;;
esac
