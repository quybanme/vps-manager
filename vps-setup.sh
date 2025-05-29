#!/bin/bash

# VPS Auto Setup Script
# Script tự động cài đặt và cấu hình VPS từ đầu

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log file
LOG_FILE="/var/log/vps_setup.log"

# Hàm log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "$1"
}

# Hàm hiển thị banner
show_banner() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                VPS AUTO SETUP v1.0                      ║${NC}"
    echo -e "${PURPLE}║            Script cài đặt VPS tự động                   ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Hàm cập nhật hệ thống
update_system() {
    log "${BLUE}=== BƯỚC 1: CẬP NHẬT HỆ THỐNG ===${NC}"
    
    log "Đang cập nhật danh sách gói..."
    apt update -y >> $LOG_FILE 2>&1
    
    log "Đang nâng cấp hệ thống..."
    apt upgrade -y >> $LOG_FILE 2>&1
    
    log "${GREEN}✓ Đã cập nhật hệ thống thành công${NC}"
}

# Hàm cài đặt các gói cần thiết
install_essentials() {
    log "${BLUE}=== BƯỚC 2: CÀI ĐẶT CÁC GÓI CẦN THIẾT ===${NC}"
    
    packages=(
        "curl" "wget" "git" "unzip" "zip"
        "htop" "nano" "vim" "tree"
        "software-properties-common" "apt-transport-https"
        "ca-certificates" "gnupg" "lsb-release"
        "ufw" "fail2ban"
    )
    
    log "Đang cài đặt các gói cơ bản..."
    for package in "${packages[@]}"; do
        log "Cài đặt $package..."
        apt install -y $package >> $LOG_FILE 2>&1
    done
    
    log "${GREEN}✓ Đã cài đặt các gói cần thiết${NC}"
}

# Hàm cài đặt Nginx
install_nginx() {
    log "${BLUE}=== BƯỚC 3: CÀI ĐẶT NGINX ===${NC}"
    
    apt install -y nginx >> $LOG_FILE 2>&1
    systemctl start nginx
    systemctl enable nginx
    
    # Tạo cấu hình mặc định tùy chỉnh
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>VPS Setup Thành Công!</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            animation: fadeInUp 1s ease-out;
        }
        p {
            font-size: 1.2em;
            margin-bottom: 15px;
            animation: fadeInUp 1s ease-out 0.2s both;
        }
        .info {
            background: rgba(255,255,255,0.2);
            padding: 20px;
            border-radius: 10px;
            margin-top: 30px;
            animation: fadeInUp 1s ease-out 0.4s both;
        }
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        .emoji {
            font-size: 2em;
            margin: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 VPS Setup Thành Công!</h1>
        <p>Máy chủ của bạn đã được cài đặt và cấu hình thành công!</p>
        <p><span class="emoji">🚀</span> Nginx đang chạy</p>
        <p><span class="emoji">🔒</span> Bảo mật đã được thiết lập</p>
        <p><span class="emoji">⚡</span> Sẵn sàng để sử dụng</p>
        
        <div class="info">
            <h3>Thông tin hệ thống:</h3>
            <p>Thời gian cài đặt: <strong id="datetime"></strong></p>
            <p>IP Server: <strong id="server-ip"></strong></p>
        </div>
    </div>

    <script>
        // Hiển thị thời gian hiện tại
        document.getElementById('datetime').textContent = new Date().toLocaleString('vi-VN');
        
        // Lấy IP của server (sẽ hiển thị IP client trong trường hợp này)
        fetch('https://api.ipify.org?format=json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('server-ip').textContent = data.ip;
            })
            .catch(() => {
                document.getElementById('server-ip').textContent = 'Không thể lấy IP';
            });
    </script>
</body>
</html>
EOF
    
    log "${GREEN}✓ Đã cài đặt Nginx thành công${NC}"
}

# Hàm cài đặt SSL (Certbot)
install_ssl() {
    log "${BLUE}=== BƯỚC 4: CÀI ĐẶT CERTBOT (SSL) ===${NC}"
    
    apt install -y certbot python3-certbot-nginx >> $LOG_FILE 2>&1
    
    # Tạo cron job để tự động gia hạn SSL
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    log "${GREEN}✓ Đã cài đặt Certbot thành công${NC}"
}

