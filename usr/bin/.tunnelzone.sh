
MEMBERS="${7}"

# midonet-cli -e 'tunnel-zone list' | grep 'name tz' || midonet-cli -e 'tunnel-zone create name tz type vxlan'

TZ="$(midonet-cli -e 'tunnel-zone list' | grep 'name tz' | awk '{print $2;}')"

for MEMBER in ${MEMBERS}; do
    echo "adding member ${MEMBER} to tunnelzone ${TZ}"

    HNAME="$(echo ${MEMBER} | awk -F':' '{print $1;}')"
    HIP="$(echo ${MEMBER} | awk -F':' '{print $2;}')"

    HUID="$(midonet-cli -e "host list name ${HNAME}" | awk '{print $2;}')"

    echo "adding member ${MEMBER} to tunnelzone ${TZ}: ${HNAME} (${HUID}) (${HIP})"

    midonet-cli -e "tunnel-zone ${TZ} add member host ${HUID} address ${HIP}" || echo

done

exit 0

