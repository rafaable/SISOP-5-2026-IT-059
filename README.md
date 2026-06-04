# Soal 1
## Step pengerjaan
1. Install manual linux 6.1.1 untuk membuat config
2. Copy `.config` ke direktori soal_1
3. Buat kernel.sh dan jalankan
   ```
   nano kernel.sh
   chmod +x kernel.sh
   ```
   Jalankan dengan `./kernel.sh` dan kernel akan membuat bzImage
4. Buat single.sh
   ```
   chmod +x single.sh
   sudo ./single.sh
   ```
6. Masuk ke direktori osboot dan emulate single.bz dengan bzImage
   ```
   qemu-system-x86_64 \
   -smp 2 \
   -m 256 \
   -display curses \
   -vga std \
   -kernel bzImage \
   -initrd single.gz
   ```
7. Kembali ke direktori soal_1
8. Buat multi.sh, running filenya
   ```
   sudo ./multi.sh
   ```
9. Masuk lagi ke osboot
10. Masuk ke direktori osboot dan emulate multi.bz dengan bzImage
   ```
   qemu-system-x86_64 \
   -smp 2 \
   -m 256 \
   -display curses \
   -vga std \
   -kernel bzImage \
   -initrd multi.gz
  ```
  Jika login sebagai hann  
  <img width="760" height="298" alt="image" src="https://github.com/user-attachments/assets/61e8d24b-6df8-48bf-80b1-c0ed9ac13e88" />  
  
11. Buat iso.sh, ulangi seperti pola sebelumnya
    ``` 
    chmod +x iso.sh
    ./iso.sh
    cd osboot
    ```
    Jalankan qemu
    ```
    qemu-system-x86_64 \
    -smp 2 \
    -m 256 \
    -display curses \
    -vga std \
    -cdrom farewell.iso
    ```  
    
12. Buat qemu.sh, ubah izin dan jalankan
    ```
    chmod +x qemu.sh
    ./qemu.sh --[perintah
    ```
    
13. Untuk point soal nomor 8 supaya bisa akses internet, tambahkan setup berikut pada single.sh dan multi.sh pada bagian initnya
    ```
    # Setup network
    /bin/ip link set eth0 up 2>/dev/null || true
    /bin/ip addr add 10.0.2.15/24 dev eth0 2>/dev/null || true
    /bin/ip route add default via 10.0.2.2 2>/dev/null || true
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    ```
    Jalankan di dalam qemu
    ```
    ping -c 4 8.8.8.8
    wget example.com
    ```
    
14. Untuk point nomor 9, OS harus memiliki package manager sendiri yang bisa install sebuah package, binary package manager harus dinamai "Party"
    ```
    Party --allow-untrusted update
    Party --allow-untrusted add nano
    ```
    
15. Untuk point nomor 10 program FUSE  
    Jalankan `./qemu.sh --multi`  
    Lalu login sebagai root dengan password root123, kemudian:
    ```
    shchmod 755 /usr/lib
    chmod 755 /usr/bin
    Party --allow-untrusted update
    Party --allow-untrusted add gcc musl-dev fuse-dev
    ```
    Jalankan perintah berikut:  
    1. `Party --allow-untrusted update` Download daftar package terbaru dari Alpine repo — wajib dijalankan sebelum install apapun agar package list up to date.
    2. `Party --allow-untrusted add gcc musl-dev fuse-dev` Install compiler (`gcc`), C standard library untuk Alpine (`musl-dev`), dan header/library FUSE (`fuse-dev`) yang dibutuhkan untuk compile program FUSE.
    3. `gcc /tmp/hello_fuse.c -o /tmp/hello_fuse \`pkg-config --cflags --libs fuse\``
Compile program FUSE. `pkg-config --cflags --libs fuse` otomatis ambil flag yang dibutuhkan untuk link ke library FUSE.
    4. `mkdir -p /tmp/mnt` Buat direktori kosong sebagai **mount point** — tempat filesystem FUSE akan di-mount.
    5. `/tmp/hello_fuse /tmp/mnt &` Jalankan program FUSE dan mount ke `/tmp/mnt`. Tanda `&` berarti jalan di background agar terminal tidak ter-block.
    6. `ls /tmp/mnt` Lihat isi filesystem FUSE — harusnya muncul `hello.txt`.
    7. `cat /tmp/mnt/hello.txt` Baca isi file dari filesystem FUSE — harusnya muncul `Hello from FUSE!`.

## Penjelasan kode 

.config merupakan konfigurasi tersimpan pada direktori kernel yang sebelumnya dibuat manual dengan menuconfig, disalin pada direktori soal_1 supaya bisa reusable untuk menjalankan kernel.h  

