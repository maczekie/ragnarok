#!/bin/bash
## +----------------------------------------------------------------------+
## | Unattended rAthena Installer - Created and Maintained by Ryoma       |
## | Copyright (C) 2016 - 2020  Ryoma,                     			      |
## |                                                                      |
## | This program is free software: you can redistribute it and/or modify |
## | it under the terms of the GNU General Public License as published by |
## | the Free Software Foundation, either version 3 of the License, or    |
## | any later version.                                                   |
## |                                                                      |
## | This program is distributed in the hope that it will be useful,      |
## | but WITHOUT ANY WARRANTY; without even the implied warranty of       |
## | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        |
## | GNU General Public License for more details.                         |
## |                                                                      |
## | You should have received a copy of the GNU General Public License    |
## | along with this program.  If not, see <http://www.gnu.org/licenses/>.|
## +----------------------------------------------------------------------+
## | Authors: Machael Gregorio <piratecodes>                              |
## +----------------------------------------------------------------------+
#

## Variables that can be overwritten by cli switches
DEV=0
APTARGS="-qy"
GEOMETRY="1920x1080"

## Process command line arguements
for arg in "$@"
do
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
		echo "Available command switches:"
		echo "Option  Long Option        Description"
		echo " -d     --dev-mode         Developer mode, shows more output, skips full client"
		echo " -s     --small-window     Sets the default VNC geometry to 1024x768"
		exit 0
    fi
    if [ "$arg" == "--dev-mode" ] || [ "$arg" == "-d" ]; then
		DEV=1
		APTARGS=""
    fi
    if [ "$arg" == "--small-window" ] || [ "$arg" == "-s" ]; then
		GEOMETRY="1024x768"
    fi
done

## Create variables for the script to use
# General
MYFILE=$0
VERSION_MAJOR=1
VERSION_MINOR=3
VERSION_PATCH=0
INSTALLER_VERSION="v${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
STEPS=18
OPSYS='unkown'
PROCESSOR='unknown'
SERVER_IPLIST=$(ip addr|awk '/eth0/ && /inet/ {gsub(/\/[0-9][0-9]/,""); print $2}')
SERVER_IP=$(echo $SERVER_IPLIST | cut -d ' ' -f 1 )
LOG_FILE='/root/cervantes_install.log'
touch $LOG_FILE
LOCAL_CERVANTES="/usr/share/cervantes"
LOCAL_DESKTOP="/home/rathena/Desktop"
LOCAL_RA_LOCATION="${LOCAL_DESKTOP}/rAthena"
LOCAL_INFO_FILE="${LOCAL_DESKTOP}/Info.txt"
LOCAL_WWW_ROOT="/var/www/html"
VERSION_PMA='5.0.2'

# Colors
BLUE='\033[0;36m'
GREEN='\033[0;92m'
RED='\033[0;92m'
YELLOW='\033[0;93m'
NC='\033[0m'

# Credentials
USERID=$(date +%s | sha256sum | base64 | head -c 6 ; echo)
USERPASS=$(date +%s | sha256sum | base64 | head -c 8 ; echo)
RATHENAPASS="ryoma2020"
DEFSQL="ragnarok"
RAGSQLPASS=$(date +%s | sha256sum | base64 | head -c 10 ; echo)

# URLs
URL_RA="https://rathena.org/board"
URL_RAGIT="https://github.com/rathena/rathena"
URL_FLUXGIT="https://github.com/rathena/FluxCP"
URL_CERVANTES_SCRIPTS="https://vhost.rocks/cervantes_scripts"
URL_FULLCLIENT="https://vhost.rocks/cervantes_scripts/client.zip"
URL_PHPMYADMIN="https://files.phpmyadmin.net/phpMyAdmin/${VERSION_PMA}/phpMyAdmin-${VERSION_PMA}-all-languages.zip"

## Packages
PACKAGES_GENERIC="expect wget sudo nano zip unzip unrar-free"
PACKAGES_MYSQL="libaio1 libdbd-mariadb-perl libdbi-perl libterm-readkey-perl libhtml-template-perl"
PACKAGES_WEB="apache2 libapache2-mod-php php-mysql php-gd php-mbstring php-xml"
PACKAGES_XFCE="xfce4 xfce4-goodies gnome-icon-theme tightvncserver zenity"
PACKAGES_RATHENA=" git make libmariadb-dev libmariadbclient-dev libmariadbclient-dev-compat gcc g++ zlib1g-dev libpcre3-dev"


