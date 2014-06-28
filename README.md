vagrant-docker-oracle12c-rac
============================

**Failed Attempt - only shared as a reference**

Vagrant + Docker + Oracle Linux 6.5 + Oracle Database 12cR1 (Enterprise Edition) RAC setup.  Does not include the GI/DB binary.  You need to download those from the official site beforehand.

Uses Vagrant/Docker images from README_images.md.

Uses pipework https://github.com/jpetazzo/pipework/ for network settings.

as of 6/28/2014

## Setup

* node (Docker Host)
  * Oracle Linux 6.5
  * oracle-rdbms-server-12cR1-preinstall
  * Unbreakable Enterprise Kernel R3
  * Memory: 4GB
  * Root Disk: 50GB
  * External Disk: /dev/sdb(ASM) 10GB, /dev/sdc(/opt1) 15GB, /dev/sdd(/opt2) 15GB
* node1, node2 (Container)
  * Oracle Linux 6.5
  * oracle-rdbms-server-12cR1-preinstall

```
192.168.101.11  node1
192.168.101.12  node2
192.168.101.21  node1-vip
192.168.101.22  node2-vip
192.168.101.100 scan
192.168.102.11  node1-priv
192.168.102.12  node2-priv
```

## Prepare

If you are behing a proxy, install vagrant-proxyconf.

```
(MacOSX)
$ export http_proxy=proxy:port
$ export https_proxy=proty:port

(Windows)
$ set http_proxy=proxy:port
$ set https_proxy=proxy:port

$ vagrant plugin install vagrant-proxyconf
```

Install VirtualBox plugin.

```
$ vagrant plugin install vagrant-vbguest
```

Clone this repository to the local directory.

```
$ git clone https://github.com/yasushiyy/vagrant-docker-oracle12c-rac
$ cd vagrant-docker-oracle12c-rac
```

If you are behind a proxy, add follwing to Vagrantfile:

```
config.proxy.http     = "http://proxy:port"
config.proxy.https    = "http://proxy:port"
config.proxy.no_proxy = "localhost,127.0.0.1"
```

Download the Grid Infrastructure / Database binary form below.  Unzip to the same directory as above.  It should have the subdirectory name "grid" and "database".

http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

go to Linux x86-64 -> "See All"

* into "database" subdirectory
  * linuxamd64_12c_database_1of2.zip
  * linuxamd64_12c_database_2of2.zip

* into "grid" subdirectory
  * linuxamd64_12c_grid_1of2.zip
  * linuxamd64_12c_grid_2of2.zip

Boot and reload.  This might take a long time.

```
$ vagrant up
$ vagrant reload
```

## Setup Containers

Start a container and create an image.

Several docker-unique setup:
* /etc/hosts is replaced with /tmp/hosts https://gist.github.com/lalyos/9525120
* /usr/bin/who is replaced because it does not return the runlevel as required by OUI
* /sbin/initctl is replaced because it does not start /etc/init.d script correctly

```
[vagrant@node ~]$ sudo su -

(if behind a proxy)
[root@node ~]# service docker stop
[root@node ~]# HTTP_PROXY=proxy:port HTTPS_PROXY=proxy:port docker -d >/dev/null 2>&1 &
[root@node ~]# docker run -e http_proxy=proxy:port -e https_proxy=proxy:port --privileged -t -i -v /vagrant:/vagrant yasushiyy/oraclelinux65 /bin/sh /vagrant/setup_container.sh

[root@node ~]# docker run --privileged -t -i -v /vagrant:/vagrant yasushiyy/oraclelinux65 /bin/sh /vagrant/setup_container.sh
[root@node ~]# docker commit `docker ps -a | grep oraclelinux65 | head -1 | awk '{print $1}'` ol65
```

Start containers, and bridge them together.