Secara garis besar, `kernel.sh` merupakan skrip otomatisasi untuk compile kernel Linux, menghasilkan bzImage yang disimpan dalam folder osboot. Fungsi utama skrip ini adalah mengotomatiskan proses download, konfigurasi, kompilasi, dan penyalinan kernel Linux sehingga menghasilkan file bootable (`bzImage`) yang siap dipakai oleh sistem operasi atau bootloader. Alur utamanya adalah:
1. Memastikan source code kernel Linux versi yang ditentukan tersedia.
2. Mengunduh source code kernel jika belum ada.
3. Mengekstrak source code kernel.
4. Menerapkan konfigurasi kernel dari file `.config` yang telah disediakan.
5. Melakukan proses kompilasi kernel.
6. Mengambil hasil kompilasi berupa file `bzImage` (kernel yang siap digunakan).
7. Menyimpan hasil tersebut ke direktori `osboot`.  

single.sh berfungsi untuk membangun initramfs minimal yang akan digunakan saat proses boot sistem operasi. Jika `kernel.sh` menghasilkan kernel `bzImage`, maka skrip ini menghasilkan filesystem awal `single.gz` yang akan dimuat oleh kernel saat boot, sehingga terbentuk lingkungan sistem operasi minimal yang siap dijalankan dalam single user mode.  
* Menentukan direktori kerja dan lokasi output build.
* Membersihkan hasil build sebelumnya.
* Membuat struktur filesystem dasar untuk sistem operasi.
* Menyiapkan BusyBox sebagai kumpulan utilitas sistem utama.
* Membuat akun root melalui file `passwd`.
* Mengunduh dan menambahkan `apk.static` sebagai program `Party`.
* Membuat kode sumber program FUSE sederhana (`hello_fuse.c`).
* Membuat skrip `init` yang dijalankan pertama kali saat boot.
* Melakukan inisialisasi filesystem virtual (`/proc`, `/sys`, `/dev`).
* Mengonfigurasi jaringan dasar (IP, gateway, dan DNS).
* Menyiapkan lingkungan dan database paket Alpine Linux sementara.
* Menampilkan banner "Farewell Party OS" saat sistem dijalankan.
* Menjalankan shell interaktif sebagai antarmuka pengguna.
* Mengatur permission direktori penting seperti `/tmp` dan `/root`.
* Mengemas seluruh filesystem menjadi file initramfs `single.gz`, menyimpannya dalam direktori osboot dan membersihkan file sementara.

multi.sh adalah skrip otomatisasi untuk membangun initramfs mode multi-user yang berisi filesystem dasar, sistem login dengan beberapa akun pengguna, konfigurasi hak akses, utilitas sistem, serta package manager, kemudian mengemas semuanya menjadi file multi.gz yang siap digunakan saat proses boot sistem operasi.  
* Membersihkan direktori build dan hasil initramfs sebelumnya.
* Membuat struktur filesystem untuk sistem operasi multi-user.
* Menyalin device files penting ke dalam filesystem.
* Menginstal BusyBox sebagai utilitas inti sistem.
* Membuat akun pengguna (`root`, `henn`, `hann`, `viii`, `kids`, dan `guest`).
* Menetapkan grup, ownership, dan permission untuk setiap direktori pengguna.
* Membuat banner login yang ditampilkan setelah pengguna masuk.
* Menyimpan data autentikasi dan shell yang dapat digunakan pengguna.
* Membuat skrip `init` untuk inisialisasi sistem saat boot.
* Membuat mekanisme login khusus (`mylogin`) dengan validasi username dan password.
* Mengonfigurasi jaringan dasar serta database package manager saat startup.
* Menambahkan package manager `Party` (berbasis `apk.static`) dan repository Alpine Linux.
* Menyertakan program contoh FUSE (`hello_fuse.c`) ke dalam filesystem.
* Mengemas seluruh filesystem menjadi file initramfs `multi.gz`.
* Membersihkan direktori sementara setelah proses build selesai.

`iso.sh` adalah skrip untuk membuat file ISO bootable (`farewell.iso`) dengan bootloader GRUB yang menyediakan pilihan boot ke mode Single User atau Multi User menggunakan kernel dan initramfs yang telah dibuat sebelumnya.  
1. Memeriksa keberadaan file `bzImage`, `single.gz`, dan `multi.gz`.
2. Membersihkan file ISO dan direktori build yang lama.
3. Membuat struktur direktori ISO beserta folder GRUB.
4. Menyalin kernel dan kedua initramfs ke dalam struktur ISO.
5. Membuat konfigurasi GRUB dengan dua menu boot: Single User dan Multi User.
6. Menghasilkan file ISO bootable menggunakan `grub-mkrescue`.
7. Menghapus direktori build sementara.
8. Menampilkan lokasi file ISO yang berhasil dibuat (`farewell.iso`).