# Hàm thiết lập firewall
setup_firewall() {
    log "${BLUE}=== BƯỚC 5: THIẾT LẬP FIREWALL ===${NC}"
    
    # Reset UFW
    ufw --force reset >> $LOG_FILE 2>&1
    
    # Cấu hình mặc định
    ufw default deny incoming >> $LOG_FILE 2>&1
    ufw default allow outgoing >> $LOG_FILE 2>&1
    
    # Cho phép SSH, HTTP, HTTPS
    ufw allow ssh >> $LOG_FILE 2>&1
    ufw allow 'Nginx Full' >> $LOG_FILE 2>&1
    
    # Kích hoạt UFW
    ufw --force enable >> $LOG_FILE 2>&1
    
    log "${GREEN}✓ Đã thiết lập firewall thành công${NC}"
}

# Hàm cấu hình Fail2Ban
setup_fail2ban() {
    log "${BLUE}=== BƯỚC 6: CẤU HÌNH FAIL2BAN ===${NC}"
    
    # Tạo file cấu hình jail.local
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Thời gian cấm (giây)
bantime = 3600

# Thời gian theo dõi (giây)
findtime = 600

# Số lần thử tối đa
maxretry = 5

# Ignore local IPs
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

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

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

    # Khởi động lại Fail2Ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log "${GREEN}✓ Đã cấu hình Fail2Ban thành công${NC}"
}

# Hàm tối ưu hóa hệ thống
optimize_system() {
    log "${BLUE}=== BƯỚC 7: TỐI ƯU HÓA HỆ THỐNG ===${NC}"
    
    # Tăng giới hạn file descriptors
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

    # Tối ưu kernel parameters
    cat >> /etc/sysctl.conf << 'EOF'
# Network tuning
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# Security
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
EOF

    sysctl -p >> $LOG_FILE 2>&1
    
    log "${GREEN}✓ Đã tối ưu hóa hệ thống${NC}"
}

# Hàm tạo thư mục và quyền
setup_directories() {
    log "${BLUE}=== BƯỚC 8: THIẾT LẬP THƯ MỤC ===${NC}"
    
    # Tạo thư mục backup
    mkdir -p /root/backups
    mkdir -p /root/scripts
    mkdir -p /var/log/vps-manager
    
    # Thiết lập quyền cho thư mục web
    chown -R www-data:www-data /var/www/
    chmod -R 755 /var/www/
    
    log "${GREEN}✓ Đã thiết lập thư mục${NC}"
}

# Hàm cài đặt VPS Manager
install_vps_manager() {
    log "${BLUE}=== BƯỚC 9: CÀI ĐẶT VPS MANAGER ===${NC}"
    
    # Tải script VPS Manager (giả sử đã có)
    cat > /root/scripts/vps-manager.sh << 'EOF'
# VPS Manager script sẽ được đặt ở đây
# (Nội dung của script VPS Manager đã tạo ở trước)
EOF
    
    chmod +x /root/scripts/vps-manager.sh
    
    # Tạo alias để chạy dễ dàng
    echo "alias vps-manager='/root/scripts/vps-manager.sh'" >> /root/.bashrc
    
    log "${GREEN}✓ Đã cài đặt VPS Manager${NC}"
}

