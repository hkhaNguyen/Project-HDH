#!/bin/bash
# CD shop program - main menu.

cd "$(dirname "$0")" || exit 1

# Load only the modules that exist, so the menu runs before every module is done.
for module in common.sh nhap.sh hienthi.sh timkiem.sh banhang.sh; do
    [ -f "$module" ] && source "$module"
done

init_data

while true; do
    clear
    echo "========== TIEM BAN DIA CD =========="
    echo "a. Them CD"
    echo "b. Them thong tin chi tiet CD"
    echo "c. Hien thi thong tin CD ngan gon"
    echo "d. Hien thi thong tin CD day du"
    echo "e. Tim kiem CD theo the loai"
    echo "f. Tim kiem CD theo tac gia"
    echo "g. Tim kiem CD theo ten bai hat"
    echo "h. Ban CD"
    echo "i. In hoa don ban hang"
    echo "j. Thoat chuong trinh"
    echo "====================================="
    read -rp "Chon: " chon || exit 0   # EOF (Ctrl+D): quit instead of looping forever
    case $chon in
        a|A) them_cd ;;
        b|B) them_chitiet ;;
        c|C) hienthi_ngangon ;;
        d|D) hienthi_daydu ;;
        e|E) tim_theloai ;;
        f|F) tim_tacgia ;;
        g|G) tim_baihat ;;
        h|H) ban_cd ;;
        i|I) in_hoadon ;;
        j|J) echo "Tam biet!"; exit 0 ;;
        *) echo "Lua chon khong hop le"; tam_dung ;;
    esac
done
