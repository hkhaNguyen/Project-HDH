#!/bin/bash
# =====================================================================
# File: timkiem.sh
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
