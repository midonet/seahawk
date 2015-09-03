
#
# java
#
yum install -y java-1.7.0-openjdk-headless

mkdir -p /usr/java/default/bin/
ln -s /usr/lib/jvm/jre-1.7.0-openjdk/bin/java /usr/java/default/bin/java

#
# zookeeper
#
yum install -y zookeeper zkdump nmap-ncat

test -f /etc/zookeeper/zoo.cfg.ORIG || cp /etc/zookeeper/zoo.cfg /etc/zookeeper/zoo.cfg.ORIG

cat >/etc/zookeeper/zoo.cfg<<EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper/data
clientPort=2181
EOF

mkdir -pv /var/lib/zookeeper/data

SERVER_ID=0

for ZK_IP in ${NSDB}; do
    SERVER_ID="$(( ${SERVER_ID} + 1 ))"

    if [[ "${IP}" == "${ZK_IP}" ]]; then
        echo "${SERVER_ID}" >/var/lib/zookeeper/data/myid
    fi

    cat >>/etc/zookeeper/zoo.cfg<<EOF
server.${SERVER_ID}=${ZK_IP}:2888:3888
EOF

done

chown -R zookeeper:zookeeper /var/lib/zookeeper/data
chown -R zookeeper:zookeeper /etc/zookeeper

systemctl enable zookeeper.service
systemctl restart zookeeper.service || systemctl start zookeeper.service

sleep 2

echo ruok | nc 127.0.0.1 2181 | grep imok || exit 1

sleep 2

for ZK_IP in ${NSDB}; do
    for BACKOFF in $(seq 1 10); do
        echo ruok | nc "${ZK_IP}" 2181 | grep imok && break
        sleep "$(( ${BACKOFF} * 10 ))"
    done

    echo ruok | nc "${ZK_IP}" 2181 | grep imok || exit 1
    echo status | nc "${ZK_IP}" 2181
done

#
# cassandra
#

SEEDS=""

for CS_IP in ${NSDB}; do
    if [[ "" == "${SEEDS}" ]]; then
        SEEDS="${CS_IP}"
    else
        SEEDS="${SEEDS},${CS_IP}"
    fi
done

yum install -y dsc20

mkdir -p /var/run/cassandra
chown cassandra:cassandra /var/run/cassandra

cat >/etc/cassandra/conf/cassandra.yaml<<EOF
cluster_name: 'midonet'
num_tokens: 256
hinted_handoff_enabled: true
max_hint_window_in_ms: 10800000 # 3 hours
hinted_handoff_throttle_in_kb: 1024
max_hints_delivery_threads: 2
batchlog_replay_throttle_in_kb: 1024
authenticator: AllowAllAuthenticator
authorizer: AllowAllAuthorizer
permissions_validity_in_ms: 2000
partitioner: org.apache.cassandra.dht.Murmur3Partitioner
data_file_directories:
    - /var/lib/cassandra/data
commitlog_directory: /var/lib/cassandra/commitlog
disk_failure_policy: stop
commit_failure_policy: stop
key_cache_size_in_mb:
key_cache_save_period: 14400
row_cache_size_in_mb: 0
row_cache_save_period: 0
saved_caches_directory: /var/lib/cassandra/saved_caches
commitlog_sync: periodic
commitlog_sync_period_in_ms: 10000
commitlog_segment_size_in_mb: 32
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "${SEEDS}"
concurrent_reads: 32
concurrent_writes: 32
memtable_flush_queue_size: 4
trickle_fsync: false
trickle_fsync_interval_in_kb: 10240
storage_port: 7000
ssl_storage_port: 7001
listen_address: ${IP}
start_native_transport: true
native_transport_port: 9042
start_rpc: true
rpc_address: ${IP}
rpc_port: 9160
rpc_keepalive: true
rpc_server_type: sync
thrift_framed_transport_size_in_mb: 15
incremental_backups: false
snapshot_before_compaction: false
auto_snapshot: true
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000
column_index_size_in_kb: 64
batch_size_warn_threshold_in_kb: 5
in_memory_compaction_limit_in_mb: 64
multithreaded_compaction: false
compaction_throughput_mb_per_sec: 16
compaction_preheat_key_cache: true
read_request_timeout_in_ms: 5000
range_request_timeout_in_ms: 10000
write_request_timeout_in_ms: 2000
cas_contention_timeout_in_ms: 1000
truncate_request_timeout_in_ms: 60000
request_timeout_in_ms: 10000
cross_node_timeout: false
endpoint_snitch: SimpleSnitch
dynamic_snitch_update_interval_in_ms: 100
dynamic_snitch_reset_interval_in_ms: 600000
dynamic_snitch_badness_threshold: 0.1
request_scheduler: org.apache.cassandra.scheduler.NoScheduler
server_encryption_options:
    internode_encryption: none
    keystore: conf/.keystore
    keystore_password: cassandra
    truststore: conf/.truststore
    truststore_password: cassandra
client_encryption_options:
    enabled: false
    keystore: conf/.keystore
    keystore_password: cassandra
internode_compression: all
inter_dc_tcp_nodelay: false
preheat_kernel_page_cache: false

EOF

systemctl enable cassandra.service
systemctl restart cassandra.service || systemctl start cassandra.service

sleep 10

for CS_IP in ${NSDB}; do
    for BACKOFF in $(seq 1 10); do
        #
        # return if the host is found in the nodetool list
        #
        nodetool -host 127.0.0.1 status | grep ^UN | grep "${CS_IP}" && break

        #
        # exponential backoff for dummies
        #
        nodetool -host 127.0.0.1 status | grep ^UN | grep "${CS_IP}" || sleep "$(( ${BACKOFF} * 10 ))"
    done

    #
    # fail if the host was not in nodetool
    #
    nodetool -host 127.0.0.1 status | grep ^UN | grep "${CS_IP}" || exit 1
done

exit 0

