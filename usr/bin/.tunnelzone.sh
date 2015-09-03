
MEMBERS="${CONTROLLERS} ${COMPUTE} ${GATEWAYS}"

# midonet-cli -e 'tunnel-zone list' | grep 'name tz' || midonet-cli -e 'tunnel-zone create name tz type vxlan'

TZ="$(midonet-cli -e 'tunnel-zone list' | grep 'name tz' | awk '{print $2;}')"

for MEMBER in ${MEMBERS}; do
    HNAME="$(ssh -o StrictHostKeyChecking=no -q "${MEMBER}" hostname)"
    HIP="${MEMBER}"

    HUID="$(midonet-cli -e "host list name ${HNAME}" | awk '{print $2;}')"

    echo "adding member ${MEMBER} to tunnelzone ${TZ}: ${HNAME} (${HUID}) (${HIP})"

    midonet-cli -e "tunnel-zone ${TZ} add member host ${HUID} address ${HIP}" || echo

done

exit 0

