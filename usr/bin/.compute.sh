
cat >/etc/libvirt/qemu.conf<<EOF
user = "root"
group = "root"

cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
    "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
    "/dev/net/tun"
]

EOF

systemctl restart libvirtd.service

#
# contains the rootwrap for calling the datapath binding
#
yum install -y openstack-nova-network
systemctl disable openstack-nova-network.service

systemctl restart openstack-nova-compute.service || systemctl start openstack-nova-compute.service

exit 0

