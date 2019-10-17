#!/usr/bin/env bash

set -x
set -e
set -o pipefail

BASEDIR=`dirname "$(readlink -f "$0")"`
! mkdir ${BASEDIR}/build
cd ${BASEDIR}/build

function cleanup {
    if [ -n "$device" ]; then
        losetup -d "$device"
    fi
    if [ -n "$boot_device" ]; then
        ! umount root/boot
        ! rm -r root/boot
    fi
    if [ -n "$root_device" ]; then
        ! umount root
        ! rm -r root
    fi
}
trap cleanup EXIT

image="./rpidude.img"
device=`losetup -f --show "$image"`

partprobe $device

mkdir root
root_device=${device}p2
mount "$root_device" root

mkdir root/boot
boot_device=${device}p1
mount "$boot_device" root/boot

read -p "Press any key to unmount and exit" -n1 -s
echo ""