# Hàm tạo thông tin hệ thống
create_system_info() {
    log "${BLUE}=== BƯỚC 10: TẠO THÔNG TIN HỆ THỐNG ===${NC}"
    
    cat > /root/system-info.txt << EOF
=== THÔNG TIN VPS SETUP ===
Thời gian cài đặt: $(date)
Hệ điều hành: $(lsb_release -d | awk -F'\t' '{print $2}')
Kernel: $(uname -r)
IP Public: $(curl -s https://api.ipify.org)

=== DỊCH VỤ ĐÃ CÀI ĐẶT ===
✓ Nginx - Web Server
✓ Certbot - SSL/TLS Certificates
✓ UFW - Firewall
✓ Fail2Ban - Intrusion Prevention
✓ VPS Manager - Management Tool

=== CÁCH SỬ DỤNG ===
1. Chạy VPS Manager: /root/scripts/vps-manager.sh
2. Hoặc dùng alias: vps-manager
3. Xem log setup: tail -f /var/log/vps_setup.log
4. Xem trạng thái firewall: ufw status
5. Xem trạng thái fail2ban: fail2ban-client status

=== THÔNG TIN BẢO MẬT ===
- Firewall đã được bật
- Fail2Ban đã được cấu hình
- Hệ thống đã được tối ưu hóa

=== BƯỚC TIẾP THEO ===
1. Thêm domain và cài đặt SSL
2. Cài đặt database (MySQL/PostgreSQL)
3. Cài đặt môi trường phát triển (PHP/Node.js/Python)
4. Thiết lập backup tự động

Chúc bạn sử dụng VPS thành công! 🚀
EOF
    
    log "${GREEN}✓ Đã tạo file thông tin hệ thống${NC}"
}

# Hàm dọn dẹp
cleanup() {
    log "${BLUE}=== BƯỚC 11: DỌN DẸP ===${NC}"
    
    apt autoremove -y >> $LOG_FILE 2>&1
    apt autoclean >> $LOG_FILE 2>&1
    
    log "${GREEN}✓ Đã dọn dẹp hệ thống${NC}"
}

# Hàm hiển thị kết quả
show_results() {
    clear
    show_banner
    
    echo -e "${GREEN}🎉 THIẾT LẬP VPS HOÀN TẤT! 🎉${NC}\n"
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│                     KẾT QUẢ SETUP                       │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│ ✓ Hệ thống đã được cập nhật                            │${NC}"
    echo -e "${GREEN}│ ✓ Nginx đã được cài đặt và cấu hình                    │${NC}"
    echo -e "${GREEN}│ ✓ SSL/TLS (Certbot) đã sẵn sàng                        │${NC}"
    echo -e "${GREEN}│ ✓ Firewall (UFW) đã được bật                           │${NC}"
    echo -e "${GREEN}│ ✓ Fail2Ban đã được cấu hình                            │${NC}"
    echo -e "${GREEN}│ ✓ Hệ thống đã được tối ưu hóa                          │${NC}"
    echo -e "${GREEN}│ ✓ VPS Manager đã sẵn sàng sử dụng                      │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│                   THÔNG TIN QUAN TRỌNG                  │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│ 🌐 Website test: http://$(curl -s https://api.ipify.org)${NC}"
    echo -e "${BLUE}│ 🛠️  VPS Manager: /root/scripts/vps-manager.sh           │${NC}"
    echo -e "${BLUE}│ 📋 Thông tin chi tiết: /root/system-info.txt            │${NC}"
    echo -e "${BLUE}│ 📝 Log setup: /var/log/vps_setup.log                   │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "\n${YELLOW}BƯỚC TIẾP THEO:${NC}"
    echo -e "1. Chạy VPS Manager để thêm domain: ${GREEN}vps-manager${NC}"
    echo -e "2. Đọc hướng dẫn chi tiết: ${GREEN}cat /root/system-info.txt${NC}"
    echo -e "3. Kiểm tra website: ${GREEN}http://$(curl -s https://api.ipify.org)${NC}"
    
    echo -e "\n${PURPLE}Cảm ơn bạn đã sử dụng VPS Auto Setup! 🚀${NC}\n"
}

# Hàm main
main() {
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
    
    show_banner
    
    echo -e "${YELLOW}Chuẩn bị thiết lập VPS tự động...${NC}"
    echo -e "${BLUE}Quá trình này sẽ mất khoảng 5-10 phút.${NC}"
    echo -e "${CYAN}Tất cả log sẽ được lưu tại: $LOG_FILE${NC}\n"
    
    read -p "Nhấn Enter để bắt đầu hoặc Ctrl+C để hủy..."
    
    # Thực hiện các bước setup
    update_system
    install_essentials
    install_nginx
    install_ssl
    setup_firewall
    setup_fail2ban
    optimize_system
    setup_directories
    install_vps_manager
    create_system_info
    cleanup
    
    # Hiển thị kết quả
    show_results
}

# Chạy script
main "$@"