if [ $DEV -eq 1 ]; then
	INSTALLER_VERSION="${INSTALLER_VERSION} - Development Script"
fi


## Helper Functions
# Print error to console and terminate
print_error_die() {
    echo
    echo -e "\033[40m\033[001;031mERROR: $@\033[0m"
    echo
    [ -f $LOG ] && tail -n15 $LOG_FILE
    exit 1
}
# Print standard error to console
print_error() {
    echo -e "\033[40m\033[001;031mERROR: $@\033[0m"
}
# Print warning message to console and sleep
print_warning() {
    echo
    echo -e "\033[40m\033[001;033mWARNING: $@\033[0m"
    echo
    sleep 2
}
# Print a section header
print_header() {
	echo
    echo "\033[0;40m\033[1;37m\033[1m$@\033[0m"
	echo
}

func_install() {
	echo "\033c"
	print_header "Welcome to Cervantes, an unattended installer by vHost"
	print_header "Version: ${INSTALLER_VERSION}\n"
	print_header "This script will now begin to install a bunch of stuff on your system. Please be patient as this could take a while!\n"

	step_updateos
	step_install_prerequisits
	step_install_mysql
	step_install_web
	step_install_xfce
	step_install_rapackages

	step_setup_user
	step_setup_desktop
	step_setup_vncservice
	step_setup_cervantes
	step_setup_rathena
	step_setup_fluxcp
	step_setup_phpmyadmin

	step_setup_fullclient
	step_finalise_imports
	step_finalise_script
}

step_updateos() {
	print_header "Updating your OS"
	apt-get -y update
	apt-get -y upgrade
	echo ""
}

step_install_prerequisits() {
	print_header "Installing Prerequisites"
	apt-get ${APTARGS} install ${PACKAGES_GENERIC} > /dev/null
	echo ""
}

step_install_mysql() {
	print_header "Installing MySQL Stuff"
	apt-get ${APTARGS} install ${PACKAGES_MYSQL} > /dev/null
	export DEBIAN_FRONTEND=noninteractive
	bash -c 'debconf-set-selections <<< "mariadb-server mariadb-server/root_password password ragnarok"'
	bash -c 'debconf-set-selections <<< "mariadb-server mariadb-server/root_password_again password ragnarok"'
	apt-get ${APTARGS} install mariadb-server
	wget -q ${URL_CERVANTES_SCRIPTS}/msi.sh
	chmod +x msi.sh && ./msi.sh
	rm msi.sh
}

step_install_web() {
	print_header "Installing Apache2 & PHP"
	apt-get ${APTARGS} install ${PACKAGES_WEB} > /dev/null
	systemctl restart apache2
	echo ""
}

step_install_xfce() {
	print_header "Installing Desktop VNC packages"
	echo " * Installing xfce & VNCServer"
	apt-get ${APTARGS} install ${PACKAGES_XFCE} > /dev/null
	wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	apt-get ${APTARGS} install ./google-chrome-stable_current_amd64.deb
	echo ""
}


step_install_rapackages() {
	print_header "Installing rA specific packages"
	apt-get ${APTARGS} install ${PACKAGES_RATHENA} > /dev/null
	echo ""
}

step_setup_user() {
	print_header "Creating User: rathena"
	echo "${YELLOW}This process is automatic and doesn't require user input.${NC}"
	echo "${YELLOW}Please do not type at the password prompt.${NC}"
	sudo useradd rathena
	wget -q ${URL_CERVANTES_SCRIPTS}/useraddpasswd.sh
	chmod +x useraddpasswd.sh && ./useraddpasswd.sh $RATHENAPASS
	rm useraddpasswd.sh
	gpasswd -a rathena sudo
	echo ""
}

step_setup_desktop() {
	print_header "Setting Up Desktop Stuff"
	mkdir -p ${LOCAL_CERVANTES}/
	cd ${LOCAL_CERVANTES}/
	wget -q https://github.com/maczekie/ragnarok/blob/main/files.zip
	unzip -qq files.zip
	cd links
	mkdir -p ${LOCAL_DESKTOP}
	cp -R * ${LOCAL_DESKTOP}
	cd ${LOCAL_CERVANTES}/scripts && chmod +x *
	cd ${LOCAL_DESKTOP} && chmod +x *
	echo
}


