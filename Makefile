
#
# Welcome to Seattle.
#
all: preflight info install nsdb compute gateways controller

info:
	@echo deploying to controller $(CONFIG_CONTROLLER_HOST) and compute nodes: $(CONFIG_COMPUTE_HOSTS)

install:
	yum list installed pssh | grep ^pssh.noarch || yum install -y pssh

controller:
	@$(PSSH)

compute:
	@$(PSSH)

gateways:
	@$(PSSH)

nsdb:
	@$(PSSH)

#
# includes most of the under-the-hood logic
#
include include/seahawk.mk

