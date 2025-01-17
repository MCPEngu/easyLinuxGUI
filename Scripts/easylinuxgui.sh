#!/bin/bash
#Script by Ngo Anh Tuan-lowendviet.com (Edited by MCPEngu)
#Changelog
#2021-June-17: Initialize script
if [ $# -eq 5 ] ; then
    vncpw=$1
    ff=$2
    gc=$3
    wine=$4
    lqx=$5
else
    echo -e "Enter password of VNC"
    read  vncpw
    echo -e "Do you want to install Iceweasel browser?(1 = Yes, 0 = No)"
    read ff
    echo -e "Do you want to install Ungoogled-Chromium browser?(1 = Yes, 0 = No)"
    read gc
    echo -e "Do you want to install Wine-staging to run Windows software?(1 = Yes, 0 = No)"
    read wine
    echo -e "Do you want to install Liquorix non-LTS latest Kernel, maybe have better performance(1 = Yes, 0 = No)"
    read lqx

    if [ $ff -eq 1 ]; then
        ff=1
    else
        ff=0
    fi
    if [ $gc -eq 1 ]; then
        gc=1
    else
        gc=0
    fi
    if [ $wine -eq 1 ]; then
        wine=1
    else
        wine=0
    fi
    if [ $lqx -eq 1 ]; then
        lqx=1
    else
        lqx=0
    fi
fi
#Get OS
. /etc/lsb-release
OS=$DISTRIB_ID

useradd vnc
echo vnc:$vncpw | chpasswd
chsh -s /bin/bash vnc
usermod -aG sudo vnc
apt-get update -y

INSTALL_PKGS="xfce4 xfce4-goodies gnome-icon-theme sudo vnc4server htop tigervnc-common bleachbit vim zip unzip unrar file-roller gedit xfonts-base neofetch dbus-x11 git wget build-essential fakeroot libncurses5-dev libssl-dev ccache bison flex qtbase5-dev bc rsync kmod cpio libelf-dev llvm clang lld"
for i in $INSTALL_PKGS; do
  sudo apt-get install -y $i
done

mkdir -p /home/vnc/.vnc || true
echo -e '#!/bin/bash' > /home/vnc/.vnc/xstartup
echo -e "xrdb \$HOME/.Xresources" >> /home/vnc/.vnc/xstartup
echo -e "vncconfig -nowin &" >> /home/vnc/.vnc/xstartup
echo -e "startxfce4 &" >> /home/vnc/.vnc/xstartup
chmod +x /home/vnc/.vnc/xstartup
echo -e "$vncpw\n$vncpw\nn" | vncpasswd /home/vnc/.vnc/passwd
chown -R vnc:vnc /home/vnc
chmod 755 /home/vnc/.vnc

if [ $ff -eq 1 ]; then
    apt-get install -y iceweasel
    
fi
if [ $gc -eq 1 ]; then
    apt update -y
    if [ "$OS" = "Ubuntu" ]; then
        echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /' | tee /etc/apt/sources.list.d/home-ungoogled_chromium.list > /dev/null
        curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/Release.key' | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg > /dev/null
    elif [ "$OS" = "Debian" ]; then
        echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Buster/ /' | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list > /dev/null
        curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Buster/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg > /dev/null
    fi
    apt update -y
    apt install -y ungoogled-chromium
fi
if [ $wine -eq 1 ]; then
    dpkg --add-architecture i386
    apt-get -y install software-properties-common
    wget -nc https://dl.winehq.org/wine-builds/Release.key
    apt-key add Release.key
    if [ "$OS" = "Ubuntu" ]; then
        apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/
    elif [ "$OS" = "Debian" ]; then
        apt-add-repository https://dl.winehq.org/wine-builds/debian/
    fi
    apt-get update
    apt-get -y install --install-recommends winehq-staging winetricks
fi
if [ $lqx -eq 1 ]; then
    apt-get update -yes
    if [ "$OS" = "Ubuntu" ]; then
        add-apt-repository ppa:damentz/liquorix -y
    if [ "$OS" = "Debian" ]; then
        curl 'https://liquorix.net/add-liquorix-repo.sh' | bash
    fi
    apt-get update -y
    apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y
fi

#Create & enable service
touch /lib/systemd/system/levvnc@.service || true
echo "[Unit]" > /lib/systemd/system/levvnc@.service
echo "Description=Automatic VNC service by https://lowendviet.com" >> /lib/systemd/system/levvnc@.service
echo "[Service]" >> /lib/systemd/system/levvnc@.service
echo "Type=forking" >> /lib/systemd/system/levvnc@.service
echo "User=vnc" >> /lib/systemd/system/levvnc@.service
echo "WorkingDirectory=/home/vnc" >> /lib/systemd/system/levvnc@.service
echo "PIDFile=/home/vnc/.vnc/%H:%i.pid" >> /lib/systemd/system/levvnc@.service
echo "ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1" >> /lib/systemd/system/levvnc@.service
echo "ExecStart=/usr/bin/vncserver -depth 16 -geometry 1280x800 :%i" >> /lib/systemd/system/levvnc@.service
echo "ExecStop=/usr/bin/vncserver -kill :%i" >> /lib/systemd/system/levvnc@.service
echo "ExecReload=/usr/bin/vncserver restart" >> /lib/systemd/system/levvnc@.service
echo "[Install]" >> /lib/systemd/system/levvnc@.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/levvnc@.service

echo "\$localhost = \"no\"" >> /etc/vnc.conf

systemctl daemon-reload
systemctl enable levvnc@1.service
if [ "$OS" = "Ubuntu" ]; then
    ufw allow 5901
    touch /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
    echo -e "[Do anything you want]" > /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
    echo -e "Identity=unix-group:root" > /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
    echo -e "Action=*" > /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
    echo -e "ResultActive=yes" > /var/lib/polkit-1/localauthority/50-local.d/disable-passwords.pkla
    reboot
fi
systemctl start levvnc@1.service
