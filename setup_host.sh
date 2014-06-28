#!/bin/sh

# yum update
yum update -y

# install Oracle Database prereq packages
yum install -y oracle-rdbms-server-12cR1-preinstall

# mount /opt1, /opt2 (for ORACLE_HOMEs), uses sfdisk -d output
sfdisk /dev/sdc << EOF
unit: sectors
/dev/sdc1 : start=       63, size= 31455207, Id=83
EOF
sfdisk /dev/sdd << EOF
unit: sectors
/dev/sdd1 : start=       63, size= 31455207, Id=83
EOF
mkfs.ext4 /dev/sdc1
mkfs.ext4 /dev/sdd1
mkdir /opt1 /opt2
echo "/dev/sdc1  /opt1  ext4  defaults  0  0" >> /etc/fstab
echo "/dev/sdd1  /opt2  ext4  defaults  0  0" >> /etc/fstab
mount -a

# install Docker, replace with the latest binary, disable selinux
rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y docker-io
curl -O --location https://get.docker.io/builds/Linux/x86_64/docker-latest
chmod a+x docker-latest
mv -f docker-latest /usr/bin/docker
chkconfig docker on

# disable selinux
sed -i.bak "s/--selinux-enabled//" /etc/sysconfig/docker
sed -i.bak "s/hugepage=never/hugepage=never selinux=0/" /boot/grub/grub.conf

# disable iptables
chkconfig iptables off

# pipework fix http://blog.hansode.org/archives/52634753.html
yum install -y http://rdo.fedorapeople.org/openstack/openstack-havana/rdo-release-havana.rpm
yum update --enablerepo=openstack-havana -y iproute

# confirm
cat /etc/oracle-release
