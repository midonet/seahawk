
#
# Welcome to Seattle.
#
all: preflight info install prepare nsdb agents compute gateways controller

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
prepare:
	@$(PSSH)

#
# install network state database
#
nsdb:
	@$(PSSH)

#
# install midonet agents
#
agents:
	@$(PSSH)

#
# configure nova on the compute nodes (install nova-network and set up libvirt qemu tap device access)
#
compute:
	@$(PSSH)

#
# configure veth pairs and SNAT on the gws
#
gateways:
	@$(PSSH)

#
# installs midonet-api, midonet-cli, midonet-manager and configures the midonet plugin on the neutron controller
#
controller:
	@$(PSSH)

#
# includes most of the under-the-hood logic
#
include include/seahawk.mk