`qemu.sh` adalah skrip untuk menjalankan dan menguji FarewellOS menggunakan emulator QEMU, baik langsung ke mode Single User, Multi User, maupun melalui file ISO yang menampilkan menu GRUB.  
1. Menerima parameter boot (`--single`, `--multi`, atau `--all`).
2. Memeriksa file kernel dan filesystem yang dibutuhkan sesuai mode yang dipilih.
3. Menampilkan pesan error jika file yang diperlukan tidak tersedia.
4. Menjalankan QEMU dengan konfigurasi CPU, memori, dan jaringan virtual.
5. Memuat kernel dan `single.gz` untuk mode Single User (`--single`).
6. Memuat kernel dan `multi.gz` untuk mode Multi User (`--multi`).
7. Mem-boot file `farewell.iso` dan menampilkan menu GRUB untuk memilih mode boot (`--all`).
8. Menampilkan petunjuk penggunaan jika parameter yang diberikan tidak valid.

**`backup.sh` adalah skrip untuk mengarsipkan hasil build sistem operasi (`bzImage`, `single.gz`, `multi.gz`, dan `farewell.iso`) ke dalam satu file ZIP bertimestamp, kemudian menghapus file aslinya untuk menghemat ruang penyimpanan.  
1. Memeriksa apakah file hasil build tersedia di folder `osboot`.
2. Menampilkan peringatan untuk file yang tidak ditemukan.
3. Menghentikan proses jika tidak ada file yang dapat di-backup.
4. Membuat nama file ZIP berdasarkan tanggal dan waktu saat backup dilakukan.
5. Mengumpulkan seluruh file build yang tersedia.
6. Mengarsipkan file-file tersebut ke dalam satu file ZIP.
7. Menghapus file asli yang telah berhasil diarsipkan.
8. Menampilkan lokasi file backup serta perintah untuk melakukan restore.

## Output
qemu manual untuk single.sh
<br><img width="1061" height="622" alt="image" src="https://github.com/user-attachments/assets/e3233d84-4060-418a-a968-e7fd2ad27d0d" /><br>

qemu manual untuk multi.sh
<br><img width="1041" height="651" alt="image" src="https://github.com/user-attachments/assets/e0ea6d4b-d121-47c9-bafb-eb96e42afd23" /><br>
<br><img width="1207" height="633" alt="image" src="https://github.com/user-attachments/assets/319955ca-ea96-48a4-b72d-187adc4be6ed" /><br>
<br><img width="1201" height="631" alt="image" src="https://github.com/user-attachments/assets/4bb93aab-ac39-4102-92fa-b1fc060dc3d8" /><br>

