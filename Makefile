
#
# Welcome to Seattle.
#
all: preflight info install prepare nsdb agents compute gateways controller manager tunnelzone
	midonet-cli -e host list

info:
	@echo deploying to
	@echo
	@echo controller: $(CONFIG_CONTROLLER_HOST)
	@echo compute nodes: $(CONFIG_COMPUTE_HOSTS)
	@echo

#
# prepare this local box
#
install:
	yum list installed | grep ^pssh.noarch || yum install -y pssh

#
# prepare the remote machines (install software etc)
#
prepare: preflight
	@$(PSSH)

#
# install network state database
#
nsdb: preflight
	$(PSSH)

#
# install midonet agents
#
agents: preflight
	@$(PSSH)

#
# configure nova on the compute nodes (install nova-network and set up libvirt qemu tap device access)
#
compute: preflight
	@$(PSSH)

#
# configure veth pairs and SNAT on the gws
#
gateways: preflight
	@$(PSSH)

#
# installs midonet-api, midonet-cli and configures the midonet plugin on the neutron controller
#
controller: preflight
	@$(PSSH)

#
# installs midonet-manager
#
manager: preflight
	@$(PSSH)

#
# adds the ip of the hosts to the tunnelzone
#
tunnelzone: preflight
	@$(PSSH)

#
# includes most of the under-the-hood logic
#
include include/seahawk.mk

