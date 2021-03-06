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
yum install -y openstack-packstack vim rsync screen make git
yum update -y
```
You should now reboot the machine to make sure SELinux is off.

After that you can continue with the packstack answer file generation and the installation of packstack.
```
packstack --gen-answer-file=/root/answers.txt
packstack --answer-file=/root/answers.txt
```

You now have to git clone this repository to the box.
```
git clone https://github.com/midonet/seahawk.git
```
Modify the file '/root/seahawk/conf/gateways.txt' and enter the ips of where you want to run the midonet gateways.

You must have valid MEM credentials to run this script:
```
[root@seahawk1 seahawk(keystone_admin)]# cat /root/.bashrc
# .bashrc

export OS_MIDOKURA_REPOSITORY_USER=xxx
export OS_MIDOKURA_REPOSITORY_PASS=yyy
```

After you have edited the gateways.txt and added the environment variables run the script for converting the box to MidoNet:
```
[root@seahawk seahawk]# pwd
/root/seahawk
[root@seahawk seahawk]# make
```
This script expects the answerfile in /root/answers.txt.

If its not there or you are using a different filename you can export the environment variable ANSWERFILE to point to it.

We will install the NSDB (zookeeper and cassandra) on the controller and the first two compute nodes.

If you do not have two compute nodes (for example when using an allinone) we will only install ZK and CS on one node.

Attention: make sure name resolution works, the packstack installer makes heavy use of hostnames in nova.conf etc.

For example if vnc is not working then most likely because your OpenStack controller cannot resolv the hostname of the compute node that is in the vnc settings of it.

