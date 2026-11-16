#!/bin/bash
# c. Hien thi thong tin CD ngan gon, d. Hien thi thong tin CD day du

hienthi_ngangon() {
    echo "========== DANH SACH CD =========="
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao"
        tam_dung
        return
    fi
    printf "%-6s %-25s %-20s %10s %5s\n" "Ma" "Ten CD" "Tac gia" "Gia" "Ton"
    awk -F'|' '{printf "%-6s %-25s %-20s %10s %5s\n", $1, $2, $3, $6, $7}' "$CD_FILE"
    tam_dung
}

# Print every field of CD $1 followed by its track list.
in_chitiet_cd() {
    awk -F'|' -v m="$1" '$1==m {
        print "Ma CD    : " $1
        print "Ten CD   : " $2
        print "Tac gia  : " $3
        print "The loai : " $4
        print "Nam PH   : " $5
        print "Gia      : " $6
        print "So luong : " $7
    }' "$CD_FILE"
    echo "Danh sach bai hat:"
    if grep -q "^$1|" "$CT_FILE"; then
        awk -F'|' -v m="$1" '$1==m {printf "  %2s. %-30s %s\n", $2, $3, $4}' "$CT_FILE"
    else
        echo "  Chua co thong tin chi tiet"
    fi
    echo "--------------------------------------"
}

hienthi_daydu() {
    local ma
    echo "========== THONG TIN CD DAY DU =========="
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao"
        tam_dung
        return
    fi
    read -rp "Nhap Ma CD (Enter de xem tat ca): " ma
    if [ -z "$ma" ]; then
        for ma in $(cut -d'|' -f1 "$CD_FILE"); do
            in_chitiet_cd "$ma"
        done
    elif cd_ton_tai "$ma"; then
        in_chitiet_cd "$ma"
    else
        echo "Khong tim thay CD $ma"
    fi
    tam_dung
}
