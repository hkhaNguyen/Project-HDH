#!/bin/bash
# =====================================================================
# Chuong trinh tiem ban dia CD (Shell Script)
# Chay: bash cdshop.sh
# Du lieu luu trong thu muc data/ (tu tao khi chay lan dau).
# =====================================================================

# =====================================================================
# Dung chung: duong dan du lieu va cac ham ho tro
# =====================================================================

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

# =====================================================================
# a. Them CD, b. Them thong tin chi tiet CD
# =====================================================================

them_cd() {
    local ma ten tacgia theloai nam gia sl
    echo "========== THEM CD =========="
    while true; do
        ma=$(nhap_chuoi "Ma CD") || return 1
        cd_ton_tai "$ma" || break
        echo "Ma CD $ma da ton tai"
    done
    ten=$(nhap_chuoi "Ten CD") || return 1
    tacgia=$(nhap_chuoi "Tac gia") || return 1
    theloai=$(nhap_chuoi "The loai") || return 1
    nam=$(nhap_so "Nam phat hanh") || return 1
    gia=$(nhap_so "Gia (dong, vd 20000)") || return 1
    sl=$(nhap_so "So luong") || return 1

    echo "$ma|$ten|$tacgia|$theloai|$nam|$gia|$sl" >> "$CD_FILE"
    echo "Da them CD $ma"
    tam_dung
}

them_chitiet() {
    local ma stt ten thoiluong tiep
    echo "========== THEM CHI TIET CD =========="
    # Without any CD, re-prompting for a code would never end.
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao, hay them CD truoc"
        tam_dung
        return 1
    fi
    while true; do
        read -rp "Ma CD: " ma || return 1
        cd_ton_tai "$ma" && break
        echo "Khong tim thay CD $ma"
    done
    tiep="y"
    while [ "$tiep" = "y" ] || [ "$tiep" = "Y" ]; do
        # Next track number continues from the tracks already saved for this CD.
        stt=$(( $(grep -c "^$ma|" "$CT_FILE") + 1 ))
        ten=$(nhap_chuoi "Ten bai hat $stt") || return 1
        while true; do
            read -rp "Thoi luong (mm:ss): " thoiluong || return 1
            [[ $thoiluong =~ ^[0-9]{1,2}:[0-5][0-9]$ ]] && break
            echo "Thoi luong phai co dang mm:ss"
        done
        echo "$ma|$stt|$ten|$thoiluong" >> "$CT_FILE"
        echo "Da them bai $stt"
        read -rp "Them bai nua? (y/n): " tiep || return 1
    done
    tam_dung
}

# =====================================================================
# c. Hien thi thong tin CD ngan gon, d. Hien thi thong tin CD day du
# =====================================================================

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

# =====================================================================
# Chức năng: e. Tìm kiếm CD theo thể loại
#            f. Tìm kiếm CD theo tác giả
#            g. Tìm kiếm CD theo tên bài hát
# Các hàm:
#   in_tieude_bang - in dòng tiêu đề của bảng CD
#   in_dong_cd     - đọc các dòng cd.txt từ stdin, in mỗi CD 1 dòng
#   tim_theo_cot   - lọc cd.txt theo 1 cột
#   tim_va_in      - phần chung của e và f: hỏi từ khóa, tìm, in kết quả
#   tim_theloai    - chức năng e
#   tim_tacgia     - chức năng f
#   tim_baihat     - chức năng g
# Dữ liệu dùng: $CD_FILE (chỉ đọc), $CT_FILE (chỉ đọc)
# Mọi chức năng tìm đều khớp một phần, không phân biệt hoa thường
#   (vd. từ khóa "pop" tìm ra cả thể loại "Pop" và "K-Pop").
# =====================================================================

# ---------------------------------------------------------------------
# in_tieude_bang: In dòng tiêu đề của bảng CD.
# Cùng định dạng cột với hienthi_ngangon (chức năng c).
# ---------------------------------------------------------------------
in_tieude_bang() {
    printf "%-6s %-25s %-20s %12s %5s\n" "Ma" "Ten CD" "Tac gia" "Gia" "Ton"
}

