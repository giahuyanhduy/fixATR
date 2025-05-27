#!/bin/bash

# Script tự động thay thế file /opt/autorun và tải check.sh trên Ubuntu

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script với quyền sudo."
    exit 1
fi

# Đường dẫn file autorun
AUTORUN_FILE="/opt/autorun"
BACKUP_FILE="/opt/autorun_$(date +%Y%m%d_%H%M%S).bak"

# Sao lưu file autorun hiện tại
if [ -f "$AUTORUN_FILE" ]; then
    echo "Sao lưu file $AUTORUN_FILE thành $BACKUP_FILE"
    cp "$AUTORUN_FILE" "$BACKUP_FILE"
else
    echo "File $AUTORUN_FILE không tồn tại, tạo mới."
fi

# Trích xuất số cổng từ dòng ssh (4 hoặc 5 chữ số)
PORT="12903" # Mặc định nếu không tìm thấy
if [ -f "$AUTORUN_FILE" ]; then
    PORT=$(grep -oP 'ssh\s+-.*-R\s+\K[0-9]{4,5}(?=:localhost:22)' "$AUTORUN_FILE" || echo "12903")
fi
echo "Sử dụng cổng: $PORT"

# Kiểm tra và tạo thư mục /home/giang/Phase_3
if [ ! -d "/home/giang/Phase_3" ]; then
    echo "Thư mục /home/giang/Phase_3 không tồn tại, đang xử lý..."
    # Tạo thư mục /home/giang nếu chưa có
    if [ ! -d "/home/giang" ]; then
        echo "Tạo thư mục /home/giang"
        mkdir -p /home/giang
    fi
    # Di chuyển Phase_3 vào /home/giang (giả sử Phase_3 nằm ở /home)
    if [ -d "/home/Phase_3" ]; then
        echo "Di chuyển Phase_3 vào /home/giang"
        mv /home/Phase_3 /home/giang/Phase_3
    else
        echo "Không tìm thấy thư mục Phase_3 để di chuyển, vui lòng kiểm tra."
        exit 1
    fi
else
    echo "Thư mục /home/giang/Phase_3 đã tồn tại."
fi

# Tải file check.sh từ GitHub và cấp quyền thực thi
CHECK_URL="https://raw.githubusercontent.com/giahuyanhduy/fixATR/main/check.sh"
CHECK_FILE="/opt/check.sh"
echo "Tải file check.sh từ $CHECK_URL"
if curl -s -o "$CHECK_FILE" "$CHECK_URL"; then
    echo "Đã tải $CHECK_FILE"
    chmod +x "$CHECK_FILE"
    echo "Đã cấp quyền thực thi cho $CHECK_FILE"
else
    echo "Lỗi: Không thể tải file check.sh từ $CHECK_URL"
    exit 1
fi

# Ghi nội dung mới vào /opt/autorun
echo "Ghi nội dung mới vào $AUTORUN_FILE"
cat > "$AUTORUN_FILE" << EOF
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

sleep 25
echo "\$(date): START" >> /opt/log.log
/opt/check.sh

#date -s "\$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"

find / -type f -mtime +3 -name '*.log' -execdir rm -- '{}' +
find / -type f -mtime +3 -name '*.pid' -execdir rm -- '{}' +
find / -type f -name '*.log' -size +10000k -execdir rm -- '{}' + &

sshpass -p "remote2@gmail.com" ssh -v -nNT -R ${PORT}:localhost:22 remote@14.225.74.7&

cd /home/giang/Phase_3
MAX_PUMP=355 forever start app.js&
EOF

# Phân quyền cho file autorun
chmod +x "$AUTORUN_FILE"
echo "Đã cập nhật $AUTORUN_FILE với cổng $PORT và phân quyền thực thi."

# Thông báo hoàn tất
echo "Script hoàn tất. File autorun và check.sh đã được cập nhật."
