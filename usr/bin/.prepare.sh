
cat>/etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF

for SERVICE in NetworkManager firewalld neutron-openvswitch-agent openvswitch-nonetwork openvswitch neutron-l3-agent; do
  systemctl stop ${SERVICE}
  systemctl disable ${SERVICE}
done

iptables -t nat --flush
iptables --flush

yum list installed | grep ^rdo-release || yum install -y https://rdoproject.org/repos/rdo-release.rpm </dev/null

rm -fv /etc/yum.repos.d/midonet*

cat >/etc/yum.repos.d/datastax.repo<<EOF
[datastax]
name = DataStax Repo for Apache Cassandra
baseurl = http://rpm.datastax.com/community
enabled = 1
gpgcheck = 1
gpgkey = https://rpm.datastax.com/rpm/repo_key

EOF

cat >/etc/yum.repos.d/midokura.repo<<EOF
[midonet]
name=MidoNet
baseurl=http://${OS_MIDOKURA_REPOSITORY_USER}:${OS_MIDOKURA_REPOSITORY_PASS}@yum.midokura.com/repo/v1.9/stable/RHEL/7/
enabled=1
gpgcheck=1
gpgkey=https://${OS_MIDOKURA_REPOSITORY_USER}:${OS_MIDOKURA_REPOSITORY_PASS}@yum.midokura.com/repo/RPM-GPG-KEY-midokura

[midonet-openstack-integration]
name=MidoNet OpenStack Integration
baseurl=http://${OS_MIDOKURA_REPOSITORY_USER}:${OS_MIDOKURA_REPOSITORY_PASS}@yum.midokura.com/repo/openstack-kilo/stable/RHEL/7/
enabled=1
gpgcheck=1
gpgkey=https://${OS_MIDOKURA_REPOSITORY_USER}:${OS_MIDOKURA_REPOSITORY_PASS}@yum.midokura.com/repo/RPM-GPG-KEY-midokura

EOF

for PKG in vim rsync screen make git; do
    yum list installed | grep ^"${PKG}" || yum install -y "${PKG}"
done

yum clean all
yum update -y

exit 0

