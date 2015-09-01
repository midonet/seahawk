# seahawk
Follow https://www.rdoproject.org/Quickstart to install the machine with packstack, optionally adding compute nodes:

```
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
yum install -y openstack-packstack
yum update -y
```

You should now reboot the machine to make sure SELinux is off.

After that you can continue with the packstack answer file generation and the installation of packstack.

You now have to git clone this repository to the box.

Modify the file conf/gateways.txt and enter the ips of where you want to run the midonet gateways.

This script expects the answerfile in /root/answers.txt.

If its not there or you are using a different filename you can export the environment variable ANSWERFILE to point to it.

We will install the NSDB (zookeeper and cassandra) on the controller and the first two compute nodes.

If you do not have two compute nodes (for example when using an allinone) we will only install ZK and CS on one node.
