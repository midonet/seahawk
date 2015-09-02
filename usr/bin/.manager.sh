
yum install -y midonet-manager

yum install -y httpd

CIP="$(echo ${CONTROLLERS} | xargs -n1 echo | head -n1)"

cat >/var/www/html/midonet-manager/config/client.js<<EOF

{
  "api_host": "http://${CIP}:8181",
  "login_host": "http://${CIP}:8181",
  "trace_api_host": "http://${CIP}:8181",
  "traces_ws_url": "ws://${CIP}:8460",
  "api_namespace": "midonet-api",
  "api_version": "1.9",
  "api_token": false,
  "agent_config_api_host": "http://${CIP}:8459",
  "agent_config_api_namespace": "conf",
  "poll_enabled": true
}

EOF

systemctl enable httpd
systemctl restart httpd || systemctl start httpd

cat /var/www/html/midonet-manager/config/client.js

exit 0

