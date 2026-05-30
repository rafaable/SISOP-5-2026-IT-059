#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
OSBOOT_DIR="${BASE_DIR}/osboot"
WORK_DIR="${BASE_DIR}/singlefs"
mkdir -p "${OSBOOT_DIR}"
echo "[*] Cleaning previous build..."
rm -rf "${WORK_DIR}"
rm -f "${OSBOOT_DIR}/single.gz"
echo "[*] Creating filesystem structure..."
mkdir -p "${WORK_DIR}"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "${WORK_DIR}/etc/apk"
echo "[*] Installing BusyBox..."
BUSYBOX=$(which busybox)
if [ -z "$BUSYBOX" ]; then
    echo "[ERROR] busybox not found"
    exit 1
fi
cp "$BUSYBOX" "${WORK_DIR}/bin/"
cd "${WORK_DIR}/bin"
./busybox --install .
cd "${WORK_DIR}"
echo "[*] Creating passwd..."
cat > etc/passwd << EOF
root::0:0:root:/root:/bin/sh
EOF
echo "[*] Installing Party..."
if [ ! -f "/tmp/apk-v2/sbin/apk.static" ]; then
    mkdir -p /tmp/apk-v2
    wget -q https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/apk-tools-static-2.14.4-r0.apk \
        -O /tmp/apk-v2/apk.tar.gz
    cd /tmp/apk-v2
    tar -xzf apk.tar.gz 2>/dev/null || true
    cd "${WORK_DIR}"
fi
cp /tmp/apk-v2/sbin/apk.static "${WORK_DIR}/bin/Party"
chmod +x "${WORK_DIR}/bin/Party"
echo "[*] Creating hello_fuse.c..."
cat > "${WORK_DIR}/tmp/hello_fuse.c" << 'EOF'
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
echo "[*] Creating init..."
cat > init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Setup network
ip link set eth0 up 2>/dev/null || true
ip addr add 10.0.2.15/24 dev eth0 2>/dev/null || true
ip route add default via 10.0.2.2 2>/dev/null || true
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Setup apk root di /tmp
mkdir -p /tmp/apkroot/etc/apk
mkdir -p /tmp/apkroot/lib/apk/db
mkdir -p /tmp/apkroot/var/cache/apk
mkdir -p /tmp/apkroot/var/log
mkdir -p /tmp/apkroot/usr/bin
mkdir -p /tmp/apkroot/usr/lib
touch /tmp/apkroot/lib/apk/db/installed
touch /tmp/apkroot/etc/apk/world
printf "http://dl-cdn.alpinelinux.org/alpine/v3.18/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.18/community\n" > /tmp/apkroot/etc/apk/repositories

echo ""
echo "=================================="
echo "      Farewell Party OS"
echo "      Single User Mode"
echo "=================================="
echo ""
exec setsid cttyhack /bin/sh
EOF
chmod +x init
echo "[*] Setting permissions..."
chmod 1777 tmp
chmod 700 root
echo "[*] Creating initramfs..."
find . | cpio -o -H newc 2>/dev/null | gzip > "${OSBOOT_DIR}/single.gz"
cd "${BASE_DIR}"
echo "[*] Cleaning temporary files..."
rm -rf "${WORK_DIR}"
echo "[+] Done"
echo "[+] Output: ${OSBOOT_DIR}/single.gz"
