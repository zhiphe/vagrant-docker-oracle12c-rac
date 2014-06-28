Create Oracle Linux Vagrant/Docker images
==========================================

Oralce Linux 6.5 images for:
* Vagrant Box: local package.box file
* Docker Image: Docker Hub image

## Download

Donload Oracle Linux Release 6 Update 5 for x86_64 (V41362-01)
* https://edelivery.oracle.com/linux

## Install

Install Virtualbox and Vagrant first.

Create a virtual machine as:
* Name: oraclelinux65
* OS: Linux / Oracle (64bit)
* Mem: 512MB
* Disk: root.vdi (50GB), Dynamically Allocated

Open settings and modify below:
* Network -> Advanced -> Adapter -> PCnet-FAST III
* Network -> Advanced -> Promiscuous Mode -> Allow All

Start machine.  When asked for an Optical Disk, specify the downloaded ISO.
* Install or Upgrade
* Skip media scan
* Language: English
* Keyboard: ja106
* Disk: Re-initialize all
* Time: Uncheck UTC, Timezone: Asia/Tokyo
* Password: vagrant -> Use Anyway
* Disk: Use entire drive -> Write changes to disk
* Reboot

Login as root and change the network settings.  Check the IP address.

```
# vi /etc/sysconfig/network-scripts/ifcfg-eth0
ONBOOT=yes
NM_CONTROLLED=no

# service network restart

# ip addr show dev eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:ae:b9:14 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global eth0
    inet6 fe80::a00:27ff:feae:b914/64 scope link
       valid_lft forever preferred_lft forever
```

Enable port-fowarding from Virtualbox to ssh from the host pc.
* Settings -> Network -> Port Forwarding
* Rule 1 / TCP / 127.0.0.1 / 2222 / 10.0.2.15 / 22

Login via ssh.  Now you can copy-and-paste.

```
$ ssh root@localhost -p 2222
vagrant
```

Disable `-bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory` warning.

```
[root@localhost ~]# echo LANG=en_US.utf-8 >> /etc/environment
[root@localhost ~]# echo LC_ALL=en_US.utf-8 >> /etc/environment
```

Enable Unbreakable Enterprise Kernel R3.  Use the entry in /boot/grub/grub.conf.

```
[root@localhost ~]# yum update -y
[root@localhost ~]# more /boot/grub/grub.conf
[root@localhost ~]# grubby --set-default=/boot/vmlinuz3.8xxxx (filename from the above entry)
[root@localhost ~]# reboot
```

## Vagrant-specific settings

Memo:
* https://docs.vagrantup.com/v2/boxes/base.html
* https://docs.vagrantup.com/v2/virtualbox/boxes.html

Install Virtualbox Plugin.  Version number may differ.

```
[root@localhost ~]# yum install -y kernel-uek-devel kernel-uek-headers gcc perl openssh-clients
[root@localhost ~]# curl -O --location http://download.virtualbox.org/virtualbox/4.3.12/VBoxGuestAdditions_4.3.12.iso
[root@localhost ~]# mount -o loop,ro VBoxGuestAdditions*.iso /media
[root@localhost ~]# sh /media/VBoxLinuxAdditions.run
[root@localhost ~]# umount /media
[root@localhost ~]# rm VBoxGuestAdditions*.iso
```

Create vagrant user.

```
[root@localhost ~]# useradd vagrant
[root@localhost ~]# passwd vagrant
vagrant
```

Setup sshd.  `useDNS no` will speed up ssh connection.

```
[root@localhost ~]# vi /etc/ssh/sshd_config
useDNS no
```

Setup passwordless ssh.

```
[root@localhost ~]# su - vagrant
[vagrant@localhost ~]$ mkdir .ssh
[vagrant@localhost ~]$ chmod 700 .ssh
[vagrant@localhost ~]$ cat > .ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF
[vagrant@localhost ~]$ chmod 600 .ssh/authorized_keys
[vagrant@localhost ~]$ exit
```

