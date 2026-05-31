int cursor = 0;
char color = 0x07;

void putInMemory(int segment, int address, char character);
int getChar();


void printChar(char c) {
    putInMemory(0xB800, cursor, c);
    putInMemory(0xB800, cursor + 1, color);
    cursor = cursor + 2;
}

void printString(char *str) {
    int i = 0;
    while (str[i] != '\0') {
        printChar(str[i]);
        i++;
    }
}

void newline() {
    int temp = cursor;
    int current_row = 0;

    while (temp >= 160) {
        temp = temp - 160;
        current_row++;
    }

    cursor = (current_row + 1) * 160;
}

void clearScreen() {
    int i;
    for (i = 0; i < 4000; i = i + 2) {
        putInMemory(0xB800, i, ' ');
        putInMemory(0xB800, i + 1, color);
    }
    cursor = 0;
}

void readString(char *buffer) {
    int i = 0;
    char c;
    while (1) {
        c = (char)getChar();

        if (c == '\r' || c == '\n') { // Enter
            buffer[i] = '\0';
            break;
        } else if (c == '\b') { // Backspace
            if (i > 0) {
                i--;
                cursor = cursor - 2;
                printChar(' ');
                cursor = cursor - 2;
            }
        } else {
            if (i < 63) { // Batasi ukuran buffer
                buffer[i] = c;
                printChar(c);
                i++;
            }
        }
    }
}

/* Helper Pemroses String */
int strcmp(char *str1, char *str2) {
    while (*str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }
    return *(unsigned char *)str1 - *(unsigned char *)str2;
}

int startsWith(char *str, char *prefix) {
    while (*prefix) {
        if (*str != *prefix) return 0;
        str++;
        prefix++;
    }
    return 1;
}

int atoi(char *str) {
    int res = 0;
    while (*str >= '0' && *str <= '9') {
        res = (res * 10) + (*str - '0');
        str++;
    }
    return res;
}

// Dilarang pakai modulo (%), jadi kita pakai pengurangan berulang untuk ekstraksi angka
void intToString(int n, char *str) {
    char temp[7];
    int i = 0;
    int j = 0;

    if (n == 0) {
        str[0] = '0';
        str[1] = '\0';
        return;
    }

    while (n > 0) {
        int rem = 0;
        int t = n;
        // Simulasi n % 10 menggunakan pengurangan berulang
        while (t >= 10) {
            t = t - 10;
        }
        rem = t;
        temp[i] = rem + '0';
        i++;

        // Simulasi n = n / 10
        t = 0;
        while (n >= 10) {
            n = n - 10;
            t++;
        }
        n = t;
    }

    // Balik urutan string temp ke str asli
    for (j = 0; j < i; j++) {
        str[j] = temp[i - 1 - j];
    }
    str[i] = '\0';
}

/* Handler Fitur Utama */
void handle_add(char *cmd) {
    // Format: "add <a> <b>" -> skip "add " (4 karakter)
    char *p = cmd + 4;
    int a, b, res;
    char buf[7];

    a = atoi(p);
    // Geser pointer melewati angka pertama
    while (*p >= '0' && *p <= '9') p++;
    while (*p == ' ') p++; // skip spasi antar angka
    b = atoi(p);

    res = a + b;
    intToString(res, buf);
    printString(buf);
}

void handle_sub(char *cmd) {
    char *p = cmd + 4;
    int a, b, res;
    char buf[7];

    a = atoi(p);
    while (*p >= '0' && *p <= '9') p++;
    while (*p == ' ') p++;
    b = atoi(p);

    res = a - b;
    if (res < 0) {
        printString("-");
        res = -res;
    }
    intToString(res, buf);
    printString(buf);
}

void handle_fac(char *cmd) {
    char *p = cmd + 4;
    int n = atoi(p);
    int result = 1;
    int i;
    char buf[7];

    for (i = 1; i <= n; i++) {
        if (n >= 8) {
            printString("know your limit little bro");
            return;
        }
        result = result * i;
    }

    intToString(result, buf);
    printString(buf);
}

void handle_season(char *cmd) {
    char *name = cmd + 7; // Skip "season "

    if (strcmp(name, "winter") == 0) {
        color = 0x01; // Blue text, Black background
        printString("winter mode");
    } else if (strcmp(name, "spring") == 0) {
        color = 0x02; // Green text
        printString("spring mode");
    } else if (strcmp(name, "summer") == 0) {
        color = 0x0E; // Yellow text
        printString("summer mode");
    } else if (strcmp(name, "fall") == 0) {
        color = 0x06; // Brown text
        printString("fall mode");
    } else if (strcmp(name, "radiant") == 0) {
        color = 0x0D; // Pink Fanta (Light Magenta) text
        printString("radiant mode");
    } else {
        printString("Unknown season. Available: winter, spring, summer, fall, radiant");
    }
}

void handle_triangle(char *cmd) {
    char *p = cmd + 9; // Skip "triangle "
    int layers = atoi(p);
    int i, j;

    for (i = 1; i <= layers; i++) {
        for (j = 0; j < i; j++) {
            printChar('x');
        }
        if (i < layers) {
            newline();
        }
    }
}

void main() {
    char cmd[64];

    clearScreen();

    printString("Welcome to <X>");
    newline();
    printString("type 'help'");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);
        newline();

        /* Shell Command Interpreter */
        if (strcmp(cmd, "check") == 0) {
            printString("ok");
        } else if (strcmp(cmd, "help") == 0) {
            printString("check add sub fac season triangle clear about");
        } else if (strcmp(cmd, "about") == 0) {
            printString("OS 16-Bit Simple Shell - Modul 5.1");
        } else if (strcmp(cmd, "clear") == 0) {
            clearScreen();
            continue; // Langsung loop ulang agar tidak memicu newline tambahan di akhir shell
        } else if (startsWith(cmd, "add ")) {
            handle_add(cmd);
        } else if (startsWith(cmd, "sub ")) {
            handle_sub(cmd);
        } else if (startsWith(cmd, "fac ")) {
            handle_fac(cmd);
        } else if (startsWith(cmd, "season ")) {
            handle_season(cmd);
        } else if (startsWith(cmd, "triangle ")) {
            handle_triangle(cmd);
        } else {
            if (strcmp(cmd, "") != 0) {
                printString("Command not found");
            }
        }

        newline();
    }
}
