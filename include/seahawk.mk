
#
# the pssh macro to run the scripts on the machines
#
PSSH_OPTS = -O StrictHostKeyChecking=no

PSSH1 = pssh $(PSSH_OPTS) -I --hosts="tmp/$(@).txt" -- "tee /tmp/$(@).sh | chmod 0755 /tmp/$(@).sh" <"usr/bin/$(@).sh"

PSSH2 = pssh $(PSSH_OPTS) -i -v --hosts="tmp/$(@).txt" -- "/tmp/$(@).sh"

PSSH = echo "running pssh task $(@)" && $(PSSH1) && $(PSSH2)

TMPDIR = tmp

#
# the packstack answer file
#
ifeq "$(ANSWERFILE)" ""
	ANSWERFILE = /root/answers.txt
endif

ifeq "$(CONFIG_COMPUTE_HOSTS)" ""
	CONFIG_COMPUTE_HOSTS = $(shell bin/answer.sh "$(ANSWERFILE)" "CONFIG_COMPUTE_HOSTS")
endif

ifeq "$(CONFIG_CONTROLLER_HOST)" ""
	CONFIG_CONTROLLER_HOST = $(shell bin/answer.sh "$(ANSWERFILE)" "CONFIG_CONTROLLER_HOST")
endif

SERVERFILES = tmp/controller.txt tmp/compute.txt tmp/gateways.txt tmp/nsdb.txt

.PHONY: $(SERVERFILES)

preflight: $(SERVERFILES)

$(TMPDIR):
	@mkdir -pv $(TMPDIR)

tmp/controller.txt: $(TMPDIR)
	echo "$(CONFIG_CONTROLLER_HOST)" > $(@)

tmp/compute.txt: $(TMPDIR)
	echo "$(CONFIG_COMPUTE_HOSTS)" > $(@)

tmp/gateways.txt: $(TMPDIR)
	cat conf/gateways.txt > $(@)

tmp/nsdb.txt: $(TMPDIR)
	(echo "$(CONFIG_CONTROLLER_HOST)"; echo "$(CONFIG_COMPUTE_HOSTS)") | sort | uniq > $(@)

