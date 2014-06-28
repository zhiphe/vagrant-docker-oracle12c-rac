#!/bin/sh

NODE1=${1:-"dummy"}
NODE2=${2:-"dummy"}

/vagrant/pipework br1 -i eth1 $NODE1 192.168.101.11/24
/vagrant/pipework br2 -i eth2 $NODE1 192.168.102.11/24
/vagrant/pipework br1 -i eth1 $NODE2 192.168.101.12/24
/vagrant/pipework br2 -i eth2 $NODE2 192.168.102.12/24

brctl show
