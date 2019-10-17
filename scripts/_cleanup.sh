# This is supposed to run in the image chroot, 
# not on your dev machine directly!

set -e
set -o pipefail
set -x

apt-get autoremove
apt-get clean
