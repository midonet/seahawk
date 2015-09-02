
ADMIN_TOKEN="$(grep '^admin_token = ' /etc/keystone/keystone.conf | tail -n1 | awk '{print $3;}' | xargs -n1 echo)"

yum install -y midonet-api

cat >/usr/share/midonet-api/WEB-INF/web.xml <<EOF
<!DOCTYPE web-app PUBLIC
 "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN"
 "http://java.sun.com/dtd/web-app_2_3.dtd" >

<web-app>
  <display-name>MidoNet API</display-name>

  <context-param>
    <param-name>rest_api-base_uri</param-name>
    <param-value>http://${IP}:8181/midonet-api</param-value>
  </context-param>

  <context-param>
    <param-name>cors-access_control_allow_origin</param-name>
    <param-value>*</param-value>
  </context-param>

  <context-param>
    <param-name>cors-access_control_allow_headers</param-name>
    <param-value>Origin, X-Auth-Token, Content-Type, Accept, Authorization</param-value>
  </context-param>

  <context-param>
    <param-name>cors-access_control_allow_methods</param-name>
    <param-value>GET, POST, PUT, DELETE, OPTIONS</param-value>
  </context-param>

  <context-param>
    <param-name>cors-access_control_expose_headers</param-name>
    <param-value>Location</param-value>
  </context-param>

  <context-param>
    <param-name>auth-auth_provider</param-name>
    <param-value>org.midonet.api.auth.keystone.v2_0.KeystoneService</param-value>
  </context-param>
  <context-param>
    <param-name>auth-admin_role</param-name>
    <param-value>admin</param-value>
  </context-param>

  <context-param>
    <param-name>keystone-service_protocol</param-name>
    <param-value>http</param-value>
  </context-param>
  <context-param>
    <param-name>keystone-service_host</param-name>
    <param-value>${IP}</param-value>
  </context-param>
  <context-param>
    <param-name>keystone-service_port</param-name>
    <param-value>35357</param-value>
  </context-param>
  <context-param>
    <param-name>keystone-admin_token</param-name>
    <param-value>${ADMIN_TOKEN}</param-value>
  </context-param>
  <context-param>
    <param-name>keystone-tenant_name</param-name>
    <param-value>admin</param-value>
  </context-param>

  <context-param>
    <param-name>zookeeper-use_mock</param-name>
    <param-value>false</param-value>
  </context-param>

  <context-param>
    <param-name>zookeeper-zookeeper_hosts</param-name>
    <param-value>${ZK}</param-value>
  </context-param>

  <context-param>
    <param-name>zookeeper-session_timeout</param-name>
    <param-value>30000</param-value>
  </context-param>

  <context-param>
    <param-name>zookeeper-midolman_root_key</param-name>
    <param-value>/midonet/v1</param-value>
  </context-param>

  <context-param>
    <param-name>zookeeper-curator_enabled</param-name>
    <param-value>true</param-value>
  </context-param>

  <context-param>
    <param-name>midocluster-properties_file</param-name>
    <param-value>/var/lib/tomcat/webapps/host_uuid.properties</param-value>
  </context-param>

  <context-param>
    <param-name>midocluster-vxgw_enabled</param-name>
    <param-value>true</param-value>
  </context-param>

  <listener>
     <listener-class>
         org.midonet.api.servlet.JerseyGuiceServletContextListener
     </listener-class>
  </listener>

  <filter>
    <filter-name>Guice Filter</filter-name>
    <filter-class>com.google.inject.servlet.GuiceFilter</filter-class>
  </filter>

  <filter-mapping>
    <filter-name>Guice Filter</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>

</web-app>

EOF

yum install -y tomcat

cat > /etc/tomcat/server.xml<<EOF
<?xml version='1.0' encoding='utf-8'?>
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JasperListener" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <Service name="Catalina">
    <Connector port="8181" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443"
               maxHttpHeaderSize="65536" />
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
EOF

cat >/etc/tomcat/Catalina/localhost/midonet-api.xml<<EOF
<Context
    path="/midonet-api"
    docBase="/usr/share/midonet-api"
    antiResourceLocking="false"
    privileged="true" />
EOF

systemctl enable tomcat.service
systemctl restart tomcat.service || systemctl start tomcat.service

yum install -y python-midonetclient

yum install -y expect

. /root/keystonerc_admin

cat >/root/.midonetrc<<EOF
[cli]
api_url = http://${IP}:8181/midonet-api
username = ${OS_USERNAME}
password = ${OS_PASSWORD}
project_id = admin
EOF

midonet-cli -e 'tunnel-zone list' | grep 'name tz' || midonet-cli -e 'tunnel-zone create name tz type vxlan'

openstack service create --name midonet --description "MidoNet API Service" midonet

openstack user create --project services --password "Midokura" "midonet"

openstack role add --project services --user midonet admin

yum install -y openstack-neutron python-neutron-plugin-midonet

sed -i 's,^core_plugin.*,core_plugin = neutron.plugins.midonet.plugin.MidonetPluginV2,g' /etc/neutron/neutron.conf

sed -i 's,^service_plugins.*,service_plugins = ,g' /etc/neutron/neutron.conf

mkdir /etc/neutron/plugins/midonet

DB="$(grep '^connection = mysql' /etc/neutron/neutron.conf | tail -n1 | awk '{print $3;}')"

cat >/etc/neutron/plugins/midonet/midonet.ini<<EOF
[DATABASE]
sql_connection = ${DB}

[MIDONET]
midonet_uri = http://${IP}:8181/midonet-api
username = midonet
password = Midokura
project_id = services
EOF

ln -sfv /etc/neutron/plugins/midonet/midonet.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/midonet/midonet.ini upgrade kilo" neutron

yum install python-neutron-lbaas

if [[ "" == "$(grep "LOADBALANCER:Midonet" /etc/neutron/neutron.conf)" ]]; then
    cat >>/etc/neutron/neutron.conf<<EOF
[service_providers]
service_provider = LOADBALANCER:Midonet:midonet.neutron.services.loadbalancer.driver.MidonetLoadbalancerDriver:default
EOF
fi

#
# DHCP agent
#
cat >/etc/neutron/dhcp_agent.ini<<EOF
[DEFAULT]
debug = False
resync_interval = 30

enable_metadata_network = False
dhcp_domain = openstacklocal
dnsmasq_config_file =/etc/neutron/dnsmasq-neutron.conf
dhcp_delete_namespaces = False
root_helper=sudo neutron-rootwrap /etc/neutron/rootwrap.conf
state_path=/var/lib/neutron

interface_driver = neutron.agent.linux.interface.MidonetInterfaceDriver
dhcp_driver = midonet.neutron.agent.midonet_driver.DhcpNoOpDriver
use_namespaces = True
enable_isolated_metadata = True

[MIDONET]
midonet_uri = http://${IP}:8181/midonet-api
username = midonet
password = Midokura
project_id = services
EOF

systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service

systemctl enable neutron-metadata-agent.service
systemctl start neutron-metadata-agent.service

systemctl enable neutron-dhcp-agent.service
systemctl start neutron-dhcp-agent.service

systemctl enable neutron-server.service

systemctl restart neutron-server.service || systemctl start neutron-server.service

exit 0

