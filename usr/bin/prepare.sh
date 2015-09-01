#!/bin/bash

CONTROLLERS="${1}"
COMPUTE="${2}"
GATEWAYS="${3}"
NSDB="${4}"

cat>/etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF

for SERVICE in NetworkManager firewalld; do
  systemctl stop ${SERVICE}
  systemctl disable ${SERVICE}
done

iptables -t nat --flush
iptables --flush

yum install -y https://rdoproject.org/repos/rdo-release.rpm
yum install -y openstack-packstack vim rsync screen make git puppet
yum update -y

puppet module list 2>/dev/null | grep midonet-midonet || puppet module install midonet-midonet

exit 0

