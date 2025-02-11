#!/bin/bash

# 更新系统
echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y

# 安装 Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# 安装 MySQL
echo "Installing MySQL..."
sudo apt install -y mysql-server
sudo mysql_secure_installation

# 安装 PHP 和相关模块
echo "Installing PHP and required modules..."
sudo apt install -y php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc

# 配置 MySQL 数据库
echo "Setting up MySQL database..."
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
MYSQL_USER="wordpress_user"
MYSQL_PASSWORD=$(openssl rand -base64 12)
MYSQL_DATABASE="wordpress_db"

# 创建数据库和用户
sudo mysql -e "CREATE DATABASE $MYSQL_DATABASE;"
sudo mysql -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 安装 WordPress
echo "Installing WordPress..."
cd /var/www
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress /var/www/html/

# 配置 WordPress 权限
echo "Setting up WordPress permissions..."
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# 配置 Nginx 网站配置文件
echo "Configuring Nginx..."
sudo cat > /etc/nginx/sites-available/wordpress <<EOL
server {
    listen 80;
    server_name saustudio.top;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# 启用网站配置并重载 Nginx
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 配置 WordPress
echo "Setting up WordPress configuration..."
cd /var/www/html/wordpress
sudo cp wp-config-sample.php wp-config.php
sudo sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
sudo sed -i "s/username_here/$MYSQL_USER/" wp-config.php
sudo sed -i "s/password_here/$MYSQL_PASSWORD/" wp-config.php

# 重启 Nginx 和 PHP-FPM
echo "Restarting Nginx and PHP-FPM..."
sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm

echo "WordPress installation is complete!"
echo "Please complete the WordPress setup by visiting http://your_domain_or_ip"
echo "MySQL Database: $MYSQL_DATABASE"
echo "MySQL User: $MYSQL_USER"
echo "MySQL Password: $MYSQL_PASSWORD"
