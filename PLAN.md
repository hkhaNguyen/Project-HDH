# Kế hoạch: Chương trình tiệm bán đĩa CD (Shell Script)

| Người | Phụ trách |
|---|---|
| **A** | a, b, c, d, j (nhập liệu, hiển thị, menu) |
| **B** | e, f, g, h, i (tìm kiếm, bán hàng, hóa đơn) |

---

## 1. Quy ước chung

### 1.1 Cấu trúc thư mục

```
Project-HDH/
├── cdshop.sh        # menu chính, source các module    (A)
├── common.sh        # đường dẫn data + hàm dùng chung   (A)
├── nhap.sh          # a, b                              (A)
├── hienthi.sh       # c, d                              (A)
├── timkiem.sh       # e, f, g                           (B)
├── banhang.sh       # h, i                              (B)
├── data/
│   ├── cd.txt       # mỗi dòng 1 CD
│   ├── chitiet.txt  # mỗi dòng 1 bài hát của 1 CD
│   └── hoadon.txt   # mỗi dòng 1 mặt hàng trong 1 hóa đơn
└── .gitattributes   # *.sh text eol=lf
```

### 1.2 Định dạng dữ liệu

Dấu phân cách là `|`. Không dùng `-`, vì tên bài hát hay tác giả thường có dấu gạch (vd. "Son Tung M-TP"), làm `awk` cắt sai cột.

**`data/cd.txt`**
```
MaCD|TenCD|TacGia|TheLoai|NamPH|Gia|SoLuong
CD001|Sky Tour|Son Tung M-TP|Pop|2020|150000|10
```

**`data/chitiet.txt`**
```
MaCD|STT|TenBaiHat|ThoiLuong
CD001|1|Chung ta cua hien tai|05:01
```

**`data/hoadon.txt`**
```
MaHD|NgayGio|MaCD|TenCD|SoLuong|DonGia|ThanhTien
HD20261116153000|16/11/2026 15:30|CD001|Sky Tour|2|150000|300000
```

> Dòng tiêu đề ở trên chỉ để giải thích, **không ghi vào file**.
> Hóa đơn lưu cả `TenCD` và `DonGia` tại thời điểm bán, để sau này đổi giá CD thì hóa đơn cũ vẫn in đúng.

### 1.3 Tên hàm

| Chức năng | Hàm | File |
|---|---|---|
| a. Thêm CD | `them_cd` | nhap.sh |
| b. Thêm chi tiết CD | `them_chitiet` | nhap.sh |
| c. Hiển thị ngắn gọn | `hienthi_ngangon` | hienthi.sh |
| d. Hiển thị đầy đủ | `hienthi_daydu` | hienthi.sh |
| e. Tìm theo thể loại | `tim_theloai` | timkiem.sh |
| f. Tìm theo tác giả | `tim_tacgia` | timkiem.sh |
| g. Tìm theo tên bài hát | `tim_baihat` | timkiem.sh |
| h. Bán CD | `ban_cd` | banhang.sh |
| i. In hóa đơn | `in_hoadon [MaHD]` | banhang.sh |

### 1.4 Nội dung `common.sh`

- Biến `CD_FILE`, `CT_FILE`, `HD_FILE` trỏ tới các file trong `data/`.
- `init_data`: tạo thư mục `data/` và các file rỗng nếu chưa có.
- `la_so_duong "$x"`: trả 0 nếu `$x` là số nguyên dương, dùng `[[ $x =~ ^[0-9]+$ ]] && [ "$x" -gt 0 ]`.
- `cd_ton_tai "$ma"`: `grep -q "^$ma|" "$CD_FILE"`.
- `tam_dung`: `read -p "Nhan Enter de tiep tuc..."`.
- `nhap_chuoi "<cau hoi>"`: hỏi lại tới khi nhập chuỗi không rỗng, không có `|`. Dùng: `ten=$(nhap_chuoi "Ten CD") || return 1`.
- `nhap_so "<cau hoi>"`: hỏi lại tới khi nhập số nguyên dương. Dùng: `sl=$(nhap_so "So luong") || return 1`.
- Cả 2 hàm trả 1 khi người dùng bấm Ctrl+D, nên luôn kèm `|| return 1` để thoát khỏi chức năng.
- `dinh_dang_tien <so>`: `150000` thành `150.000đ`. `printf` căn cột theo byte mà `đ` chiếm 2 byte, nên cột tiền ở các dòng dữ liệu phải rộng hơn tiêu đề 1 ô (vd. tiêu đề `%12s`, dòng `%13s`).