# ---------------------------------------------------------------------
# in_dong_cd: Đọc các dòng định dạng cd.txt từ stdin, in mỗi CD 1 dòng.
# Cách dùng: echo "$ketqua" | in_dong_cd
# ---------------------------------------------------------------------
in_dong_cd() {
    local ma ten tacgia theloai nam gia sl
    # IFS='|' : tách dòng thành các biến theo dấu |
    # -r      : giữ nguyên dấu \ nếu có trong dữ liệu
    while IFS='|' read -r ma ten tacgia theloai nam gia sl; do
        # Cột giá rộng 13 (tiêu đề là 12) vì chữ "đ" chiếm 2 byte.
        printf "%-6s %-25s %-20s %13s %5s\n" "$ma" "$ten" "$tacgia" "$(dinh_dang_tien "$gia")" "$sl"
    done
}

# ---------------------------------------------------------------------
# tim_theo_cot: In các dòng của cd.txt có cột $1 chứa từ khóa $2.
# Tham số : $1 = số thứ tự cột (3 = tác giả, 4 = thể loại)
#           $2 = từ khóa
# Trả về  : in các dòng khớp ra stdout (không in gì nếu không khớp)
# ---------------------------------------------------------------------
tim_theo_cot() {
    # -F'|'         : tách cột bằng dấu |
    # -v c=.. k=..  : truyền biến từ shell vào awk
    # index(a, b)   : vị trí của chuỗi b trong chuỗi a, bằng 0 nếu không có.
    #                 Khác 0 là khớp, awk in dòng đó ra.
    # tolower       : đưa cả hai về chữ thường để không phân biệt hoa thường
    awk -F'|' -v c="$1" -v k="$2" 'index(tolower($c), tolower(k))' "$CD_FILE"
}

# ---------------------------------------------------------------------
# tim_va_in: Phần chung của e và f: hỏi từ khóa, tìm, in kết quả.
# Tham số : $1 = số cột cần tìm trong cd.txt
#           $2 = tiêu đề màn hình
#           $3 = tên trường hiển thị cho người dùng (vd. "the loai")
# Trả về  : 1 nếu chưa có CD hoặc người dùng bấm Ctrl+D
# ---------------------------------------------------------------------
tim_va_in() {
    local cot=$1 tieude=$2 truong=$3 tukhoa ketqua
    echo "========== $tieude =========="
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao"
        tam_dung
        return 1
    fi
    # nhap_chuoi tự hỏi lại nếu từ khóa rỗng.
    tukhoa=$(nhap_chuoi "Nhap $truong can tim") || return 1

    ketqua=$(tim_theo_cot "$cot" "$tukhoa")
    if [ -z "$ketqua" ]; then
        echo "Khong tim thay CD nao co $truong chua \"$tukhoa\""
    else
        echo "Tim thay $(echo "$ketqua" | wc -l) CD:"
        in_tieude_bang
        echo "$ketqua" | in_dong_cd
    fi
    tam_dung
}

# e. Tìm kiếm CD theo thể loại (cột 4 của cd.txt)
tim_theloai() {
    tim_va_in 4 "TIM CD THEO THE LOAI" "the loai"
}

# f. Tìm kiếm CD theo tác giả (cột 3 của cd.txt)
tim_tacgia() {
    tim_va_in 3 "TIM CD THEO TAC GIA" "tac gia"
}

# ---------------------------------------------------------------------
# tim_baihat: g. Tìm CD theo tên bài hát.
# In các CD có ít nhất 1 bài khớp từ khóa, dưới mỗi CD in các bài khớp.
# Một bài có thể nằm trong nhiều CD, khi đó in đủ tất cả các CD.
# Trả về  : 1 nếu chưa có bài hát nào hoặc người dùng bấm Ctrl+D
# ---------------------------------------------------------------------
tim_baihat() {
    local tukhoa baikhop dsma ma dong
    echo "========== TIM CD THEO TEN BAI HAT =========="
    if [ ! -s "$CT_FILE" ]; then
        echo "Chua co thong tin bai hat nao"
        tam_dung
        return 1
    fi
    tukhoa=$(nhap_chuoi "Nhap ten bai hat can tim") || return 1

    # Bước 1: Lọc các bài hát có tên (cột 3 của chitiet.txt) chứa từ khóa.
    baikhop=$(awk -F'|' -v k="$tukhoa" 'index(tolower($3), tolower(k))' "$CT_FILE")
    if [ -z "$baikhop" ]; then
        echo "Khong tim thay bai hat nao chua \"$tukhoa\""
        tam_dung
        return
    fi

    # Bước 2: Lấy danh sách mã CD (cột 1) chứa các bài đó.
    # Một CD có thể có nhiều bài khớp, sort -u bỏ các mã trùng.
    dsma=$(echo "$baikhop" | cut -d'|' -f1 | sort -u)

    # Bước 3: Với từng CD: in thông tin CD, rồi in các bài khớp của CD đó.
    echo "Tim thay $(echo "$dsma" | wc -l) CD:"
    in_tieude_bang
    echo "$dsma" | while read -r ma; do
        # So sánh bằng ($1==m) để lấy đúng CD, không khớp nhầm mã khác.
        dong=$(awk -F'|' -v m="$ma" '$1==m' "$CD_FILE")
        # Bỏ qua nếu bài hát thuộc 1 CD không còn trong cd.txt.
        [ -z "$dong" ] && continue
        echo "$dong" | in_dong_cd
        echo "$baikhop" | awk -F'|' -v m="$ma" '$1==m {printf "       -> Bai %s: %s (%s)\n", $2, $3, $4}'
    done
    tam_dung
}

