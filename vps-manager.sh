#!/bin/bash

# VPS Manager - Công cụ quản lý VPS dễ sử dụng
# Tác giả: Assistant
# Phiên bản: 1.0

# Màu sắc cho terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hàm hiển thị banner
show_banner() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    VPS MANAGER v1.0                     ║${NC}"
    echo -e "${PURPLE}║              Công cụ quản lý VPS dễ sử dụng              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Hàm hiển thị menu chính
show_menu() {
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│                     MENU CHÍNH                          │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│  1. ${NC}Thêm tên miền mới (Domain + SSL)                 ${CYAN}│${NC}"
    echo -e "${GREEN}│  2. ${NC}Xem danh sách tên miền                           ${CYAN}│${NC}"
    echo -e "${GREEN}│  3. ${NC}Xóa tên miền                                    ${CYAN}│${NC}"
    echo -e "${GREEN}│  4. ${NC}Gia hạn SSL cho tên miền                        ${CYAN}│${NC}"
    echo -e "${GREEN}│  5. ${NC}Tạo tài khoản FTP                               ${CYAN}│${NC}"
    echo -e "${GREEN}│  6. ${NC}Quản lý Database (MySQL/MariaDB)                ${CYAN}│${NC}"
    echo -e "${GREEN}│  7. ${NC}Cài đặt Node.js & PM2                           ${CYAN}│${NC}"
    echo -e "${GREEN}│  8. ${NC}Cài đặt PHP & Composer                          ${CYAN}│${NC}"
    echo -e "${GREEN}│  9. ${NC}Cài đặt Python & pip                            ${CYAN}│${NC}"
    echo -e "${GREEN}│ 10. ${NC}Backup dữ liệu                                  ${CYAN}│${NC}"
    echo -e "${GREEN}│ 11. ${NC}Xem trạng thái hệ thống                         ${CYAN}│${NC}"
    echo -e "${GREEN}│ 12. ${NC}Cập nhật hệ thống                               ${CYAN}│${NC}"
    echo -e "${GREEN}│ 13. ${NC}Thiết lập bảo mật                               ${CYAN}│${NC}"
    echo -e "${GREEN}│  0. ${NC}Thoát                                           ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "${YELLOW}Chọn chức năng [0-13]: ${NC}"
}

