sudo timedatectl set-timezone Asia/Manila

sudo useradd -c "User ArcadiaGM Configured for VNC Access" ArcadiaGM
sudo passwd @rcadiaGM2020

mysqldump -u root –p123456 01_center > 01_center.sql
USE 01_center;
sudo gpasswd -a root mysql
sudo chown -R root: /data

CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY 'bkppassword';

sudo systemctl start mysql

Arcadia Test Server
128.199.246.92
uXRZ8t9F$ceJSaN

128.199.246.92/arcadiatest

128.199.246.92/4bc085c9031ea8898afeecf8eea84219/index.php