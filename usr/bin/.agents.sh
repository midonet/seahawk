
yum install -y midolman

hostname -f || cat >/etc/hosts<<EOF
127.0.0.1 localhost.localdomain localhost
${IP} $(hostname).local $(hostname)

EOF

#
# NSDB in midolman.conf
#
cat >/etc/midolman/midolman.conf<<EOF
[zookeeper]
zookeeper_hosts = ${ZK}

EOF

cat <<EOF | mn-conf set -t default
zookeeper {
    zookeeper_hosts = "${ZK}"
}

cassandra {
    servers = "${CS}"
}

agent {
    "haproxy_health_monitor" {
        "haproxy_file_loc"="/etc/midolman/l4lb/"
        "health_monitor_enable"=true
        "namespace_cleanup"=false
    }
}

EOF

echo "cassandra.replication_factor : ${CS_COUNT}" | mn-conf set -t default

service midolman stop

rmmod openvswitch
modprobe openvswitch

service midolman start

sleep 10

ps axufwwwwwwwwww | grep -v grep | grep midolman || exit 1

tail -n200 /var/log/midolman/midolman.log

exit 0