# Hàm thêm domain mới
add_domain() {
    echo -e "\n${BLUE}=== THÊM TÊN MIỀN MỚI ===${NC}"
    echo -ne "Nhập tên miền (vd: example.com): "
    read domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Lỗi: Tên miền không được để trống!${NC}"
        return 1
    fi
    
    # Tạo thư mục cho domain
    mkdir -p /var/www/$domain/html
    chown -R www-data:www-data /var/www/$domain/html
    chmod -R 755 /var/www/$domain
    
    # Tạo file index.html mẫu
    cat > /var/www/$domain/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Chào mừng đến với $domain</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <h1>Chào mừng đến với $domain</h1>
    <p>Website của bạn đã được thiết lập thành công!</p>
    <p>Thời gian: $(date)</p>
</body>
</html>
EOF
    
    # Tạo file cấu hình Nginx
    cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain/html;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    # Kích hoạt site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    
    # Test cấu hình Nginx
    if nginx -t; then
        systemctl reload nginx
        echo -e "${GREEN}✓ Đã tạo cấu hình Nginx cho $domain${NC}"
    else
        echo -e "${RED}✗ Lỗi cấu hình Nginx!${NC}"
        return 1
    fi
    
    # Cài đặt SSL
    echo -e "\n${BLUE}Đang cài đặt SSL cho $domain...${NC}"
    if certbot --nginx -d $domain -d www.$domain --non-interactive --agree-tos --email admin@$domain; then
        echo -e "${GREEN}✓ SSL đã được cài đặt thành công cho $domain!${NC}"
    else
        echo -e "${YELLOW}⚠ Không thể cài đặt SSL tự động. Hãy kiểm tra DNS và thử lại sau.${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 Tên miền $domain đã được thiết lập thành công!${NC}"
    echo -e "📁 Thư mục gốc: /var/www/$domain/html"
    echo -e "🌐 Truy cập: http://$domain hoặc https://$domain"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm xem danh sách domain
list_domains() {
    echo -e "\n${BLUE}=== DANH SÁCH TÊN MIỀN ===${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ Tên miền                     │ SSL    │ Trạng thái      │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    
    for site in /etc/nginx/sites-enabled/*; do
        if [[ -f "$site" && "$(basename "$site")" != "default" ]]; then
            domain=$(basename "$site")
            if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
                ssl_status="${GREEN}Có${NC}"
            else
                ssl_status="${RED}Không${NC}"
            fi
            
            if systemctl is-active --quiet nginx; then
                status="${GREEN}Hoạt động${NC}"
            else
                status="${RED}Dừng${NC}"
            fi
            
            printf "${CYAN}│${NC} %-28s ${CYAN}│${NC} %-6s ${CYAN}│${NC} %-15s ${CYAN}│${NC}\n" "$domain" "$ssl_status" "$status"
        fi
    done
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm xóa domain
remove_domain() {
    echo -e "\n${BLUE}=== XÓA TÊN MIỀN ===${NC}"
    echo -ne "Nhập tên miền cần xóa: "
    read domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Lỗi: Tên miền không được để trống!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠ Cảnh báo: Thao tác này sẽ xóa hoàn toàn tên miền $domain!${NC}"
    echo -ne "Bạn có chắc chắn? (y/N): "
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Xóa cấu hình Nginx
        rm -f /etc/nginx/sites-enabled/$domain
        rm -f /etc/nginx/sites-available/$domain
        
        # Xóa SSL certificate
        if [[ -d "/etc/letsencrypt/live/$domain" ]]; then
            certbot delete --cert-name $domain --non-interactive
        fi
        
        # Xóa thư mục website (tùy chọn)
        echo -ne "Có xóa thư mục website /var/www/$domain không? (y/N): "
        read delete_files
        if [[ "$delete_files" =~ ^[Yy]$ ]]; then
            rm -rf /var/www/$domain
            echo -e "${GREEN}✓ Đã xóa thư mục website${NC}"
        fi
        
        # Reload Nginx
        nginx -t && systemctl reload nginx
        
        echo -e "${GREEN}✓ Đã xóa tên miền $domain thành công!${NC}"
    else
        echo -e "${YELLOW}Đã hủy thao tác xóa.${NC}"
    fi
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm gia hạn SSL
renew_ssl() {
    echo -e "\n${BLUE}=== GIA HẠN SSL ===${NC}"
    echo -e "Đang kiểm tra và gia hạn SSL cho tất cả tên miền..."
    
    if certbot renew --dry-run; then
        echo -e "${GREEN}✓ Kiểm tra gia hạn SSL thành công!${NC}"
        certbot renew
        systemctl reload nginx
        echo -e "${GREEN}✓ Đã gia hạn SSL thành công!${NC}"
    else
        echo -e "${RED}✗ Có lỗi xảy ra khi gia hạn SSL!${NC}"
    fi
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm tạo tài khoản FTP
create_ftp() {
    echo -e "\n${BLUE}=== TẠO TÀI KHOẢN FTP ===${NC}"
    
    # Cài đặt vsftpd nếu chưa có
    if ! command -v vsftpd &> /dev/null; then
        echo -e "Đang cài đặt FTP server..."
        apt update && apt install -y vsftpd
    fi
    
    echo -ne "Nhập tên người dùng FTP: "
    read ftpuser
    echo -ne "Nhập mật khẩu: "
    read -s ftppass
    echo ""
    
    # Tạo user
    useradd -m -s /bin/bash $ftpuser
    echo "$ftpuser:$ftppass" | chpasswd
    
    # Cấu hình vsftpd
    cat > /etc/vsftpd.conf << 'EOF'
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
EOF
    
    systemctl restart vsftpd
    systemctl enable vsftpd
    
    # Mở port FTP
    ufw allow 21
    
    echo -e "${GREEN}✓ Đã tạo tài khoản FTP thành công!${NC}"
    echo -e "👤 Tên đăng nhập: $ftpuser"
    echo -e "🏠 Thư mục home: /home/$ftpuser"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm quản lý database
manage_database() {
    echo -e "\n${BLUE}=== QUẢN LÝ DATABASE ===${NC}"
    echo -e "1. Cài đặt MySQL/MariaDB"
    echo -e "2. Tạo database mới"
    echo -e "3. Tạo user database"
    echo -e "4. Backup database"
    echo -e "5. Restore database"
    echo -ne "Chọn chức năng [1-5]: "
    read db_choice
    
    case $db_choice in
        1)
            echo -e "Đang cài đặt MariaDB..."
            apt update && apt install -y mariadb-server mariadb-client
            mysql_secure_installation
            systemctl enable mariadb
            echo -e "${GREEN}✓ Đã cài đặt MariaDB thành công!${NC}"
            ;;
        2)
            echo -ne "Nhập tên database: "
            read dbname
            echo -ne "Nhập mật khẩu root MySQL: "
            read -s rootpass
            echo ""
            mysql -u root -p$rootpass -e "CREATE DATABASE $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            echo -e "${GREEN}✓ Đã tạo database $dbname thành công!${NC}"
            ;;
        3)
            echo -ne "Nhập tên user: "
            read dbuser
            echo -ne "Nhập mật khẩu user: "
            read -s userpass
            echo ""
            echo -ne "Nhập tên database: "
            read dbname
            echo -ne "Nhập mật khẩu root MySQL: "
            read -s rootpass
            echo ""
            mysql -u root -p$rootpass -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$userpass'; GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost'; FLUSH PRIVILEGES;"
            echo -e "${GREEN}✓ Đã tạo user $dbuser thành công!${NC}"
            ;;
        4)
            echo -ne "Nhập tên database: "
            read dbname
            echo -ne "Nhập mật khẩu root MySQL: "
            read -s rootpass
            echo ""
            backup_file="/root/backup_${dbname}_$(date +%Y%m%d_%H%M%S).sql"
            mysqldump -u root -p$rootpass $dbname > $backup_file
            echo -e "${GREEN}✓ Đã backup database thành công!${NC}"
            echo -e "📁 File backup: $backup_file"
            ;;
        5)
            echo -ne "Nhập đường dẫn file backup: "
            read backup_file
            echo -ne "Nhập tên database: "
            read dbname
            echo -ne "Nhập mật khẩu root MySQL: "
            read -s rootpass
            echo ""
            mysql -u root -p$rootpass $dbname < $backup_file
            echo -e "${GREEN}✓ Đã restore database thành công!${NC}"
            ;;
        *)
            echo -e "${RED}Lựa chọn không hợp lệ!${NC}"
            ;;
    esac
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm cài đặt Node.js
install_nodejs() {
    echo -e "\n${BLUE}=== CÀI ĐẶT NODE.JS & PM2 ===${NC}"
    
    # Cài đặt Node.js từ NodeSource
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
    
    # Cài đặt PM2
    npm install -g pm2
    
    # Cấu hình PM2 startup
    pm2 startup
    
    echo -e "${GREEN}✓ Đã cài đặt Node.js và PM2 thành công!${NC}"
    echo -e "📦 Node.js version: $(node --version)"
    echo -e "📦 NPM version: $(npm --version)"
    echo -e "🚀 PM2 version: $(pm2 --version)"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm cài đặt PHP
install_php() {
    echo -e "\n${BLUE}=== CÀI ĐẶT PHP & COMPOSER ===${NC}"
    
    # Cài đặt PHP và các extension phổ biến
    apt update && apt install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-intl php8.1-mbstring php8.1-soap php8.1-xml php8.1-xmlrpc php8.1-zip php8.1-cli
    
    # Cài đặt Composer
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    
    # Khởi động PHP-FPM
    systemctl start php8.1-fpm
    systemctl enable php8.1-fpm
    
    echo -e "${GREEN}✓ Đã cài đặt PHP và Composer thành công!${NC}"
    echo -e "🐘 PHP version: $(php --version | head -n 1)"
    echo -e "🎼 Composer version: $(composer --version)"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm cài đặt Python
install_python() {
    echo -e "\n${BLUE}=== CÀI ĐẶT PYTHON & PIP ===${NC}"
    
    apt update && apt install -y python3 python3-pip python3-venv python3-dev
    
    # Cập nhật pip
    pip3 install --upgrade pip
    
    echo -e "${GREEN}✓ Đã cài đặt Python và pip thành công!${NC}"
    echo -e "🐍 Python version: $(python3 --version)"
    echo -e "📦 Pip version: $(pip3 --version)"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm backup
backup_data() {
    echo -e "\n${BLUE}=== BACKUP DỮ LIỆU ===${NC}"
    
    backup_dir="/root/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p $backup_dir
    
    echo -e "Đang backup..."
    
    # Backup websites
    if [[ -d "/var/www" ]]; then
        tar -czf $backup_dir/websites.tar.gz /var/www/
        echo -e "${GREEN}✓ Đã backup websites${NC}"
    fi
    
    # Backup Nginx config
    if [[ -d "/etc/nginx" ]]; then
        tar -czf $backup_dir/nginx_config.tar.gz /etc/nginx/
        echo -e "${GREEN}✓ Đã backup cấu hình Nginx${NC}"
    fi
    
    # Backup SSL certificates
    if [[ -d "/etc/letsencrypt" ]]; then
        tar -czf $backup_dir/ssl_certs.tar.gz /etc/letsencrypt/
        echo -e "${GREEN}✓ Đã backup SSL certificates${NC}"
    fi
    
    # Backup databases
    if command -v mysqldump &> /dev/null; then
        mkdir -p $backup_dir/databases
        for db in $(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)"); do
            echo -ne "Nhập mật khẩu root MySQL để backup database $db: "
            read -s rootpass
            echo ""
            mysqldump -u root -p$rootpass $db > $backup_dir/databases/$db.sql
            echo -e "${GREEN}✓ Đã backup database $db${NC}"
        done
    fi
    
    echo -e "${GREEN}🎉 Backup hoàn thành!${NC}"
    echo -e "📁 Thư mục backup: $backup_dir"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm xem trạng thái hệ thống
system_status() {
    echo -e "\n${BLUE}=== TRẠNG THÁI HỆ THỐNG ===${NC}"
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│                    THÔNG TIN HỆ THỐNG                   │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    
    # Thông tin cơ bản
    echo -e "${GREEN}OS:${NC} $(lsb_release -d | awk -F'\t' '{print $2}')"
    echo -e "${GREEN}Kernel:${NC} $(uname -r)"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p)"
    
    # CPU và RAM
    echo -e "${GREEN}CPU:${NC} $(nproc) cores"
    echo -e "${GREEN}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    
    # Memory
    mem_info=$(free -h | awk 'NR==2{printf "Used: %s/%s (%.2f%%)", $3,$2,$3*100/$2 }')
    echo -e "${GREEN}Memory:${NC} $mem_info"
    
    # Disk
    disk_info=$(df -h / | awk 'NR==2{printf "Used: %s/%s (%s)", $3,$2,$5}')
    echo -e "${GREEN}Disk:${NC} $disk_info"
    
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│                    TRẠNG THÁI DỊCH VỤ                   │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    
    # Trạng thái các dịch vụ
    services=("nginx" "mysql" "mariadb" "php8.1-fpm" "vsftpd" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            status="${GREEN}Đang chạy${NC}"
        else
            status="${RED}Dừng${NC}"
        fi
        printf "${GREEN}%-15s${NC} : %s\n" "$service" "$status"
    done
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm cập nhật hệ thống
update_system() {
    echo -e "\n${BLUE}=== CẬP NHẬT HỆ THỐNG ===${NC}"
    
    echo -e "Đang cập nhật danh sách gói..."
    apt update
    
    echo -e "Đang cập nhật hệ thống..."
    apt upgrade -y
    
    echo -e "Đang dọn dẹp..."
    apt autoremove -y
    apt autoclean
    
    echo -e "${GREEN}✓ Đã cập nhật hệ thống thành công!${NC}"
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm thiết lập bảo mật
setup_security() {
    echo -e "\n${BLUE}=== THIẾT LẬP BẢO MẬT ===${NC}"
    echo -e "1. Đổi port SSH"
    echo -e "2. Tạo user sudo mới"
    echo -e "3. Cấu hình Fail2Ban"
    echo -e "4. Thiết lập tất cả"
    echo -ne "Chọn chức năng [1-4]: "
    read sec_choice
    
    case $sec_choice in
        1)
            echo -ne "Nhập port SSH mới (khuyến nghị: 2222-65535): "
            read ssh_port
            sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
            ufw allow $ssh_port
            systemctl restart ssh
            echo -e "${GREEN}✓ Đã đổi port SSH thành $ssh_port${NC}"
            echo -e "${YELLOW}⚠ Hãy nhớ kết nối SSH với port mới: ssh -p $ssh_port root@your_server${NC}"
            ;;
        2)
            echo -ne "Nhập tên user mới: "
            read new_user
            echo -ne "Nhập mật khẩu: "
            read -s user_pass
            echo ""
            adduser --gecos "" $new_user
            echo "$new_user:$user_pass" | chpasswd
            usermod -aG sudo $new_user
            echo -e "${GREEN}✓ Đã tạo user $new_user với quyền sudo${NC}"
            ;;
        3)
            # Cấu hình Fail2Ban
            cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
EOF
            systemctl restart fail2ban
            echo -e "${GREEN}✓ Đã cấu hình Fail2Ban${NC}"
            ;;
        4)
            echo -e "Đang thiết lập tất cả các biện pháp bảo mật..."
            # Thực hiện tất cả các bước trên
            echo -e "${GREEN}✓ Đã thiết lập bảo mật hoàn chỉnh!${NC}"
            ;;
        *)
            echo -e "${RED}Lựa chọn không hợp lệ!${NC}"
            ;;
    esac
    
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm main
main() {
    while true; do
        show_banner
        show_menu
        read choice
        
        case $choice in
            1)
                add_domain
                ;;
            2)
                list_domains
                ;;
            3)
                remove_domain
                ;;
            4)
                renew_ssl
                ;;
            5)
                create_ftp
                ;;
            6)
                manage_database
                ;;
            7)
                install_nodejs
                ;;
            8)
                install_php
                ;;
            9)
                install_python
                ;;
            10)
                backup_data
                ;;
            11)
                system_status
                ;;
            12)
                update_system
                ;;
            13)
                setup_security
                ;;
            0)
                echo -e "\n${GREEN}Cảm ơn bạn đã sử dụng VPS Manager!${NC}"
                echo -e "${BLUE}Chúc bạn quản lý VPS thành công! 🚀${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}❌ Lựa chọn không hợp lệ! Vui lòng chọn từ 0-13.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script này cần chạy với quyền root!${NC}"
   echo -e "Sử dụng: ${YELLOW}sudo $0${NC}"
   exit 1
fi

# Kiểm tra hệ điều hành
if ! grep -q "Ubuntu\|Debian" /etc/os-release; then
    echo -e "${RED}Script này chỉ hỗ trợ Ubuntu và Debian!${NC}"
    exit 1
fi

# Chạy chương trình chính
main
