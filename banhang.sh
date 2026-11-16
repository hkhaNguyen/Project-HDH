#!/bin/bash
# =====================================================================
# File: banhang.sh
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
