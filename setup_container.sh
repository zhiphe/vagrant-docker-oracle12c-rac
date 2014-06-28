#!/bin/sh

# yum update
yum update -y

# fix locale warning
yum reinstall -y glibc-common

# install packages
yum install -y expect vim-minimal openssh-server oracle-rdbms-server-12cR1-preinstall
service sshd start

# use /tmp/hosts instead of /etc/hosts https://gist.github.com/lalyos/9525120
sed -i.bak 's:/etc/hosts:/tmp/hosts:g' /lib64/libnss_files.so.2

# fix /tmp/hosts
cat > /tmp/hosts << EOF
192.168.101.11  node1
192.168.101.12  node2
192.168.101.21  node1-vip
192.168.101.22  node2-vip
192.168.101.100 scan
192.168.102.11  node1-priv
192.168.102.12  node2-priv
EOF

# add user/groups
groupadd -g 54318 asmdba
groupadd -g 54319 asmoper
groupadd -g 54320 asmadmin
# 54321 oinstall
# 54322 dba
groupadd -g 54323 oper
useradd -u 54320 -g oinstall -G asmdba,asmoper,asmadmin,dba grid
usermod -a -g oinstall -G dba,oper,asmdba oracle

# setup users
cat >> /home/grid/.bash_profile << 'EOF'
export ORACLE_BASE=/opt/grid
export ORACLE_HOME=/opt/12.1.0.1/grid
export PATH=$PATH:$ORACLE_HOME/bin
EOF

cat >> /home/oracle/.bash_profile << 'EOF'
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/12.1.0.1/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin
EOF

cat >> /etc/security/limits.conf << EOF
oracle   soft   nofile   1024
grid     soft   nofile   1024
oracle   hard   nofile   65536
grid     hard   nofile   65536
oracle   soft   nproc    2047
grid     soft   nproc    2047
oracle   hard   nproc    16384
grid     hard   nproc    16384
oracle   soft   stack    10240
grid     soft   stack    10240
oracle   hard   stack    32768
grid     hard   stack    32768
EOF

# change password - avoid http://d.hatena.ne.jp/hiratake55/20090709/1247108930
yum reinstall -y cracklib-dicts
echo oracle | passwd --stdin root
echo oracle | passwd --stdin grid
echo oracle | passwd --stdin oracle

# confirm
cat /etc/oracle-release
