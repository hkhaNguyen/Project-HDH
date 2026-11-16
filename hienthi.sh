#!/bin/bash
# c. Hien thi thong tin CD ngan gon, d. Hien thi thong tin CD day du

hienthi_ngangon() {
    local ma ten tacgia theloai nam gia sl
    echo "========== DANH SACH CD =========="
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao"
        tam_dung
        return
    fi
    # Price column is 12 wide in the header, 13 in rows: "đ" takes 2 bytes.
    printf "%-6s %-25s %-20s %12s %5s\n" "Ma" "Ten CD" "Tac gia" "Gia" "Ton"
    while IFS='|' read -r ma ten tacgia theloai nam gia sl; do
        printf "%-6s %-25s %-20s %13s %5s\n" "$ma" "$ten" "$tacgia" "$(dinh_dang_tien "$gia")" "$sl"
    done < "$CD_FILE"
    tam_dung
}

# Print every field of CD $1 followed by its track list.
in_chitiet_cd() {
    local ma ten tacgia theloai nam gia sl
    IFS='|' read -r ma ten tacgia theloai nam gia sl < <(grep "^$1|" "$CD_FILE")
    echo "Ma CD    : $ma"
    echo "Ten CD   : $ten"
    echo "Tac gia  : $tacgia"
    echo "The loai : $theloai"
    echo "Nam PH   : $nam"
    echo "Gia      : $(dinh_dang_tien "$gia")"
    echo "So luong : $sl"
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
