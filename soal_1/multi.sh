#!/bin/bash
set -e

# multi.sh - Build multi-user initramfs → osboot/multi.gz
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
RAMDISK="$WORKDIR/osboot/myramdisk"
OUTPUT="$WORKDIR/osboot/multi.gz"

# 0. Cleanup hasil build sebelumnya
echo "[*] Membersihkan build sebelumnya..."
sudo rm -rf "$RAMDISK"

# 1. Buat struktur direktori
echo "[*] Membuat struktur direktori..."
sudo mkdir -p "$RAMDISK"/{bin,dev,proc,sys,etc,tmp,root,var/log,var/cache/apk,lib/apk/db,usr/bin,usr/lib}
sudo mkdir -p "$RAMDISK"/home/{henn,hann,viii,kids}

# 2. Salin device files
echo "[*] Menyalin device files..."
sudo cp -a /dev/null    "$RAMDISK/dev/"
sudo cp -a /dev/tty*    "$RAMDISK/dev/"
sudo cp -a /dev/zero    "$RAMDISK/dev/"
sudo cp -a /dev/console "$RAMDISK/dev/"

# 3. Salin dan install BusyBox
echo "[*] Menginstal BusyBox..."
sudo cp /usr/bin/busybox "$RAMDISK/bin/"
sudo chroot "$RAMDISK" /bin/busybox --install /bin

# 4. Generate password hash (MD5/apr1)
#    BusyBox static login hanya support MD5 ($1$/$apr1$)
#    SHA-512 ($6$) tidak dikenali → password selalu gagal
echo "[*] Membuat password hash (MD5)..."
HASH_ROOT=$(openssl passwd -6 "root123")
HASH_HENN=$(openssl passwd -6 "henn123")
HASH_HANN=$(openssl passwd -6 "hann123")
HASH_VIII=$(openssl passwd -6 "viii123")
HASH_KIDS=$(openssl passwd -6 "kids123")

# 5. Buat /etc/passwd (hash langsung di sini, tidak pakai shadow)
echo "[*] Membuat /etc/passwd..."
sudo tee "$RAMDISK/etc/passwd" > /dev/null <<EOF
root:${HASH_ROOT}:0:0:root:/root:/bin/sh
henn:${HASH_HENN}:1001:1001:henn:/home/henn:/bin/sh
hann:${HASH_HANN}:1002:1002:hann:/home/hann:/bin/sh
viii:${HASH_VIII}:1003:1003:viii:/home/viii:/bin/sh
kids:${HASH_KIDS}:1004:1004:kids:/home/kids:/bin/sh
guest:x:9999:9999:guest:/tmp:/bin/sh
EOF
sudo chmod 644 "$RAMDISK/etc/passwd"

# 6. Buat /etc/group (hanya grup primer, no supplementary)
#    Karena setgroups tidak tersedia di kernel minimal,
#    supplementary groups tidak bisa dipakai untuk permission.
#    Hierarki akses diimplementasikan via UID/GID + mode bits.
echo "[*] Membuat /etc/group..."
sudo tee "$RAMDISK/etc/group" > /dev/null <<EOF
root:x:0:
tty:x:5:
henn:x:1001:
hann:x:1002:
viii:x:1003:
kids:x:1004:
guest:x:9999:
EOF

# 7. Atur ownership dan permission direktori
#    gunakan GID primer user sebagai "level" hierarki.
#    Hierarki akses (GID-based):
#      /root      → root:root  700  → hanya root (uid=0)
#      /home/henn → henn:henn  700  → hanya henn (uid=1001)
#      /home/hann → hann:hann  775  → owner rwx, group rwx, others r-x
#                                     henn tidak punya GID hann, tapi
#                                     karena henn UID≠owner & bukan group
#                                     → henn masuk bucket "others" → r-x saja
echo "[*] Mengatur permission direktori..."

sudo chown 0:0        "$RAMDISK/root"
sudo chmod 700        "$RAMDISK/root"

sudo chown 1001:1001  "$RAMDISK/home/henn"
sudo chmod 700        "$RAMDISK/home/henn"

sudo chown 1002:1002  "$RAMDISK/home/hann"
sudo chmod 777        "$RAMDISK/home/hann"

sudo chown 1003:1003  "$RAMDISK/home/viii"
sudo chmod 777        "$RAMDISK/home/viii"

sudo chown 1004:1004  "$RAMDISK/home/kids"
sudo chmod 777        "$RAMDISK/home/kids"

sudo chown 0:0        "$RAMDISK/tmp"
sudo chmod 1777       "$RAMDISK/tmp"