Setup sudo.  Commenting out "requiretty" will get rid of the `sudo: sorry, you must have a tty to run sudo` error with "vagrant up".


```
[root@localhost ~]# visudo
# Defaults requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
```

Shutdown.

```
[root@localhost ~]# shutdown -h now
```

Create a package.

```
$ vagrant package --base oraclelinux65
```

"package.box" is created in the current directory.

## Docker-specific settings

Memo:
* https://docs.docker.com/articles/baseimages/

Create a Docker Hub repository first.  This example will use "yasushiyy/oraclelinux65".
* https://hub.docker.com/

Startup the virtual machie created above.  Enable SSH port-forwarding again, as vagrant has disable it.

Install Docker.  Replace the binary with the latest version.

```
[root@localhost ~]# rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
[root@localhost ~]# yum install -y docker-io
[root@localhost ~]# curl -O --location https://get.docker.io/builds/Linux/x86_64/docker-latest
[root@localhost ~]# chmod a+x docker-latest
[root@localhost ~]# mv -f docker-latest /usr/bin/docker

[root@localhost ~]# sed -i.bak "s/--selinux-enabled//" /etc/sysconfig/docker
[root@localhost ~]# service docker start
[root@localhost ~]# rm -f /etc/yum.repos.d/epel*.repo
```

Download and execute the conversion script.
* replace variables in yum.repos.d file as it will cause an error.
* replace $version in the script as we want force the tag to be "latest"

```
[root@localhost ~]# sed -i.bak -e "s/\$uekr3/1/" -e "s/\$uek/0/" /etc/yum.repos.d/public-yum-ol6.repo
[root@localhost ~]# curl -O --location https://raw.githubusercontent.com/dotcloud/docker/master/contrib/mkimage-yum.sh
[root@localhost ~]# sed -i.bak "s/\$version/latest/" mkimage-yum.sh
[root@localhost ~]# bash mkimage-yum.sh yasushiyy/oraclelinux65
```

Upload the image to the Docker Hub.

```
[root@localhost ~]# docker login
Username: yasushiyy
Password:
Email: x@y.z
Login Succeeded

[root@localhost ~]# docker push yasushiyy/oraclelinux65
The push refers to a repository [yasushiyy/oraclelinux65] (len: 1)
Sending image list
Pushing repository yasushiyy/oraclelinux65 (1 tags)
a771c205a44f: Image successfully pushed
Pushing tag for rev [a771c205a44f] on {https://registry-1.docker.io/v1/repositories/yasushiyy/oraclelinux65/tags/latest}
```

Confirm.
* https://registry.hub.docker.com/u/yasushiyy/oraclelinux65/

You can safely shutdown and remove the created VM image.

## Test

Test Vagrant box.

```
$ vagrant box add --name oraclelinux65 package.box

$ mkdir test
$ cd test

$ cat > Vagrantfile << EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "oraclelinux65"
end
EOF

$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'oraclelinux65'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: test_default_1403887057705_48235
==> default: Fixed port collision for 22 => 2222. Now on port 2200.
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 => 2200 (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2200
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: Warning: Connection timeout. Retrying...
==> default: Machine booted and ready!
GuestAdditions 4.3.12 running --- OK.
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => /Users/yasushiyy/VM/test

$ vagrant ssh
[vagrant@localhost ~]$ cat /etc/oracle-release
Oracle Linux Server release 6.5
```

Test Docker image.

```
[vagrant@localhost ~]$ sudo su -
[root@localhost ~]# rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
[root@localhost ~]# yum install -y docker-io
[root@localhost ~]# service docker start

[root@localhost ~]# docker run -t -i yasushiyy/oraclelinux65 /bin/bash
Unable to find image 'yasushiyy/oraclelinux65' locally
Pulling repository yasushiyy/oraclelinux65
a771c205a44f: Download complete

bash-4.1# cat /etc/oracle-release
Oracle Linux Server release 6.5
```
