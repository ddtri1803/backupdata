@echo off
setlocal

:: **Script**: Batch (Windows) Phục hồi database sau khi XAMPP báo: *Error: MySQL shutdown unexpectedly.*
:: **Lưu Ý**: Thay đổi các biến dưới đây cho phù hợp với môi trường của bạn.
:: Các bước phải làm:
:: Tạo Tệp Mật Khẩu: Tạo một tệp chứa mật khẩu MySQL của bạn. Ví dụ:
:: echo your_mysql_password > C:\path\to\password_file.txt
:: chạy recover_mysql.bat
:: check: /path/to/recovery.log
:: Cập nhật các biến sau theo hệ thống của bạn
:: Sao Lưu Trước: Trước khi chạy script, sao lưu các tệp FRM và IBD gốc và các dữ liệu quan trọng khác để tránh mất mát dữ liệu.
set MYSQL_USER=root
set MYSQL_PASSWORD_FILE=C:\path\to\password_file.txt
set DATABASE_NAME=your_database_name
set FRM_DIR=C:\path\to\frm\files
set IBD_FILE=C:\path\to\ibd\file.ibd
set TABLE_NAME=your_table_name
set LOG_FILE=C:\path\to\recovery.log

:: Đọc mật khẩu từ tệp an toàn
if not exist "%MYSQL_PASSWORD_FILE%" (
    echo Tệp mật khẩu không tồn tại! >> "%LOG_FILE%"
    exit /b 1
)
set /p MYSQL_PASSWORD=<"%MYSQL_PASSWORD_FILE%"

:: Tạo nhật ký
echo Bắt đầu quá trình khôi phục: %DATE% %TIME% >> "%LOG_FILE%"

:: Bước 1: Tạo cơ sở dữ liệu mới
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "CREATE DATABASE IF NOT EXISTS %DATABASE_NAME%;" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi tạo cơ sở dữ liệu. >> "%LOG_FILE%"
    exit /b 1
)
echo Tạo cơ sở dữ liệu thành công. >> "%LOG_FILE%"

:: Bước 2: Tạo bảng từ các tệp .FRM
mysqlfrm --diagnostic "%FRM_DIR%" > table_definitions.sql
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi trích xuất cấu trúc bảng. >> "%LOG_FILE%"
    exit /b 1
)
echo Trích xuất cấu trúc bảng thành công. >> "%LOG_FILE%"

:: Tạo bảng trong cơ sở dữ liệu mới
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% %DATABASE_NAME% < table_definitions.sql
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi tạo bảng. >> "%LOG_FILE%"
    exit /b 1
)
echo Tạo bảng thành công trong cơ sở dữ liệu mới. >> "%LOG_FILE%"

:: Bước 3: Xóa tệp .IBD mới tạo nếu có
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "USE %DATABASE_NAME%; ALTER TABLE %TABLE_NAME% DISCARD TABLESPACE;" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi xóa tệp .IBD. >> "%LOG_FILE%"
    exit /b 1
)
echo Xóa tệp .IBD thành công. >> "%LOG_FILE%"

:: Bước 4: Sao chép tệp .IBD gốc vào thư mục cơ sở dữ liệu
copy "%IBD_FILE%" "C:\ProgramData\MySQL\MySQL Server 8.0\Data\%DATABASE_NAME%\" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi sao chép tệp .IBD. >> "%LOG_FILE%"
    exit /b 1
)
echo Sao chép tệp .IBD thành công. >> "%LOG_FILE%"

:: Bước 5: Nhập lại tablespace vào bảng
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "USE %DATABASE_NAME%; ALTER TABLE %TABLE_NAME% IMPORT TABLESPACE;" >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo Lỗi khi nhập lại tablespace. >> "%LOG_FILE%"
    exit /b 1
)
echo Nhập lại tablespace thành công. >> "%LOG_FILE%"

echo Quá trình khôi phục hoàn tất! >> "%LOG_FILE%"
endlocal
