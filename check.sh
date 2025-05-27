#!/bin/bash

#wget -q --tries=10 --timeout=20 --spider http://google.com
#if [ $? -eq 0 ]; then
#        echo "Online."
#else
#        echo "Offline ..."
#fi


#TEST=$(ping 8.8.8.8 -c4)

#if [[ "$TEST" == *"4 received, 0%"* ]]; then
#    echo "Internet: OK"
#else
#    echo "!!! Internet lost connection !!!"
#	/sbin/shutdown -r +1
#fi
#echo "$(date): START" >> /opt/log.log

find / -type f -name '*.log' -size +10000k -execdir rm -- '{}' + &

MAX_RETRIES=10
COUNT=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    # Lấy thời gian từ Google bằng cách gửi yêu cầu HEAD đến google.com
    TIME_STR=$(curl -sI --connect-timeout 5 google.com | grep -i "^date:" | awk '{print $3, $4, $5, $6, $7}')
    
    if [ -n "$TIME_STR" ]; then
        echo "Lấy thời gian từ Google thành công: $TIME_STR"
        
        # Chuyển đổi chuỗi thời gian thành định dạng chuẩn
        DATE_CMD="$(date -d "$TIME_STR" '+%Y-%m-%d %H:%M:%S')"
        
        # Đặt thời gian hệ thống (yêu cầu quyền root)
        date -s "$DATE_CMD"
        
        echo "Thời gian hệ thống đã được cập nhật!"

		#echo "$(date): UPDATE" >> /opt/log.log

        break
    else
        echo "Lấy thời gian thất bại, thử lại... ($((COUNT+1))/$MAX_RETRIES)"
        COUNT=$((COUNT+1))
        sleep 6
    fi

done

if [ $COUNT -eq $MAX_RETRIES ]; then
	echo "$(date): ***REBOOT***" >> /opt/log.log
    echo "Không thể lấy thời gian từ Google sau $MAX_RETRIES lần thử, khởi động lại hệ thống..."
    reboot &
	/sbin/shutdown -r +5
fi

#TEST=$(ping 8.8.8.8 -c4)

#while [[ "$TEST" == *"4 received, 0%"* ]]; do
#	echo "no net"
#	sleep 10
#done