sudo chmod 777 "$RAMDISK/var/log"
sudo chmod 777 "$RAMDISK/var/cache/apk"
sudo chmod 777 "$RAMDISK/lib/apk/db"

sudo chmod 755 "$RAMDISK/bin" "$RAMDISK/dev" "$RAMDISK/proc" \
               "$RAMDISK/sys" "$RAMDISK/etc"

# 8. Buat /etc/profile → login banner
echo "[*] Membuat /etc/profile..."
sudo tee "$RAMDISK/etc/profile" > /dev/null <<'EOF'
echo '$$$$$$$$\                                                   $$\ $$\ '
echo '$$  _____|                                                  $$ |$$ |'
echo '$$ |   $$$$$$\   $$$$$$\   $$$$$$\  $$\  $$\  $$\  $$$$$$\  $$ |$$ |'
echo '$$$$$$\\____$$\ $$  __$$\ $$  __$$\ $$ | $$ | $$ |$$  __$$\ $$ |$$ |'
echo '$$  __|$$$$$$$ |$$ |  \__|$$$$$$$$ |$$ | $$ | $$ |$$$$$$$$ |$$ |$$ |'
echo '$$ |  $$  __$$ |$$ |      $$   ____|$$ | $$ | $$ |$$   ____|$$ |$$ |'
echo '$$ |  \$$$$$$$ |$$ |      \$$$$$$$\ \$$$$$\$$$$  |\$$$$$$$\ $$ |$$ |'
echo '\__|   \_______|\__|       \_______| \_____\____/  \_______|\__|\__|'
echo ''
echo ''
echo ''
echo '            $$$$$$$\                      $$\                       '
echo '            $$  __$$\                     $$ |                      '
echo '            $$ |  $$ |$$$$$$\   $$$$$$\ $$$$$$\   $$\   $$\         '
echo '            $$$$$$$  |\____$$\ $$  __$$\\_$$  _|  $$ |  $$ |        '
echo '            $$  ____/ $$$$$$$ |$$ |  \__| $$ |    $$ |  $$ |        '
echo '            $$ |     $$  __$$ |$$ |       $$ |$$\ $$ |  $$ |        '
echo '            $$ |     \$$$$$$$ |$$ |       \$$$$  |\$$$$$$$ |        '
echo '            \__|      \_______|\__|        \____/  \____$$ |        '
echo '                                                  $$\   $$ |        '
echo '                                                  \$$$$$$  |        '
echo '                                                   \______/         '
echo ''
echo "Welcome $(whoami)"
EOF
sudo chmod 644 "$RAMDISK/etc/profile"

# 9. Buat /etc/passwords (plaintext, root-only, untuk verifikasi manual)
echo "[*] Membuat /etc/passwords..."
sudo tee "$RAMDISK/etc/passwords" > /dev/null <<'EOF'
root:root123
henn:henn123
hann:hann123
viii:viii123
kids:kids123
EOF
sudo chmod 600 "$RAMDISK/etc/passwords"
sudo chown 0:0 "$RAMDISK/etc/passwords"

# 10. Buat /etc/shells
sudo tee "$RAMDISK/etc/shells" > /dev/null <<'EOF'
/bin/sh
/bin/ash
EOF

# 11. Buat /init
echo "[*] Membuat /init..."
sudo tee "$RAMDISK/init" > /dev/null <<'EOF'
#!/bin/sh

/bin/mount -t proc  none /proc
/bin/mount -t sysfs none /sys
/bin/mount -t devtmpfs devtmpfs /dev 2>/dev/null || true

/bin/chmod 1777 /tmp

# Setup network
/bin/ip link set eth0 up 2>/dev/null || true
/bin/ip addr add 10.0.2.15/24 dev eth0 2>/dev/null || true
/bin/ip route add default via 10.0.2.2 2>/dev/null || true
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Init apk database
touch /etc/apk/world
touch /lib/apk/db/installed

while true; do
    /bin/getty -n -l /bin/mylogin -L tty1 115200 vt100
sleep 1
done
EOF
sudo chmod +x "$RAMDISK/init"

# 12. Buat /bin/mylogin — wrapper login dengan whitelist user
#     Jika username tidak ada di whitelist, langsung tolak
#     tanpa minta password. Jika ada, serahkan ke /bin/login.
echo "[*] Membuat /bin/mylogin..."
sudo tee "$RAMDISK/bin/mylogin" > /dev/null <<'EOF'
#!/bin/sh

VALID_USERS="root henn hann viii kids"

printf "Login: "
read USERNAME

