# This is supposed to run in the image chroot, 
# not on your dev machine directly!

set -e
set -o pipefail
set -x

release="FAKERELEASE" #this gets replaced as the script is copied over

mv /etc/apt/sources.list /etc/apt/sources.list.old
echo "deb http://archive.raspberrypi.org/debian/ $release main" >> /etc/apt/sources.list
apt-get update
# these packages are only available from the rpi foundation repositories.
apt-get install raspberrypi-bootloader raspberrypi-kernel raspberrypi-archive-keyring firmware-brcm80211
mv /etc/apt/sources.list.old /etc/apt/sources.list
apt-get update

echo "setting up wpa_supplicant.service"
systemctl disable wpa_supplicant.service
systemctl enable networking.service

echo "setting up safeshutdown.service"
systemctl enable safeshutdown.service

useradd rpidude -G sudo
password=rpidude
echo "rpidude:${password}" | chpasswd
echo "### IMPORTANT ###"
echo "The password for the rpidude user has been set to ${password}."
echo "### IMPORTANT ###"

echo "making X11 start on boot"
chmod +x /usr/bin/x-daemon
systemctl enable xlogin@rpidude

echo "installing python modules"
pip3 install setuptools

passwd --lock root