step_setup_vncservice() {
	print_header "Creating VNC Server Start-up Files"
	cd /usr/local/bin
	touch myvncserver
	echo "#!/bin/bash
PATH=\"$PATH:/usr/bin/\"
case \"$1\" in
start)
/usr/bin/vncserver -depth 16 -geometry ${GEOMETRY} :1
;;
stop)
/usr/bin/vncserver -kill :1
;;
restart)
$0 stop
$0 start
;;
esac
exit 0" >> myvncserver
	chmod +x myvncserver
	echo "[Unit]
Description=Manage VNC Server

[Service]
Type=forking
ExecStart=/usr/local/bin/myvncserver start
ExecStop=/usr/local/bin/myvncserver stop
ExecReload=/usr/local/bin/myvncserver restart
User=rathena

[Install]
WantedBy=multi-user.target" >> /lib/systemd/system/myvncserver.service
	systemctl daemon-reload
	systemctl enable myvncserver.service
	echo ""
}

step_setup_cervantes() {
	print_header "Installing Cervantes Files"
	chown -R rathena:rathena /home/rathena
	chown -R rathena:rathena ${LOCAL_CERVANTES}
	cd /home/rathena
	sudo -u rathena sh -c "wget -q ${URL_CERVANTES_SCRIPTS}/vnc.sh"
	sudo -u rathena sh -c "chmod +x vnc.sh"
	sudo -u rathena sh -c "./vnc.sh $RATHENAPASS"
	rm vnc.sh
	sudo -u rathena sh -c "myvncserver stop"
	mkdir -p /home/rathena/.config/xfce4/xfconf/xfce-perchannel-xml/
	touch /home/rathena/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<channel name=\"xfce4-desktop\" version=\"1.0\">
  <property name=\"backdrop\" type=\"empty\">
    <property name=\"screen0\" type=\"empty\">
      <property name=\"monitor0\" type=\"empty\">
        <property name=\"brightness\" type=\"empty\"/>
        <property name=\"color1\" type=\"empty\"/>
        <property name=\"color2\" type=\"empty\"/>
        <property name=\"color-style\" type=\"empty\"/>
        <property name=\"image-path\" type=\"string\" value=\"${LOCAL_CERVANTES}/img/bg_${GEOMETRY}.png\"/>
        <property name=\"image-show\" type=\"empty\"/>
        <property name=\"last-image\" type=\"empty\"/>
        <property name=\"last-single-image\" type=\"string\" value=\"${LOCAL_CERVANTES}/img/bg_${GEOMETRY}.png\"/>
      </property>
    </property>
  </property>
  <property name=\"desktop-icons\" type=\"empty\">
    <property name=\"icon-size\" type=\"uint\" value=\"32\"/>
  </property>
</channel>" >> /home/rathena/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
	touch /home/rathena/.config/mimeapps.list
	echo "[Default Applications]
text/plain=mousepad.desktop

[Added Associations]
text/plain=mousepad.desktop;" >> /home/rathena/.config/mimeapps.list
	chown -R rathena:rathena /home/rathena/
}