[video demo ISO, qemu.sh, network, package manager & fuse](https://youtu.be/muQ7D4r3S7Y)

# Soal 2
## Step pengerjaan
1. Download, unzip, dan pindahkan file template ke workdir sekarang
   ```
   wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=14rOog6VbT6sxjp3s_GJoTW7hgE6FAtmo' -O template.zip
   unzip template.zip
   mv template/* template/.* . 2>/dev/null
   rm -rf template template.zip
   ```
2. Install software yang diperlukan
   ```
   sudo apt update
   sudo apt install nasm bcc bin86 bochs bochs-sdl
   ```
3. Isi getchar pada kernel.asm
   ```
   _getChar:
    mov ah, 0
    int 16h

    mov ah, 0
    ret
   ```
4. Cari path untuk menyesuaikan VGA bochsrc.txt
   ```
   dpkg -L bochs | grep BIOS
   ```
   Ditemukan hasil
   > /usr/share/bochs/VGABIOS-lgpl-latest
   Cari path BIOS
   ```
   find /usr/share -iname "*bios*" 2>/dev/null
   ```
   Ditemukan
   > /usr/share/seabios/bios.bin
5. Lengkapi kernel.sh dan kernel.c
6. Lakukan boot
   
## Cara kerja kode
### bootloader.asm
Kode ini merupakan program bootloader berbasis arsitektur x86 16-bit yang berfungsi untuk memuat kernel sistem operasi dari media penyimpanan ke memori, kemudian mengalihkan eksekusi program ke kernel tersebut. Bootloader ini juga menyediakan mekanisme penanganan kesalahan apabila proses pembacaan kernel dari disk gagal dilakukan.

```asm
bits 16
org 0x7C00

jmp start
nop
```

* Bagian ini menentukan bahwa program akan dijalankan dalam mode 16-bit dan ditempatkan pada alamat memori 0x7C00, yaitu lokasi standar tempat BIOS memuat boot sector. Instruksi lompat digunakan untuk langsung menuju bagian utama program, sedangkan instruksi nop berfungsi sebagai pengisi satu byte yang sering digunakan untuk menjaga kompatibilitas struktur boot sector.

```asm
KERNEL_SEGMENT equ 0x1000
KERNEL_SECTORS equ 1
```

* Bagian ini mendefinisikan dua konstanta. Konstanta pertama menunjukkan lokasi memori tempat kernel akan dimuat, sedangkan konstanta kedua menunjukkan jumlah sektor disk yang akan dibaca sebagai kernel.

```asm
start:

    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sti
```

* Bagian ini melakukan inisialisasi awal lingkungan eksekusi. Seluruh register segmen diatur ke nilai awal yang konsisten dan stack ditempatkan pada lokasi yang aman agar program dapat bekerja dengan kondisi memori yang terkontrol sejak awal proses booting.

```asm
mov ax, KERNEL_SEGMENT
mov es, ax

xor bx, bx
```

* Bagian ini menyiapkan alamat tujuan di memori yang nantinya akan digunakan sebagai lokasi penyimpanan kernel yang dibaca dari disk. Register yang digunakan sebagai penunjuk offset juga diatur ke posisi awal.

```asm
mov ah, 0x02
mov al, KERNEL_SECTORS
mov ch, 0x00
mov cl, 0x02
mov dh, 0x00

; IMPORTANT:
; BIOS already gives boot drive in DL
; DO NOT overwrite DL

int 0x13
```

* Bagian ini menyiapkan parameter yang diperlukan untuk membaca data dari disk menggunakan layanan BIOS. Data yang dibaca adalah kernel yang berada pada sektor tertentu di media penyimpanan. Setelah seluruh parameter siap, BIOS dipanggil untuk melakukan proses pembacaan tersebut.

```asm
jc disk_error
```

* Setelah proses pembacaan disk selesai, bagian ini memeriksa apakah terjadi kesalahan. Jika BIOS melaporkan kegagalan, eksekusi program akan dialihkan ke prosedur penanganan error.

```asm
cli

mov ax, KERNEL_SEGMENT
mov ds, ax
mov es, ax

mov ax, 0x9000
mov ss, ax

mov sp, 0xFFFF
mov bp, 0xFFFF

sti
```

* Bagian ini menyiapkan lingkungan kerja yang akan digunakan oleh kernel. Register segmen data dan segmen tambahan diarahkan ke lokasi kernel, sementara stack dipindahkan ke area memori yang lebih aman agar tidak bertabrakan dengan data kernel maupun bootloader.

```asm
push word KERNEL_SEGMENT
push word 0x0000
retf
```

* Bagian ini melakukan perpindahan kontrol dari bootloader menuju kernel. Eksekusi program tidak lagi berada pada bootloader, melainkan dilanjutkan oleh kode kernel yang telah dimuat ke memori.

```asm
disk_error:

    mov si, msg
```

* Bagian ini merupakan awal dari prosedur penanganan kesalahan yang dijalankan apabila kernel gagal dibaca dari media penyimpanan. Penunjuk karakter diarahkan ke pesan yang akan ditampilkan.

```asm
.print:

    lodsb
    or al, al
    jz $

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10

    jmp .print
```

* Bagian ini menampilkan pesan kesalahan karakter demi karakter ke layar menggunakan layanan BIOS. Proses berlangsung terus hingga seluruh karakter pada pesan selesai dibaca. Setelah pesan berakhir, program berhenti pada kondisi diam sehingga pengguna dapat melihat informasi kesalahan yang muncul.

```asm
msg db 'DISK ERROR',0
```

* Bagian ini mendefinisikan teks pesan yang akan ditampilkan apabila proses pembacaan kernel mengalami kegagalan.

```asm
times 510-($-$$) db 0
dw 0xAA55
```

* Bagian ini mengisi sisa ruang boot sector dengan nilai nol hingga ukuran total mencapai 512 byte. Dua byte terakhir diisi dengan tanda tangan boot sector yang digunakan BIOS untuk mengenali bahwa sektor tersebut dapat dijalankan sebagai bootloader.

### bochsrc.txt
Kode ini merupakan berkas konfigurasi emulator Bochs yang digunakan untuk menentukan spesifikasi mesin virtual, sumber BIOS, perangkat boot, media penyimpanan virtual, sistem tampilan, serta pengaturan perangkat tambahan lainnya. Konfigurasi ini memungkinkan emulator menjalankan sistem operasi atau bootloader yang tersimpan pada berkas floppy image.

```ini
megs: 32
```

* Bagian ini menentukan jumlah memori utama (RAM) yang tersedia untuk mesin virtual. Nilai 32 menunjukkan bahwa sistem yang dijalankan di dalam emulator akan memiliki kapasitas memori sebesar 32 MB untuk menjalankan program dan menyimpan data selama proses eksekusi.

```ini
romimage: file=/usr/share/seabios/bios.bin
```

* Bagian ini menentukan lokasi berkas BIOS utama yang digunakan oleh emulator. BIOS berfungsi sebagai firmware virtual yang akan dijalankan pertama kali saat mesin virtual dinyalakan dan bertugas melakukan inisialisasi perangkat sebelum proses boot berlangsung.

```ini
vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest
```

* Bagian ini menentukan lokasi BIOS untuk perangkat grafis virtual. BIOS VGA bertanggung jawab menyediakan fungsi dasar tampilan sehingga sistem yang berjalan dapat menampilkan informasi ke layar sejak tahap awal proses booting.

```ini
boot: floppy
```

* Bagian ini menentukan perangkat yang digunakan sebagai sumber boot utama. Pengaturan ini menunjukkan bahwa emulator akan mencoba memulai sistem dari media floppy disk virtual yang telah ditentukan dalam konfigurasi.

```ini
floppya: 1_44=floppy.img, status=inserted
```

* Bagian ini mendefinisikan floppy drive virtual beserta berkas image yang digunakan. Berkas floppy.img diperlakukan sebagai disket berkapasitas 1,44 MB dan dianggap sudah terpasang pada drive sehingga dapat langsung digunakan saat proses boot.

```ini
log: bochslog.txt
```

* Bagian ini menentukan nama berkas log yang digunakan untuk menyimpan informasi aktivitas emulator. Berkas log dapat membantu pengguna melakukan analisis atau pencarian kesalahan selama proses eksekusi sistem virtual.

```ini
mouse: enabled=0
```

* Bagian ini mengatur status perangkat mouse virtual. Nilai 0 menunjukkan bahwa dukungan mouse dinonaktifkan sehingga emulator tidak menyediakan perangkat mouse kepada sistem yang dijalankan.

```ini
display_library: sdl2
```

* Bagian ini menentukan pustaka grafis yang digunakan untuk menampilkan jendela emulator. Penggunaan SDL2 memungkinkan tampilan emulator muncul dalam jendela grafis yang dapat berinteraksi dengan sistem operasi host.

```ini
sound: driver=dummy
```

* Bagian ini mengatur sistem suara pada emulator. Driver dummy menunjukkan bahwa dukungan suara tidak benar-benar diaktifkan dan semua keluaran audio akan diabaikan tanpa menghasilkan suara nyata.

### kernel.asm
* Deskripsi singkat kode ini secara keseluruhan buat apa tanpa menjelaskan cara kerjanya

Kode ini merupakan program assembly 16-bit yang menyediakan titik awal eksekusi sistem, menampilkan karakter pada layar mode teks, serta menyediakan beberapa fungsi dasar yang dapat digunakan oleh program lain, yaitu fungsi untuk menulis data ke lokasi memori tertentu dan fungsi untuk membaca masukan karakter dari keyboard.

```asm
bits 16

global _start
global _putInMemory
global _getChar
extern _main
```

* Bagian ini mendefinisikan bahwa program akan dijalankan dalam mode 16-bit. Selain itu, beberapa label ditandai sebagai simbol global sehingga dapat diakses oleh modul lain. Deklarasi eksternal menunjukkan bahwa terdapat fungsi lain yang berada di luar berkas ini dan dapat digunakan selama proses pengembangan sistem.

```asm
_start:

    cli

    mov ax, cs
    mov ds, ax
    mov es, ax
```

* Bagian ini merupakan titik awal eksekusi program. Pada tahap ini dilakukan penyiapan lingkungan kerja dengan menyelaraskan segmen data dan segmen tambahan terhadap segmen kode yang sedang digunakan sehingga akses terhadap data dapat dilakukan secara konsisten.

```asm
mov ax, 0xB800
mov ds, ax
```

* Bagian ini mengarahkan register segmen data ke area memori video mode teks. Area memori tersebut digunakan untuk menampilkan karakter secara langsung ke layar tanpa memerlukan layanan BIOS tambahan.

```asm
mov byte [0], 'A'
mov byte [1], 0x0F
```

* Bagian ini menuliskan sebuah karakter beserta atribut tampilannya ke memori video. Karakter yang ditulis akan muncul pada posisi awal layar dengan warna yang ditentukan oleh nilai atribut yang diberikan.

```asm
.hang:
    jmp .hang
```

* Bagian ini membuat program tetap berada pada kondisi berjalan tanpa melanjutkan ke instruksi lain. Dengan demikian, tampilan yang telah ditulis ke layar tetap dapat dilihat dan program tidak berpindah ke area memori yang tidak diinginkan.

```asm
_putInMemory:
    push bp
    mov bp, sp

    push ds
```

* Bagian ini merupakan awal dari fungsi penulisan memori. Register yang diperlukan disimpan terlebih dahulu agar kondisi program sebelum pemanggilan fungsi tetap terjaga dan dapat dipulihkan setelah fungsi selesai dijalankan.

```asm
mov ax, [bp+4]
mov si, [bp+6]
mov cl, [bp+8]
```

* Bagian ini mengambil parameter yang diberikan oleh program pemanggil. Parameter tersebut berisi informasi mengenai segmen memori tujuan, alamat offset tujuan, dan data yang akan dituliskan.

```asm
mov ds, ax
mov [si], cl
```

* Bagian ini melakukan proses penulisan data ke lokasi memori yang telah ditentukan sebelumnya. Data yang diterima sebagai parameter akan disimpan pada alamat tujuan yang sesuai.

```asm
pop ds

pop bp
ret
```

* Bagian ini mengembalikan kondisi register yang sebelumnya disimpan dan mengakhiri fungsi. Setelah itu, kontrol program dikembalikan ke bagian yang memanggil fungsi tersebut.

```asm
_getChar:
```

* Bagian ini merupakan awal fungsi yang bertugas membaca masukan dari keyboard dan mengembalikannya kepada program yang memanggil fungsi tersebut.

```asm
mov ah, 0x00
int 16h
```

* Bagian ini memanggil layanan BIOS keyboard untuk menunggu hingga pengguna menekan sebuah tombol. Setelah tombol ditekan, informasi karakter yang dimasukkan akan diterima oleh program.

```asm
mov ah, 0
ret
```

* Bagian ini membersihkan bagian register yang tidak diperlukan sehingga hanya karakter hasil masukan yang digunakan. Setelah itu fungsi selesai dan hasil pembacaan keyboard dikembalikan kepada program pemanggil.

### kernel.c
Kode ini merupakan implementasi shell sederhana pada sistem operasi 16-bit yang menyediakan berbagai fungsi dasar seperti menampilkan teks ke layar, membaca masukan pengguna dari keyboard, mengelola tampilan layar, memproses string, melakukan operasi aritmetika sederhana, mengubah warna tampilan berdasarkan tema musim, serta menampilkan pola segitiga menggunakan perintah yang diketik oleh pengguna.

```c
int cursor = 0;
char color = 0x07;
```

* Bagian ini mendefinisikan variabel global yang digunakan untuk menyimpan posisi penulisan karakter pada layar dan atribut warna teks yang sedang aktif. Nilai awal warna menunjukkan tampilan teks standar pada mode teks VGA.

```c
void putInMemory(int segment, int address, char character);
int getChar();
```

* Bagian ini merupakan deklarasi fungsi eksternal yang disediakan oleh modul lain. Fungsi pertama digunakan untuk menuliskan data ke lokasi memori tertentu, sedangkan fungsi kedua digunakan untuk menerima masukan karakter dari keyboard.

```c
void printChar(char c) {
    putInMemory(0xB800, cursor, c);
    putInMemory(0xB800, cursor + 1, color);
    cursor = cursor + 2;
}
```

* Fungsi ini bertugas menampilkan satu karakter ke layar. Setelah karakter ditampilkan beserta atribut warnanya, posisi kursor dipindahkan ke lokasi berikutnya sehingga karakter selanjutnya dapat ditulis tanpa menimpa karakter sebelumnya.

```c
void printString(char *str) {
    int i = 0;
    while (str[i] != '\0') {
        printChar(str[i]);
        i++;
    }
}
```

* Fungsi ini digunakan untuk menampilkan sebuah teks yang terdiri atas banyak karakter. Setiap karakter dalam string diproses satu per satu hingga ditemukan penanda akhir string.

```c
void newline() {
    int temp = cursor;
    int current_row = 0;

    while (temp >= 160) {
        temp = temp - 160;
        current_row++;
    }

    cursor = (current_row + 1) * 160;
}
```

* Fungsi ini memindahkan posisi kursor ke awal baris berikutnya. Dengan demikian, teks yang ditampilkan setelahnya akan muncul pada baris baru seperti efek tombol Enter pada terminal.

```c
void clearScreen() {
    int i;
    for (i = 0; i < 4000; i = i + 2) {
        putInMemory(0xB800, i, ' ');
        putInMemory(0xB800, i + 1, color);
    }
    cursor = 0;
}
```

* Fungsi ini membersihkan seluruh isi layar dengan mengganti setiap posisi karakter menjadi spasi kosong. Setelah layar dibersihkan, posisi kursor dikembalikan ke sudut kiri atas layar.

```c
void readString(char *buffer)
```

* Fungsi ini digunakan untuk membaca satu baris masukan dari pengguna. Karakter yang diketik akan disimpan ke dalam buffer dan ditampilkan ke layar. Fungsi ini juga menangani tombol Enter untuk mengakhiri input serta tombol Backspace untuk menghapus karakter yang telah diketik.

```c
int strcmp(char *str1, char *str2)
```

* Fungsi ini membandingkan dua string karakter demi karakter. Hasil perbandingan digunakan untuk menentukan apakah kedua string memiliki isi yang sama atau berbeda.

```c
int startsWith(char *str, char *prefix)
```

* Fungsi ini memeriksa apakah suatu string diawali oleh awalan tertentu. Fungsi ini berguna untuk mengenali perintah yang memiliki parameter tambahan setelah nama perintah.

```c
int atoi(char *str)
```

* Fungsi ini mengubah data berupa teks angka menjadi nilai bilangan bulat sehingga dapat digunakan dalam operasi matematika.

```c
void intToString(int n, char *str)
```

* Fungsi ini melakukan konversi dari bilangan bulat menjadi bentuk teks. Implementasinya tidak menggunakan operator modulo maupun pembagian langsung, melainkan menggunakan pengurangan berulang untuk memperoleh setiap digit angka.

```c
void handle_add(char *cmd)
```

* Fungsi ini menangani perintah penjumlahan. Dua angka yang diberikan oleh pengguna dipisahkan dari teks perintah, kemudian dijumlahkan dan hasilnya ditampilkan ke layar.

```c
void handle_sub(char *cmd)
```

* Fungsi ini menangani perintah pengurangan. Setelah dua angka diperoleh dari masukan pengguna, operasi pengurangan dilakukan dan hasilnya ditampilkan. Jika hasil bernilai negatif, tanda minus akan ditampilkan terlebih dahulu.

```c
void handle_fac(char *cmd)
```

* Fungsi ini menghitung nilai faktorial dari sebuah bilangan. Sebelum perhitungan dilakukan, terdapat pembatasan nilai maksimum untuk mencegah hasil yang terlalu besar. Jika batas terlampaui, sistem akan menampilkan pesan peringatan.

```c
void handle_season(char *cmd)
```

* Fungsi ini mengubah warna tampilan teks berdasarkan nama musim yang diberikan pengguna. Setiap musim memiliki warna tersendiri sehingga tampilan shell dapat berubah sesuai tema yang dipilih.

```c
void handle_triangle(char *cmd)
```

* Fungsi ini menampilkan pola segitiga menggunakan karakter 'x'. Jumlah lapisan segitiga ditentukan oleh angka yang diberikan pengguna pada perintah.

```c
void main() {
    char cmd[64];

    clearScreen();

    printString("Welcome to <X>");
    newline();
    printString("type 'help'");
    newline();
    newline();
```

* Bagian awal fungsi utama digunakan untuk membersihkan layar dan menampilkan pesan pembuka ketika shell pertama kali dijalankan. Pesan ini berfungsi sebagai informasi awal bagi pengguna.

```c
while (1) {
    printString("> ");
    readString(cmd);
    newline();
```

* Bagian ini membentuk loop utama shell yang berjalan terus-menerus. Shell akan menampilkan prompt, menerima masukan pengguna, dan kemudian memproses perintah yang diberikan.

```c
if (strcmp(cmd, "check") == 0) {
    printString("ok");
}
```

* Perintah ini digunakan untuk menguji apakah shell berfungsi dengan baik. Jika pengguna mengetikkan "check", sistem akan memberikan respons sederhana sebagai tanda bahwa shell aktif.

```c
else if (strcmp(cmd, "help") == 0) {
    printString("check add sub fac season triangle clear about");
}
```

* Perintah ini menampilkan daftar perintah yang tersedia sehingga pengguna dapat mengetahui fitur-fitur yang dapat digunakan.

```c
else if (strcmp(cmd, "about") == 0) {
    printString("OS 16-Bit Simple Shell - Modul 5.1");
}
```

* Perintah ini menampilkan informasi singkat mengenai sistem atau shell yang sedang dijalankan.

```c
else if (strcmp(cmd, "clear") == 0) {
    clearScreen();
    continue;
}
```

* Perintah ini membersihkan seluruh isi layar dan langsung mengembalikan kontrol ke awal loop shell tanpa menambahkan baris baru.

```c
else if (startsWith(cmd, "add ")) {
    handle_add(cmd);
}
```

* Perintah ini memanggil fitur penjumlahan apabila masukan pengguna diawali dengan kata "add".

```c
else if (startsWith(cmd, "sub ")) {
    handle_sub(cmd);
}
```

* Perintah ini memanggil fitur pengurangan apabila masukan diawali dengan kata "sub".

```c
else if (startsWith(cmd, "fac ")) {
    handle_fac(cmd);
}
```

* Perintah ini memanggil fitur perhitungan faktorial berdasarkan angka yang diberikan pengguna.

```c
else if (startsWith(cmd, "season ")) {
    handle_season(cmd);
}
```

* Perintah ini digunakan untuk mengubah tema warna shell sesuai musim yang dipilih.

```c
else if (startsWith(cmd, "triangle ")) {
    handle_triangle(cmd);
}
```

* Perintah ini digunakan untuk membuat pola segitiga dengan jumlah lapisan sesuai parameter yang diberikan.

```c
else {
    if (strcmp(cmd, "") != 0) {
        printString("Command not found");
    }
}
```

* Bagian ini menangani perintah yang tidak dikenali. Jika pengguna memasukkan teks yang tidak sesuai dengan perintah yang tersedia, shell akan menampilkan pesan bahwa perintah tersebut tidak ditemukan.

```c
newline();
}
```

* Setelah sebuah perintah selesai diproses, shell berpindah ke baris baru dan kembali menunggu masukan berikutnya dari pengguna.

### Makefile
Kode ini digunakan untuk mengotomatisasi proses pembuatan sistem operasi sederhana berbasis 16-bit. Berkas ini mengatur tahapan pembuatan floppy image, kompilasi bootloader, kompilasi kernel, penggabungan seluruh komponen ke dalam media boot virtual, serta menjalankan hasilnya menggunakan emulator.

```make
prepare:
	dd if=/dev/zero of=floppy.img bs=512 count=2880
```

* Bagian ini bertugas menyiapkan media penyimpanan virtual berupa berkas floppy image. Berkas tersebut akan digunakan sebagai representasi disket virtual yang nantinya berisi bootloader dan kernel sistem operasi. Ukuran image yang dibuat disesuaikan dengan kapasitas standar floppy disk 1,44 MB.

```make
bootloader:
	nasm -f bin bootloader.asm -o bootloader.bin
	dd if=bootloader.bin of=floppy.img bs=512 count=1 conv=notrunc
```

* Bagian ini bertanggung jawab membangun bootloader dari kode assembly menjadi berkas biner yang dapat dijalankan. Setelah berhasil dibuat, bootloader ditempatkan pada sektor pertama floppy image karena sektor tersebut merupakan lokasi yang akan dibaca pertama kali oleh BIOS saat proses booting berlangsung.

```make
kernel:
	nasm -f as86 kernel.asm -o kernel-asm.o
	bcc -ansi -c kernel.c -o kernel.o
	ld86 -o kernel.bin -d kernel-asm.o kernel.o
	dd if=kernel.bin of=floppy.img bs=512 seek=1 conv=notrunc
```

* Bagian ini digunakan untuk membangun kernel sistem operasi. Kode assembly dan kode C dikompilasi secara terpisah menjadi berkas objek, kemudian keduanya digabungkan menjadi satu berkas kernel yang siap dijalankan. Setelah proses pembangunan selesai, kernel disimpan ke dalam floppy image pada sektor setelah bootloader sehingga dapat dimuat oleh bootloader ketika sistem dijalankan.

```make
build: prepare bootloader kernel
```

* Bagian ini merupakan target utama yang menggabungkan seluruh proses pembangunan sistem. Ketika target ini dijalankan, seluruh tahapan mulai dari pembuatan floppy image, pembangunan bootloader, hingga pembangunan kernel akan dilakukan secara berurutan.

```make
run:
	bochs -f bochsrc.txt
```

* Bagian ini digunakan untuk menjalankan sistem operasi yang telah dibuat menggunakan emulator Bochs. Emulator akan membaca konfigurasi dari berkas yang telah ditentukan dan menjalankan floppy image sehingga pengguna dapat menguji hasil sistem operasi tanpa memerlukan perangkat keras fisik.

## Output
<img width="978" height="664" alt="image" src="https://github.com/user-attachments/assets/40fa3aca-e4d7-444e-b0fa-90ac96cbcf2e" />


    