### 1.5 Quy ước khác

- Chạy và test trên máy ảo Linux.
- Tiền tính bằng đồng: nhập và lưu số trơn (`20000`), khi in ra cho người dùng xem thì qua `dinh_dang_tien` (`20.000đ`).
- Dữ liệu gõ **không dấu**. `tolower()` của `mawk` (mặc định trên Ubuntu) không xử lý được chữ có dấu.
- Mỗi hàm tự in kết quả, xong thì gọi `tam_dung`.
- File `.sh` dùng kết thúc dòng **LF**, không dùng CRLF.
- MaCD do người dùng nhập, chương trình kiểm tra trùng.
- Một hóa đơn có thể gồm nhiều CD.
- "Chi tiết CD" là danh sách bài hát của CD đó.
- Tìm kiếm khớp một phần, không phân biệt hoa thường.

---

## 2. Người A: Nhập liệu, hiển thị, menu

### a. Thêm CD — `them_cd`
- **Làm gì:** `read` lần lượt MaCD, Tên, Tác giả, Thể loại, Năm, Giá, Số lượng. Kiểm tra hợp lệ rồi `echo "$ma|$ten|...|$sl" >> "$CD_FILE"`.
- **Cần kiểm tra:**
  - Mã bị trùng (`cd_ton_tai`).
  - Trường bỏ trống (`[ -z "$x" ]`).
  - Năm, giá, số lượng không phải số (`la_so_duong`).
  - Chuỗi nhập có ký tự `|`.
- **Test:** thêm CD hợp lệ, thêm trùng mã, nhập giá `abc`.

### b. Thêm thông tin chi tiết CD — `them_chitiet`
- **Làm gì:** nhập MaCD (phải tồn tại). Lặp `while` để nhập từng bài: tên bài, thời lượng `mm:ss`. STT tự tăng từ số bài đã có: `grep -c "^$ma|" "$CT_FILE"` + 1. Sau mỗi bài hỏi "Them bai nua? (y/n)".
- **Cần kiểm tra:** MaCD không tồn tại, tên bài rỗng, thời lượng sai dạng (`[[ $t =~ ^[0-9]{1,2}:[0-5][0-9]$ ]]`).
- **Test:** thêm 3 bài cho 1 CD, rồi chạy lại b cho CD đó và kiểm tra STT chạy tiếp từ 4.

### c. Hiển thị thông tin CD ngắn gọn — `hienthi_ngangon`
- **Làm gì:** in bảng, mỗi CD 1 dòng gồm Mã, Tên, Tác giả, Giá, Tồn. Đọc từng dòng bằng `while IFS='|' read -r ...`, giá in qua `dinh_dang_tien`.
- **Cần kiểm tra:** file rỗng thì báo "Chua co CD nao". Các cột phải thẳng hàng.

### d. Hiển thị thông tin CD đầy đủ — `hienthi_daydu`
- **Làm gì:** hỏi MaCD (Enter để xem tất cả CD). Với mỗi CD: in toàn bộ 7 trường lấy từ `cd.txt`, rồi in tracklist lọc từ `chitiet.txt` bằng `awk -F'|' -v m="$ma" '$1==m'`.
- **Cần kiểm tra:** MaCD không tồn tại, CD chưa có bài hát nào (in "Chua co thong tin chi tiet").

### j. Thoát chương trình và menu chính — `cdshop.sh`
- **Làm gì:**
  ```bash
  #!/bin/bash
  cd "$(dirname "$0")"
  source common.sh; source nhap.sh; source hienthi.sh
  source timkiem.sh; source banhang.sh
  init_data
  while true; do
      clear
      # echo menu a..j
      read -p "Chon: " chon
      case $chon in
          a|A) them_cd ;;
          # ... b..i
          j|J) echo "Tam biet"; exit 0 ;;
          *) echo "Lua chon khong hop le"; tam_dung ;;
      esac
  done
  ```
