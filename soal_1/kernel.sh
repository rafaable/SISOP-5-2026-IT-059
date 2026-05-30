#!/bin/bash

set -e

KERNEL_VERSION="6.1.1"
KERNEL_ARCHIVE="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_DIR="linux-${KERNEL_VERSION}"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
OSBOOT_DIR="${BASE_DIR}/osboot"

mkdir -p "${OSBOOT_DIR}"

cd "${BASE_DIR}"

echo "[*] Checking kernel source..."

if [ ! -f "${KERNEL_ARCHIVE}" ];
  then
  echo "[*] Downloading Linux ${KERNEL_VERSION}..."
  wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_ARCHIVE}"
fi

if [ ! -d "${KERNEL_DIR}" ]; then
echo "[*] Extracting source..."
tar -xf "${KERNEL_ARCHIVE}"
fi

cd "${KERNEL_DIR}"

echo "[*] Applying kernel config..."

if [ ! -f "${BASE_DIR}/.config" ]; then
echo "[ERROR] .config not found in ${BASE_DIR}"
exit 1
fi

cp "${BASE_DIR}/.config" .config

make olddefconfig

echo "[*] Building kernel..."
make -j"$(nproc)"

echo "[*] Copying bzImage..."

cp arch/x86/boot/bzImage "${OSBOOT_DIR}/bzImage"

echo "[+] Done"
echo "[+] Output: ${OSBOOT_DIR}/bzImage"
