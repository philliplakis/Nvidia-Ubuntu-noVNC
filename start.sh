#!/bin/bash
#
# BASICS
#
echo "********************************************************************************"
echo ""
echo "Setting up the host."
echo ""
echo "********************************************************************************"
apt-get update -y
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl wget emacs vim less sudo lsof net-tools git htop gedit gedit-plugins unzip zip psmisc xz-utils libglib2.0-0 libxext6 libsm6 libxrender1 libpython-dev libsuitesparse-dev libeigen3-dev libsdl1.2-dev doxygen graphviz libignition-math2-dev gcc libc6-dev libglu1 libglu1:i386 libxv1 libxv1:i386 lubuntu-desktop xvfb xterm terminator zenity mesa-utils make cmake python python-numpy x11-xkb-utils xauth xfonts-base xkb-data openssl -y
apt-get upgrade
#
# INSTALL NVIDIA DRIVERS
#
echo "********************************************************************************"
echo ""
echo "NVIDIA DRIVERS"
echo ""
echo "********************************************************************************"
sleep 5
wget http://us.download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run
chmod a+x NVIDIA-Linux-x86_64-410.78.run
./NVIDIA-Linux-x86_64-410.78.run -s --install-libglvnd
#
# SETUP noVNC / TigerVNC 
#
echo "********************************************************************************"
echo ""
echo "SETUP noVNC / TigerVNC"
echo ""
echo "********************************************************************************"
sleep 5
git clone https://github.com/novnc/noVNC.git
curl -fsSL https://github.com/novnc/websockify/archive/v0.8.0.tar.gz | tar -xzf - -C /opt && \
mv ./noVNC /opt/noVNC && \
chmod -R a+w /opt/noVNC && \
mv /opt/websockify-0.8.0 /opt/websockify && \
cd /opt/websockify && make && \
cd /opt/noVNC/utils && \
ln -s /opt/websockify
cd /tmp && \
curl -fsSL -O https://sourceforge.net/projects/turbovnc/files/2.2/turbovnc_2.2_amd64.deb \
        -O https://sourceforge.net/projects/libjpeg-turbo/files/1.5.2/libjpeg-turbo-official_1.5.2_amd64.deb \
        -O https://sourceforge.net/projects/virtualgl/files/2.5.2/virtualgl_2.5.2_amd64.deb \
        -O https://sourceforge.net/projects/virtualgl/files/2.5.2/virtualgl32_2.5.2_amd64.deb && \
dpkg -i *.deb && \
rm -f /tmp/*.deb && \
sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver
#
echo "LightDM Area"
echo "**********"
sleep 5
perl -pi -e 's/^lightdm:(.*)(\/bin\/false)$/lightdm:$1\/bin\/bash/' /etc/passwd
export DISPLAY=":0"
service lightdm start
# Critical to wait a bit: you can't run xhost too fast after x starts
sleep 5
# This xhost command is key to getting Lubuntu working properly with nvidia-driven GPU support.
su - lightdm -c "xhost +si:localuser:root"
perl -pi -e 's/^lightdm:(.*)(\/bin\/bash)$/lightdm:$1\/bin\/false/' /etc/passwd
echo "Defeat screen locking and power management"
echo "**********"
# Defeat screen locking and power management
mv /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/light-locker.desktop_bak
mv /etc/xdg/autostart/xfce4-power-manager.desktop /etc/xdg/autostart/xfce4-power-manager.desktop_bak
echo " ****  SSL SETUP  **** "
echo "**********"
cd /etc/ssl
openssl req -x509 -nodes -newkey rsa:2048 -keyout self.pem -out self.pem -days 365
cd 
echo " ****  xstartup.turbovnc  **** "
echo "**********"
mkdir -p ~/.vnc
cd ~/.vnc/
cat > xstartup.turbovnc <<EOF
#!/bin/sh
xsetroot -solid grey
/usr/bin/lxsession -s Lubuntu &
EOF
cd ../
chmod a+x ~/.vnc/xstartup.turbovnc
echo " ****  Start XVnc/X/Lubuntu  **** "
echo "**********"
# Start XVnc/X/Lubuntu
/opt/TurboVNC/bin/vncserver
chmod -f 777 /tmp/.X11-unix
touch ~/.Xauthority
xauth generate :0 . trusted
echo " ****  Start Websockify  **** "
echo "**********"
if [ $? -eq 0 ] ; then
    /opt/noVNC/utils/launch.sh --vnc localhost:5901 --cert /etc/ssl/self.pem

fi
