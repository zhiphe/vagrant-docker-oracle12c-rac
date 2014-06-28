#!/bin/sh

service sshd start
chown grid:asmadmin /dev/sdb

if [ ! -f /root/firstrun_done ]; then
  echo "127.0.0.1 localhost localhost.localdomain `hostname`" >> /tmp/hosts
  echo "export ORACLE_SID=`hostname | sed 's/node/+ASM/'`" >> /home/grid/.bash_profile
  echo "export ORACLE_SID=`hostname | sed 's/node/orcl/'`" >> /home/oracle/.bash_profile

  mkdir -p /opt/grid /opt/oraInventory /opt/12.1.0.1/grid /opt/oracle/product/12.1.0.1/dbhome_1
  chown -R oracle:oinstall /opt
  chown -R grid:oinstall /opt/grid /opt/oraInventory /opt/12.1.0.1
  chmod -R ug+rw /opt

  cp /vagrant/who /usr/bin
  cp /vagrant/initctl /sbin
fi

touch /root/firstrun_done