IS_VALID=0
for u in $VALID_USERS; do
    if [ "$USERNAME" = "$u" ]; then
        IS_VALID=1
        break
    fi
done

if [ "$IS_VALID" = "1" ]; then
    # Minta password (stty -echo agar tidak tampil di layar)
    printf "Password: "
    stty -echo 2>/dev/null
    read PASSWORD
    stty echo 2>/dev/null
    printf "\n"

    # Ambil password yang benar dari /etc/passwords (root-only file)
    STORED_PASS=$(grep "^${USERNAME}:" /etc/passwords | cut -d: -f2)

    if [ "$PASSWORD" = "$STORED_PASS" ]; then
        exec /bin/su -l "$USERNAME"
    else
        echo "Login incorrect"
        sleep 1
        exec /bin/mylogin
    fi
else
    # User tidak terdaftar: langsung masuk sebagai guest
    exec /bin/su -l guest
fi
EOF
sudo chmod +x "$RAMDISK/bin/mylogin"

# 13. Install Party package manager (apk.static dari Alpine)
echo "[*] Menginstal Party package manager..."

APK_STATIC="/tmp/apk-v2/sbin/apk.static"
if [ ! -f "$APK_STATIC" ]; then
    echo "[*] Mendownload apk-static v2..."
    mkdir -p /tmp/apk-v2
    wget -q https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/apk-tools-static-2.14.4-r0.apk \
        -O /tmp/apk-v2/apk.tar.gz
    cd /tmp/apk-v2
    tar -xzf apk.tar.gz 2>/dev/null || true
    cd "$RAMDISK"
fi

# Copy apk.static sebagai /bin/Party
sudo cp "$APK_STATIC" "$RAMDISK/bin/Party"
sudo chmod +x "$RAMDISK/bin/Party"

# Setup direktori apk
sudo mkdir -p "$RAMDISK/etc/apk"
sudo touch "$RAMDISK/lib/apk/db/installed"
sudo touch "$RAMDISK/etc/apk/world"y

# Setup Alpine repository
sudo tee "$RAMDISK/etc/apk/repositories" > /dev/null <<'REPOEOF'
http://dl-cdn.alpinelinux.org/alpine/v3.18/main
http://dl-cdn.alpinelinux.org/alpine/v3.18/community
REPOEOF

# 14. Copy hello_fuse.c ke initramfs
sudo tee "$RAMDISK/tmp/hello_fuse.c" > /dev/null << 'EOF'
#define FUSE_USE_VERSION 26
#include <fuse.h>
#include <string.h>
#include <errno.h>

static const char *content = "Hello from FUSE!\n";

static int hello_getattr(const char *path, struct stat *st) {
    memset(st, 0, sizeof(struct stat));
    if (strcmp(path, "/") == 0) {
        st->st_mode = S_IFDIR | 0755;
        st->st_nlink = 2;
    } else if (strcmp(path, "/hello.txt") == 0) {
        st->st_mode = S_IFREG | 0444;
        st->st_nlink = 1;
        st->st_size = strlen(content);
    } else {
        return -ENOENT;
    }
    return 0;
}

static int hello_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                         off_t offset, struct fuse_file_info *fi) {
    if (strcmp(path, "/") != 0) return -ENOENT;
    filler(buf, ".", NULL, 0);
    filler(buf, "..", NULL, 0);
    filler(buf, "hello.txt", NULL, 0);
    return 0;
}

static int hello_open(const char *path, struct fuse_file_info *fi) {
    if (strcmp(path, "/hello.txt") != 0) return -ENOENT;
    return 0;
}

static int hello_read(const char *path, char *buf, size_t size,
                      off_t offset, struct fuse_file_info *fi) {
    if (strcmp(path, "/hello.txt") != 0) return -ENOENT;
    size_t len = strlen(content);
    if (offset >= (off_t)len) return 0;
    if (offset + size > len) size = len - offset;
    memcpy(buf, content + offset, size);
    return size;
}

static struct fuse_operations hello_ops = {
    .getattr = hello_getattr,
    .readdir = hello_readdir,
    .open    = hello_open,
    .read    = hello_read,
};

int main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &hello_ops, NULL);
}
EOF

# 15. Buat initramfs → osboot/multi.gz
echo "[*] Membuat initramfs multi.gz..."
mkdir -p "$WORKDIR/osboot"
cd "$RAMDISK"
sudo sh -c "find . | cpio -oHnewc | gzip > '$OUTPUT'"

echo ""
echo "[✓] Selesai! Output: $OUTPUT"
echo "[*] Membersihkan direktori build..."
sudo rm -rf "$RAMDISK"
echo "[✓] Build bersih."