step_setup_rathena() {
	print_header "Grabbing rA Source Files"
	sudo -u rathena sh -c "git clone -q ${URL_RAGIT} ${LOCAL_RA_LOCATION}"
	echo ""


	print_header "Performing Initial rA Compile"
	echo "This step will take time.. please be patient"
	echo "You may see warnings here - this is normal"
	cd ${LOCAL_RA_LOCATION}
	sudo -u rathena sh -c "./configure > /dev/null"
	sudo -u rathena sh -c "make server > /dev/null"
	sudo -u rathena sh -c "chmod a+x login-server && chmod a+x char-server && chmod a+x map-server"
	echo ""


	print_header "Creating MySQL Database"
	mysqladmin -u root -p${DEFSQL} create ragnarok
	mysql -u root -p${DEFSQL} -e "CREATE USER ragnarok@localhost IDENTIFIED BY '${RAGSQLPASS}';"
	mysql -u root -p${DEFSQL} -e "GRANT ALL PRIVILEGES ON ragnarok.* TO 'ragnarok'@'localhost';"
	mysql -u root -p${DEFSQL} -e "CREATE USER ragnarok@127.0.0.1 IDENTIFIED BY '${RAGSQLPASS}';"
	mysql -u root -p${DEFSQL} -e "GRANT ALL PRIVILEGES ON ragnarok.* TO 'ragnarok'@'127.0.0.1';"
	mysql -u root -p${DEFSQL} -e "CREATE USER ragnarok@slash.vhost.rocks IDENTIFIED BY '${RAGSQLPASS}';"
	mysql -u root -p${DEFSQL} -e "GRANT ALL PRIVILEGES ON ragnarok.* TO 'ragnarok'@'slash.vhost.rocks';"
	mysql -u root -p${DEFSQL} -e "CREATE USER ragnarok@jimi.vhost.rocks IDENTIFIED BY '${RAGSQLPASS}';"
	mysql -u root -p${DEFSQL} -e "GRANT ALL PRIVILEGES ON ragnarok.* TO 'ragnarok'@'jimi.vhost.rocks';"
	mysql -u root -p${DEFSQL} -e "FLUSH PRIVILEGES;"
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/main.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/logs.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_cash_db.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_cash_db2.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_db.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_db2.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_db2_re.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/item_db_re.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_db.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_db2.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_db2_re.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_db_re.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_skill_db.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_skill_db2.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_skill_db2_re.sql
	mysql -u root -p${DEFSQL} ragnarok  < ${LOCAL_RA_LOCATION}/sql-files/mob_skill_db_re.sql
	mysql -u root -p${DEFSQL} -e "USE ragnarok; UPDATE login SET userid = '${USERID}', user_pass = '${USERPASS}' WHERE sex = 'S';"
	echo ""
}