# =====================================================================
# Chức năng: h. Bán CD
#            i. In hóa đơn bán hàng
# Các hàm:
#   ban_cd     - lập 1 hóa đơn, bán 1 hoặc nhiều CD, trừ tồn kho
#   in_hoadon  - in hóa đơn theo mã (Enter: in hóa đơn mới nhất)
# Dữ liệu dùng: $CD_FILE (đọc, và ghi khi trừ tồn kho)
#               $HD_FILE (ghi khi bán, đọc khi in)
# Mỗi dòng của hoadon.txt là 1 mặt hàng của 1 hóa đơn:
#   MaHD|NgayGio|MaCD|TenCD|SoLuong|DonGia|ThanhTien
# Lưu cả TenCD và DonGia tại lúc bán, để sau này đổi giá CD thì
# hóa đơn cũ vẫn in đúng.
# =====================================================================

# ---------------------------------------------------------------------
# ban_cd: h. Bán CD. Mỗi lần gọi tạo 1 hóa đơn, khách mua được nhiều CD.
# Với mỗi CD: kiểm tra mã, kiểm tra tồn kho, trừ tồn, ghi 1 dòng hóa đơn.
# Bán xong thì in hóa đơn vừa tạo. Không bán được CD nào thì không tạo
# hóa đơn.
# Trả về  : 1 nếu chưa có CD nào để bán
# ---------------------------------------------------------------------
ban_cd() {
    local mahd ngaygio ma dong ten gia ton sl thanhtien tiep somathang=0
    echo "========== BAN CD =========="
    if [ ! -s "$CD_FILE" ]; then
        echo "Chua co CD nao"
        tam_dung
        return 1
    fi

    # Bước 1: Tạo mã hóa đơn từ ngày giờ hiện tại (vd. HD20261116153000).
    mahd="HD$(date +%Y%m%d%H%M%S)"
    # Nếu mã đã có (2 hóa đơn trong cùng 1 giây) thì chờ 1 giây rồi tạo lại.
    while grep -q "^$mahd|" "$HD_FILE"; do
        sleep 1
        mahd="HD$(date +%Y%m%d%H%M%S)"
    done
    ngaygio=$(date "+%d/%m/%Y %H:%M")
    echo "Ma hoa don: $mahd"

    # Bước 2: Lặp bán từng CD tới khi khách không mua thêm.
    tiep="y"
    while [ "$tiep" = "y" ] || [ "$tiep" = "Y" ]; do
        # Để trống (Enter) hoặc bấm Ctrl+D thì kết thúc bán.
        read -rp "Ma CD (Enter de ket thuc): " ma || break
        [ -z "$ma" ] && break

        # Lấy dòng có cột 1 đúng bằng mã CD (so sánh bằng, không khớp một phần).
        dong=$(awk -F'|' -v m="$ma" '$1==m' "$CD_FILE")
        if [ -z "$dong" ]; then
            echo "Khong tim thay CD $ma"
            continue
        fi
        # Tách các cột cần dùng: 2 = tên CD, 6 = giá, 7 = số lượng tồn.
        ten=$(echo "$dong" | cut -d'|' -f2)
        gia=$(echo "$dong" | cut -d'|' -f6)
        ton=$(echo "$dong" | cut -d'|' -f7)
        if [ "$ton" -le 0 ]; then
            echo "CD $ma ($ten) da het hang"
            continue
        fi
        echo "CD: $ten - Gia: $(dinh_dang_tien "$gia") - Con: $ton"

        # Nhập số lượng tới khi hợp lệ: là số nguyên dương (nhap_so tự kiểm tra)
        # và không vượt quá tồn kho.
        # Ctrl+D: "break 2" thoát cả vòng này lẫn vòng bán CD bên ngoài.
        while true; do
            sl=$(nhap_so "So luong") || break 2
            [ "$sl" -le "$ton" ] && break
            echo "Khong du hang, chi con $ton"
        done

        thanhtien=$((sl * gia))

        # Trừ tồn kho: awk trừ cột 7 ở dòng có mã = $ma, các dòng khác giữ nguyên.
        #   OFS='|' : ghép lại các cột của dòng vừa sửa bằng dấu |
        #   1       : điều kiện luôn đúng, nên awk in ra mọi dòng
        # awk không sửa thẳng được file, nên ghi ra file tạm rồi đổi tên đè lên.
        awk -F'|' -v OFS='|' -v m="$ma" -v sl="$sl" '$1==m {$7-=sl} 1' "$CD_FILE" > "$CD_FILE.tmp" \
            && mv "$CD_FILE.tmp" "$CD_FILE"

        # Ghi mặt hàng này vào hóa đơn.
        echo "$mahd|$ngaygio|$ma|$ten|$sl|$gia|$thanhtien" >> "$HD_FILE"
        somathang=$((somathang + 1))
        echo "Da them: $ten x $sl = $(dinh_dang_tien "$thanhtien")"

        read -rp "Mua them CD khac? (y/n): " tiep || break
    done

    # Bước 3: In hóa đơn vừa tạo. Không bán được gì thì không có hóa đơn.
    if [ "$somathang" -eq 0 ]; then
        echo "Khong ban CD nao, khong tao hoa don"
        tam_dung
        return
    fi
    echo
    in_hoadon "$mahd"
}

