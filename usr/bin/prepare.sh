#!/bin/bash

OS_MIDOKURA_REPOSITORY_USER="${1}"
OS_MIDOKURA_REPOSITORY_PASS="${2}"

CONTROLLERS="${3}"
COMPUTE="${4}"
GATEWAYS="${5}"
NSDB="${6}"

cat <<EOF

MEM USER: ${OS_MIDOKURA_REPOSITORY_USER}
MEM PASS: ${OS_MIDOKURA_REPOSITORY_PASS}

RUNNING SCRIPT ${0} on $(hostname) ($(hostname -f))

CONTROLLER: ${CONTROLLERS}
COMPUTE: ${COMPUTE}
GATEWAYS: ${GATEWAYS}
NSDB: ${NSDB}

EOF

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

yum list installed | grep ^rdo-release || yum install -y https://rdoproject.org/repos/rdo-release.rpm </dev/null

for PKG in vim rsync screen make git puppet; do
    yum list installed | grep ^"${PKG}" || yum install -y "${PKG}"
done

yum update -y

puppet module list 2>/dev/null | grep midonet-midonet || puppet module install midonet-midonet

exit 0