```
[root@node ~]# NODE1=$(docker run --privileged -h node1 -v /vagrant:/vagrant -v /opt1:/opt -t -i -d ol65 /bin/sh -c "/vagrant/setup_container_run.sh; /bin/bash")
[root@node ~]# NODE2=$(docker run --privileged -h node2 -v /vagrant:/vagrant -v /opt2:/opt -t -i -d ol65 /bin/sh -c "/vagrant/setup_container_run.sh; /bin/bash")
[root@node ~]# /vagrant/setup_host_network.sh $NODE1 $NODE2
```

Setup ssh equivalence.

```
[root@node ~]# docker attach $NODE1
bash-4.1# su - grid   -c "expect /vagrant/setup_ssh.expect grid   oracle"
bash-4.1# su - oracle -c "expect /vagrant/setup_ssh.expect oracle oracle"
  -> Ctrl-p Ctrl-q to detach if you need to.
```

## Install Clusterware (as grid)

Install Clusterware.

```
bash-4.1# su - grid

(optional)
[grid@node1 ~]$ /vagrant/grid/runInstaller -silent -responseFile /vagrant/grid_install.rsp -executePrereqs

the follwing WARNING can be ignored:
[WARNING] [INS-13014] Target environment does not meet some optional requirements.

[grid@node1 ~]$ /vagrant/grid/runInstaller -silent -responseFile /vagrant/grid_install.rsp

the follwing WARNING can be ignored:
[WARNING] [INS-41170] You have chosen not to configure the Grid Infrastructure Management Repository. Not configuring the Grid Infrastructure Management Repository will permanently disable the Cluster Health Monitor, QoS Management, Memory Guard, and Rapid Home Provisioning features. Enabling of these features will require reinstallation of the Grid Infrastructure.
[WARNING] [INS-30011] The SYS password entered does not conform to the Oracle recommended standards.
[WARNING] [INS-30011] The ASMSNMP password entered does not conform to the Oracle recommended standards.
[WARNING] [INS-13014] Target environment does not meet some optional requirements.

   :
The installation of Oracle Grid Infrastructure 12c was successful.
   :
```

Run root scripts.  When asked for a root password, enter "oracle".

```
[grid@node1 ~]$ ssh root@node1 /opt/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node2 /opt/oraInventory/orainstRoot.sh
[grid@node1 ~]$ ssh root@node1 /opt/12.1.0.1/grid/root.sh
  :
CRS-2678: 'ora.cssdmonitor' on 'node1' has experienced an unrecoverable failure
CRS-0267: Human intervention required to resume its availability.
  :
CRS-5802: Unable to start the agent process
CRS-4000: Command Start failed, or completed with errors.
2014/06/28 00:56:51 CLSRSC-119: Start of the exclusive mode cluster failed
2014/06/28 01:02:21 CLSRSC-198: Initial cluster configuration failed
The command '/opt/12.1.0.1/grid/perl/bin/perl -I/opt/12.1.0.1/grid/perl/lib -I/opt/12.1.0.1/grid/crs/install /opt/12.1.0.1/grid/crs/install/rootcrs.pl ' execution failed
```

**FAILED!!!**

## after host reboot (memo)

Re-connecting to an existing container is like starting up a server.  Some settings must be done again.

```
[root@node ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS                      PORTS               NAMES
70694a2fef51        ol65:latest         /bin/sh -c '/vagrant   8 minutes ago       Exited (-1) 2 minutes ago                       sad_carson
2ba77f412082        ol65:latest         /bin/sh -c '/vagrant   8 minutes ago       Exited (-1) 2 minutes ago                       ecstatic_bell

NODE1=<cid>
NODE2=<cid>

[root@node ~]# docker start $NODE1
[root@node ~]# docker start $NODE2
[root@node ~]# /vagrant/setup_host_network.sh $NODE1 $NODE2

[root@node ~]# docker attach $NODE1
bash-4.1# su - grid   -c "expect /vagrant/setup_ssh.expect grid   oracle"
bash-4.1# su - oracle -c "expect /vagrant/setup_ssh.expect oracle oracle"
  -> Ctrl-p Ctrl-q to detach
```
