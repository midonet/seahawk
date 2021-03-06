#!/bin/bash

#
# the content of this script is autogenerated from a header (..header.sh) and a dotfile (.xxx.sh)
#
# DO NOT EDIT THIS SCRIPT FILE
#
# to edit the original of this script file look for files in usr/bin starting with a dot (.)
#

OS_MIDOKURA_REPOSITORY_USER="${1:-demo}"
OS_MIDOKURA_REPOSITORY_PASS="${2:-demo}"

CONTROLLERS="${3:-127.0.0.1}"
COMPUTE="${4:-127.0.0.1}"
GATEWAYS="${5:-127.0.0.1}"
NSDB="${6:-127.0.0.1}"

cat <<EOF

MEM USER: ${OS_MIDOKURA_REPOSITORY_USER}
MEM PASS: ${OS_MIDOKURA_REPOSITORY_PASS}

RUNNING SCRIPT ${0} on $(hostname) ($(hostname -f))

CONTROLLER: ${CONTROLLERS}
COMPUTE: ${COMPUTE}
GATEWAYS: ${GATEWAYS}
NSDB: ${NSDB}

DEBUG FLAG: ${DEBUG}
VERBOSE FLAG: ${VERBOSE}

EOF

IP="$(ip addr show | grep 'inet ' | grep -v 'inet 127.0' | head -n1 | awk '{print $2;}' | awk -F'/' '{print $1;}')"

ZK=""
CS=""

CS_COUNT=0

for ZK_IP in ${NSDB}; do
    CS_COUNT="$(( ${CS_COUNT} + 1 ))"

    if [[ "" == "${ZK}" ]]; then
        ZK="${ZK_IP}:2181"
        CS="${ZK_IP}"
    else
        ZK="${ZK},${ZK_IP}:2181"
        CS="${CS},${ZK_IP}"
    fi
done

#
# the content of this script is autogenerated from a header (..header.sh) and a dotfile (.xxx.sh)
#
# DO NOT EDIT THIS SCRIPT FILE
#
# to edit the original of this script file look for files in usr/bin starting with a dot (.)
#

