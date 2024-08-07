#!/bin/bash

# **Script**: Script Shell (Linux/Mac) Phục hồi database sau khi XAMPP báo: *Error: MySQL shutdown unexpectedly.*
# **Lưu Ý**: Thay đổi các biến dưới đây cho phù hợp với môi trường của bạn.
# các bước phải làm
# Tạo Tệp Mật Khẩu: Tạo một tệp chứa mật khẩu MySQL của bạn. Ví dụ:
# echo "your_mysql_password" > /path/to/password_file
# chmod +x /path/to/recover_mysql.sh
# ./recover_mysql.sh
# check: /path/to/recovery.log
# Cập nhật các biến sau theo hệ thống của bạn
MYSQL_USER="root"
MYSQL_PASSWORD_FILE="/path/to/password_file"
DATABASE_NAME="your_database_name"
FRM_DIR="/path/to/frm/files"
IBD_FILE="/path/to/ibd/file.ibd"
TABLE_NAME="your_table_name"
LOG_FILE="/path/to/recovery.log"

# Đọc mật khẩu từ tệp an toàn
if [ ! -f "$MYSQL_PASSWORD_FILE" ]; then
  echo "Tệp mật khẩu không tồn tại!" | tee -a "$LOG_FILE"
  exit 1
fi
MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")

# Đặt quyền cho tệp mật khẩu để chỉ người dùng hiện tại có thể đọc
chmod 600 "$MYSQL_PASSWORD_FILE"

echo "Bắt đầu quá trình khôi phục: $(date)" | tee -a "$LOG_FILE"

# Bước 1: Tạo cơ sở dữ liệu mới
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"; then
  echo "Tạo cơ sở dữ liệu thành công." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi tạo cơ sở dữ liệu." | tee -a "$LOG_FILE"
  exit 1
fi

# Bước 2: Tạo bảng từ các tệp .FRM
if mysqlfrm --diagnostic "$FRM_DIR" > table_definitions.sql; then
  echo "Trích xuất cấu trúc bảng thành công." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi trích xuất cấu trúc bảng." | tee -a "$LOG_FILE"
  exit 1
fi

# Tạo bảng trong cơ sở dữ liệu mới
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE_NAME" < table_definitions.sql; then
  echo "Tạo bảng thành công trong cơ sở dữ liệu mới." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi tạo bảng." | tee -a "$LOG_FILE"
  exit 1
fi

# Bước 3: Xóa tệp .IBD mới tạo nếu có
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $DATABASE_NAME; ALTER TABLE $TABLE_NAME DISCARD TABLESPACE;" 2>> "$LOG_FILE"; then
  echo "Xóa tệp .IBD thành công." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi xóa tệp .IBD." | tee -a "$LOG_FILE"
  exit 1
fi

# Bước 4: Sao chép tệp .IBD gốc vào thư mục cơ sở dữ liệu
if cp "$IBD_FILE" "/var/lib/mysql/$DATABASE_NAME/"; then
  echo "Sao chép tệp .IBD thành công." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi sao chép tệp .IBD." | tee -a "$LOG_FILE"
  exit 1
fi

# Bước 5: Nhập lại tablespace vào bảng
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $DATABASE_NAME; ALTER TABLE $TABLE_NAME IMPORT TABLESPACE;" 2>> "$LOG_FILE"; then
  echo "Nhập lại tablespace thành công." | tee -a "$LOG_FILE"
else
  echo "Lỗi khi nhập lại tablespace." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Quá trình khôi phục hoàn tất!" | tee -a "$LOG_FILE"
