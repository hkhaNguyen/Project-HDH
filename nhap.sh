#!/bin/bash
# a. Them CD, b. Them thong tin chi tiet CD

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