# ---------------------------------------------------------------------
# in_hoadon: i. In 1 hóa đơn bán hàng.
# Tham số : $1 = mã hóa đơn (không bắt buộc). Nếu không truyền thì hỏi
#           người dùng; người dùng bấm Enter thì in hóa đơn mới nhất.
# Trả về  : 1 nếu chưa có hóa đơn nào hoặc không tìm thấy mã
# ---------------------------------------------------------------------
in_hoadon() {
    local mahd=$1 cacdong ngaygio hd ngay ma ten sl gia thanhtien tong=0
    if [ ! -s "$HD_FILE" ]; then
        echo "Chua co hoa don nao"
        tam_dung
        return 1
    fi
    if [ -z "$mahd" ]; then
        echo "========== IN HOA DON =========="
        read -rp "Nhap Ma HD (Enter de in hoa don moi nhat): " mahd
        # Hóa đơn mới nhất nằm ở dòng cuối file (dòng được ghi sau cùng).
        [ -z "$mahd" ] && mahd=$(tail -1 "$HD_FILE" | cut -d'|' -f1)
    fi

    # Lấy tất cả các mặt hàng (các dòng) thuộc hóa đơn này.
    cacdong=$(awk -F'|' -v m="$mahd" '$1==m' "$HD_FILE")
    if [ -z "$cacdong" ]; then
        echo "Khong tim thay hoa don $mahd"
        tam_dung
        return 1
    fi
    # Mọi dòng của 1 hóa đơn có cùng ngày giờ, lấy ở dòng đầu tiên.
    ngaygio=$(echo "$cacdong" | head -1 | cut -d'|' -f2)

    echo "=================== HOA DON BAN HANG ===================="
    echo "Ma HD: $mahd   Ngay: $ngaygio"
    echo "---------------------------------------------------------"
    # Cột tiền ở dòng dữ liệu rộng hơn tiêu đề 1 ô vì chữ "đ" chiếm 2 byte.
    printf "%-25s %4s %12s %13s\n" "Ten CD" "SL" "Don gia" "Thanh tien"

    # Đọc từng mặt hàng: in 1 dòng và cộng dồn tổng tiền.
    # Dùng "done < <(...)" chứ không dùng "echo ... | while": với ống dẫn,
    # vòng while chạy trong shell con nên biến tong cộng xong sẽ bị mất.
    while IFS='|' read -r hd ngay ma ten sl gia thanhtien; do
        printf "%-25s %4s %13s %14s\n" "$ten" "$sl" "$(dinh_dang_tien "$gia")" "$(dinh_dang_tien "$thanhtien")"
        tong=$((tong + thanhtien))
    done < <(echo "$cacdong")

    echo "---------------------------------------------------------"
    printf "%-43s %14s\n" "TONG CONG:" "$(dinh_dang_tien "$tong")"
    echo "========================================================="
    tam_dung
}

# =====================================================================
# Menu chinh, j. Thoat chuong trinh
# =====================================================================

cd "$(dirname "$0")" || exit 1

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