step_setup_fluxcp() {
	print_header "Configuring FluxCP"
	cd ${LOCAL_WWW_ROOT}
	rm ${LOCAL_WWW_ROOT}/index.html
	git clone -q https://github.com/rathena/FluxCP /var/www/html/
	cd ${LOCAL_WWW_ROOT}/
	touch ${LOCAL_WWW_ROOT}/diff.diff
echo "diff --git a/config/application.php b/config/application.php
--- a/config/application.php
+++ b/config/application.php
@@ -3,7 +3,7 @@
 // the default, and should be changed as needed.
 return array(
 	'ServerAddress'				=> 'localhost',				// This value is the hostname:port under which Flux runs. (e.g., example.com or example.com:80)
-	'BaseURI'					=> 'fluxcp',						// The base URI is the base web root on which your application lies.
+	'BaseURI'					=> '',						// The base URI is the base web root on which your application lies.
 	'InstallerPassword'			=> 'secretpassword',		// Installer/updater password.
 	'RequireOwnership'			=> true,					// Require the executing user to be owner of the FLUX_ROOT/data/ directory tree? (Better for security)
 															// WARNING: This will be mostly IGNORED on non-POSIX-compliant OSes (e.g. Windows).
diff --git a/config/servers.php b/config/servers.php
--- a/config/servers.php
+++ b/config/servers.php
@@ -15,7 +15,7 @@ return array(
 				// -- It specifies the encoding to convert your MySQL data to on the website (most likely needs to be utf8)
			'Hostname'   => '127.0.0.1',
			'Username'   => 'ragnarok',
-			'Password'   => 'ragnarok',
+			'Password'   => '${RAGSQLPASS}',
			'Database'   => 'ragnarok',
			'Persistent' => true,
 			'Timezone'   => null // Example: '+0:00' is UTC.
@@ -36,7 +36,7 @@ return array(
 				// -- It specifies the encoding to convert your MySQL data to on the website (most likely needs to be utf8)
			'Hostname'   => '127.0.0.1',
			'Username'   => 'ragnarok',
-			'Password'   => 'ragnarok',
+			'Password'   => '${RAGSQLPASS}',
			'Database'   => 'ragnarok',
			'Persistent' => true,
			'Timezone'   => null // Possible values is as described in the comment in DbConfig." >> ${LOCAL_WWW_ROOT}/diff.diff
	git apply diff.diff
	rm ${LOCAL_WWW_ROOT}/diff.diff
	/sbin/usermod -aG www-data rathena
	chown -R www-data:www-data ${LOCAL_WWW_ROOT}
	chmod -R 0774 ${LOCAL_WWW_ROOT}
	ln -s ${LOCAL_WWW_ROOT} ${LOCAL_DESKTOP}/FluxCP
	echo ""
}

step_setup_phpmyadmin() {
	print_header "Installing phpMyAdmin"
	wget -q ${URL_PHPMYADMIN}
	unzip -qq phpMyAdmin-${VERSION_PMA}-all-languages.zip
	rm phpMyAdmin-${VERSION_PMA}-all-languages.zip
	mv phpMyAdmin-${VERSION_PMA}-all-languages phpmyadmin
	mv phpmyadmin/config.sample.inc.php phpmyadmin/config.inc.php
	echo "<?php" > ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	BLOWFISH=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
	echo "\$cfg['blowfish_secret'] = '${BLOWFISH}';" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$i=0;" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$i++;" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$cfg['Servers'][\$i]['host'] = 'localhost';" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$cfg['Servers'][\$i]['AllowRoot'] = false;" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$cfg['Servers'][\$i]['AllowNoPassword'] = false;" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	echo "\$cfg['Servers'][\$i]['auth_type']     = 'cookie';" >> ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	chown -R www-data:www-data ${LOCAL_WWW_ROOT}
	chmod 0660 ${LOCAL_WWW_ROOT}/phpmyadmin/config.inc.php
	ln -s ${LOCAL_WWW_ROOT} ${LOCAL_DESKTOP}/phpMyAdmin
	echo ""
}

step_setup_fullclient() {
	print_header "Creating Full Downloadable Client"
	echo "This step will take around 10 minutes. Now is the perfect time to go"
	echo "make a nice cup of coffee. The full client is also around 4GB. Please"
	echo "ensure you have enough disk space!"
	if [ $DEV -eq 1 ]
	then
		echo "${YELLOW}Dev Version; Skipping....${NC}"
	else

		mkdir -p ${LOCAL_WWW_ROOT}/downloads/
		cd ${LOCAL_WWW_ROOT}/downloads/
		wget -q ${URL_FULLCLIENT}
		unzip -qq client.zip
		rm client.zip
		mkdir -p ${LOCAL_WWW_ROOT}/downloads/client/data/
		echo "<?xml version=\"1.0\" encoding=\"euc-kr\" ?>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "<clientinfo>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "	<desc>Ragnarok Client Information</desc>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "	<servicetype>korea</servicetype>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "	<servertype>primary</servertype>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "	<connection>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "		<display>Ragnarok Online</display>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "      		<address>${SERVER_IP}</address>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "      		<port>6900</port>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "      		<version>55</version>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "      		<langtype>1</langtype>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "		<loading>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "			<image>loading00.jpg</image>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "			<image>loading01.jpg</image>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "		</loading>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "		<aid>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "			<admin>2000000</admin>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "		</aid>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "   	</connection>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		echo "</clientinfo>" >> ${LOCAL_WWW_ROOT}/downloads/client/data/sclientinfo.xml
		cd ${LOCAL_WWW_ROOT}/downloads/client/
		wget -q ${URL_CERVANTES_SCRIPTS}/roclient.exe

		# use rsu.pack to create client grf

		cd ${LOCAL_WWW_ROOT}/downloads/
		zip -qqrm fullclient.zip client
		cd ${LOCAL_WWW_ROOT}/downloads/
		rm -rf client/
		cd ${LOCAL_WWW_ROOT}/data/schemas/logindb/
		wget -q ${URL_CERVANTES_SCRIPTS}/cp_cmspages.20170808161901.sql
		chown -R www-data:www-data ${LOCAL_WWW_ROOT}
		cd /home/
		echo ""
	fi
}

step_finalise_imports() {
	print_header "Preparing auto-config import files"
	echo "//Cervantes
userid: ${USERID}
passwd: ${USERPASS}
char_ip: ${SERVER_IP}" >> ${LOCAL_RA_LOCATION}/conf/import/char_conf.txt

	echo "//Cervantes
userid: ${USERID}
passwd: ${USERPASS}
map_ip: ${SERVER_IP}" >> ${LOCAL_RA_LOCATION}/conf/import/map_conf.txt

	echo "//Cervantes
//use_sql_db: yes
login_server_pw: ${RAGSQLPASS}
ipban_db_pw: ${RAGSQLPASS}
char_server_pw: ${RAGSQLPASS}
map_server_pw: ${RAGSQLPASS}
log_db_pw: ${RAGSQLPASS}" >> ${LOCAL_RA_LOCATION}/conf/import/inter_conf.txt

	touch ${LOCAL_INFO_FILE}
	echo "Cervantes
Server IP: ${SERVER_IP}

-- MySQL --
root password is '${DEFSQL}', but can only be accessed locally from this system.
For all other MySQL uses, please use the following credentials:
User: ragnarok
Password: ${RAGSQLPASS}

-- SSH User --
User: rathena
Password: $RATHENAPASS

-- FluxCP --
 * Access FluxCP from this server using the browser and going to http://localhost
 or
 * Access FluxCP from anywhere by browsing to http://${SERVER_IP}/
The Installer Password is the default for FluxCP, which is secretpassword

-- phpMyAdmin --
 * Access phpMyAdmin via the desktop shortcut
 or
 * Access phpMyAdmin from anywhere by browsing to http://${SERVER_IP}/phpmyadmin
Access from root user is disabled, so you will need to login as 'ragnarok' with your MySQL password.

-- Full Client --
A full client will be made available to you on your downloads page straight
 after completing the FluxCP installation process. This is located at:
 * URL: http://${SERVER_IP}/?module=pages&action=content&page=downloads
 * Filesystem: FluxCP Desktop Shortcut -> downloads folder" >> ${LOCAL_INFO_FILE}
}


step_finalise_script() {
	print_header "Finishing up!"
	sudo -u rathena sh -c "myvncserver start"
	echo
	echo
	echo
	echo
	echo
	echo
	echo
	echo "${YELLOW}************************ ${BLUE}All done!${NC}${YELLOW} ******************************${NC}"
	echo "${GREEN} -- System Stuff${NC}"
	echo "Linux User 'rathena' Password: ${RATHENAPASS}"
	echo "Server IP: ${SERVER_IP}"
	echo ""
	echo "${GREEN} -- MySQL Stuff${NC}"
	echo "MySQL user: ragnarok"
	echo "MySQL password: ${RAGSQLPASS}"
	echo "phpMyAdmin: http://${SERVER_IP}/phpmyadmin"
	echo ""
	echo "${GREEN} -- VNC Stuff${NC}"
	echo "VNC Password: ch4ngem3"
	echo "We recommend TightVNC Viewer: http://www.tightvnc.com/download.php"
	echo "In the Remote Host box, type ${SERVER_IP}:1"
	echo ""
	echo "${GREEN} -- FluxCP Stuff${NC}"
	echo "Control Panel: http://${SERVER_IP}/"
	echo "After FluxCP installation, full client will be linked on downloads page."
	echo ""
	echo "${BLUE}You should now use ${GREEN}sudo shutdown -r now ${BLUE}to reboot, then you can login"
	echo " via VNC and click Start rAthena on the desktop.${NC}"
	echo "${YELLOW}*****************************************************************${NC}"
	rm /home/$MYFILE
	exit 0
}


# Figure out where we are
func_oscheck() {
    print_header "Determining Linux distribution"
	if [ $PROCESSOR != 'x86_64']; then
	echo "${RED}I'm not sure what kind of system this is, but i'm not installing on it.${NC}"
	exit 1
	fi

    if [ -f /etc/os-release ]; then
        release=$(cat /etc/os-release)
	else
		echo "${RED}I'm unable to gather information about your OS. It's probably not Debian.${NC}"
		exit 1
	fi

    # lowest common substring
    local deb10="Debian GNU/Linux 10"
    local deb9="Debian GNU/Linux 9"

    if [ `echo "$release" | egrep -c "$deb10"` -gt 0 ]; then
        OPSYS='Debian'
        DISTRO='10'
    fi

    # Needs to be Debian
    if [ "$OPSYS" = "unknown" ]; then
        error_print_die "${RED}System not supported. Require Debian 10.${NC}"
    fi

    # Unsupported version of Debian
    if [ "$DISTRO" = "unknown" ]; then
        error_print_die "${RED}System not supported. Require Debian 10. Consider upgrading your potato.${NC}"
    fi
}

func_oscheck
func_install
