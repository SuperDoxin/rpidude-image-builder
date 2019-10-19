#!/usr/bin/env bash

set -e
set -o pipefail
set -x

BASEDIR=`dirname "$(readlink -f "$0")"`
! mkdir ${BASEDIR}/build
cd ${BASEDIR}/build

if [ "$(ls -A .)" ]; then
    echo "Build directory is not empty! aborting."
    exit -1
fi

# redirect stdout/stderr to a log file
exec 2> >(tee -ia build.log >&2)
exec > >(tee -i build.log)

! false "start of user settings"
################################
### settings below this line ###
################################

mirror="http://mirrordirector.raspbian.org/raspbian/"
release="buster"
version_tag="local-development"
boot_partition_size="100" # in megabytes
root_partition_size="2000" # in megabytes, aproximate

################################
### settings above this line ###
################################
! false "end of user settings"

bold=$(tput bold)
normal=$(tput sgr0)

device="";
root_device="";
boot_device="";
function cleanup {
    if [ -n "$device" ]; then
        losetup -d "$device"
    fi
    if [ -n "$boot_device" ]; then
        ! umount root/boot
        ! rmdir root/boot
    fi
    if [ -n "$root_device" ]; then
        ! umount root
        ! rmdir root
    fi
    ! rm keyring.gpg
    ! rm keyring.gpg~
}
trap cleanup EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Current user is not root! Please re-run script as root or using sudo"
    exit
fi


### create empty image
echo "Creating empty image..."

image="./rpidude.img"
dd if=/dev/zero of="$image" bs=1MB count=$(( $boot_partition_size + $root_partition_size ))
device=`losetup -f --show "$image"`

echo "Mounted image as $device"
echo "Creating partitions"

! fdisk $device << EOF
n
p
1

+${boot_partition_size}M
t
c
n
p
2


w
EOF

echo "Telling the OS about new partitions"
partprobe $device
echo "Creating filesystems"

mkfs.vfat -n "RPIDudeBoot" "${device}p1"
mkfs.ext4 -L "RPIDudeRoot" "${device}p2"

echo "Mounting filesystems"

mkdir root
root_device=${device}p2
mount "$root_device" root

mkdir root/boot
boot_device=${device}p1
mount "$boot_device" root/boot

echo "creating keyring"
keyring=`readlink -f keyring.gpg`
gpg --no-default-keyring --keyring $keyring --fingerprint --import /usr/share/keyrings/debian-archive-keyring.gpg
gpg --no-default-keyring --keyring $keyring --fingerprint --import ../raspbian.public.key
gpg --no-default-keyring --keyring $keyring --fingerprint --import ../raspberrypi.gpg.key


echo "Bootstrapping debian [stage one]"
package_cache_dir=`readlink -f ../package-cache`
! mkdir "$package_cache_dir"
debootstrap --include=locales,console-common,ntp,openssh-server,sudo,wpasupplicant,xorg,python3,python3-pip,python3-gpiozero --foreign --cache-dir "$package_cache_dir" --keyring "$keyring" --arch armhf $release root $mirror

#raspberrypi-sys-mods raspberrypi-archive-keyring raspberrypi-bootloader libraspberrypi-bin

echo "Bootstrapping debian [stage two]"
chroot root /debootstrap/debootstrap --second-stage

echo "Applying overlay"
! rsync -a ../overlay/ ./root/

echo "Exporting keyring"
gpg --no-default-keyring --keyring $keyring --export > root/etc/apt/trusted.gpg

echo "Runing setup steps"

cp ../scripts/_setup.sh root/_setup.sh
sed -i "s/FAKERELEASE/$release/g" root/_setup.sh
chmod +x root/_setup.sh
LANG=C chroot root/ bash /_setup.sh
rm root/_setup.sh

echo "Cleaning up apt"

cp ../scripts/_cleanup.sh root/_cleanup.sh
chmod +x root/_cleanup.sh
LANG=C chroot root/ bash /_cleanup.sh
rm root/_cleanup.sh

echo "${bold}======== Done! ========${normal}"

read -p "Press any key to continue... " -n1 -s