- **Cần kiểm tra:** nhập chữ hoa, nhập ký tự lạ, nhập rỗng.

---

## 3. Người B: Tìm kiếm, bán hàng, hóa đơn

### e, f. Tìm kiếm CD theo thể loại / tác giả — `tim_theloai`, `tim_tacgia`
- **Làm gì:** dùng 1 hàm chung cho cả e và f:
  ```bash
  tim_theo_cot() {   # $1 = số cột, $2 = từ khóa
      awk -F'|' -v c="$1" -v k="$2" 'index(tolower($c), tolower(k))' "$CD_FILE"
  }
  ```
  `tim_theloai` hỏi từ khóa rồi gọi `tim_theo_cot 4 "$kw"`. `tim_tacgia` làm tương tự với cột 3. Kết quả in theo cùng format bảng như chức năng c.
- **Cần kiểm tra:** từ khóa rỗng, không tìm thấy (báo "Khong tim thay").
- **Test:** tìm `pop` phải ra cả CD có thể loại `Pop`; tìm một phần tên tác giả.

### g. Tìm kiếm CD theo tên bài hát — `tim_baihat`
- **Làm gì:**
  1. Lọc `chitiet.txt` theo cột 3 (tên bài), khớp một phần, không phân biệt hoa thường.
  2. Lấy danh sách MaCD: `cut -d'|' -f1 | sort -u`.
  3. `while read ma` để tra `cd.txt` và in thông tin CD, kèm tên bài khớp.
- **Cần kiểm tra:** 1 bài có trong nhiều CD (phải in đủ các CD), không tìm thấy.

### h. Bán CD — `ban_cd`
- **Làm gì:**
  1. Tạo `MaHD="HD$(date +%Y%m%d%H%M%S)"` và `NgayGio=$(date "+%d/%m/%Y %H:%M")`.
  2. Lặp:
     - Nhập MaCD (phải tồn tại), lấy `TenCD`, `Gia`, `Ton` bằng `awk`.
     - Nhập SL, kiểm tra `la_so_duong` và `SL <= Ton`.
     - `ThanhTien=$((SL * Gia))`.
     - **Trừ tồn kho:**
       ```bash
       awk -F'|' -v OFS='|' -v m="$ma" -v sl="$sl" '$1==m {$7-=sl} 1' "$CD_FILE" > tmp && mv tmp "$CD_FILE"
       ```
     - Ghi 1 dòng vào `hoadon.txt`.
     - Hỏi "Mua them? (y/n)".
  3. Kết thúc thì gọi `in_hoadon "$MaHD"`.
- **Cần kiểm tra:** mã sai, CD hết hàng (tồn = 0), SL = 0, SL vượt tồn, SL không phải số. Người dùng không mua gì thì không tạo hóa đơn rỗng.
- **Test:** bán 2 CD trong 1 hóa đơn, rồi chạy c để thấy tồn kho đã giảm.

### i. In hóa đơn bán hàng — `in_hoadon [MaHD]`
- **Làm gì:** lấy MaHD từ `$1`. Nếu không có thì hỏi người dùng; Enter để lấy hóa đơn mới nhất bằng `tail -1 "$HD_FILE" | cut -d'|' -f1`. In ra:
  ```
  ========== HOA DON BAN HANG ==========
  Ma HD: HD20261116153000   Ngay: 16/11/2026 15:30
  --------------------------------------
  Ten CD               SL      Don gia    Thanh tien
  Sky Tour              2     150.000đ      300.000đ
  --------------------------------------
  TONG CONG:                                300.000đ
  ```
  Đọc các dòng của hóa đơn bằng `while IFS='|' read -r ...`, cộng dồn tổng bằng `$(( ))`, mọi số tiền in qua `dinh_dang_tien`.
- **Cần kiểm tra:** MaHD không tồn tại, file hóa đơn rỗng.
