#!/bin/bash
# Shared data paths and helper functions for the CD shop program.

DATA_DIR="data"
CD_FILE="$DATA_DIR/cd.txt"
CT_FILE="$DATA_DIR/chitiet.txt"
HD_FILE="$DATA_DIR/hoadon.txt"

# Create the data directory and empty data files if missing.
init_data() {
    mkdir -p "$DATA_DIR"
    touch "$CD_FILE" "$CT_FILE" "$HD_FILE"
}

# Return 0 if $1 is a positive integer.
la_so_duong() {
    [[ $1 =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

# Return 0 if a CD with code $1 exists in cd.txt.
cd_ton_tai() {
    [ -n "$1" ] && grep -q "^$1|" "$CD_FILE"
}

tam_dung() {
    read -rp "Nhan Enter de tiep tuc..."
}

# Read a non-empty text field without '|', re-prompting until valid.
# Prompt and errors go to stderr so the caller can capture the value with $(...).
# Returns 1 on EOF (Ctrl+D).
nhap_chuoi() {   # $1 = prompt
    local x
    while true; do
        read -rp "$1: " x || return 1
        if [ -z "$x" ] || [[ $x == *"|"* ]]; then
            echo "Khong duoc de trong hoac chua ky tu |" >&2
        else
            echo "$x"
            return 0
        fi
    done
}

# Read a positive integer, re-prompting until valid. Returns 1 on EOF (Ctrl+D).
nhap_so() {   # $1 = prompt
    local x
    while true; do
        read -rp "$1: " x || return 1
        if la_so_duong "$x"; then
            echo "$((10#$x))"   # strip leading zeros, else bash reads 020000 as octal
            return 0
        fi
        echo "Phai la so nguyen duong" >&2
    done
}

# Format an amount in dong for display: 1500000 -> 1.500.000đ
# printf pads by bytes and "đ" is 2 bytes, so money columns need width + 1.
dinh_dang_tien() {   # $1 = amount (integer)
    local n=$1 s=""
    while [ "$n" -ge 1000 ]; do
        s=$(printf ".%03d" $((n % 1000)))$s
        n=$((n / 1000))
    done
    echo "$n${s}đ"
}
