
#
# temp directory to store server lists as text files
#
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

SERVERFILES = $(TMPDIR)/controller.txt $(TMPDIR)/compute.txt $(TMPDIR)/gateways.txt $(TMPDIR)/nsdb.txt

.PHONY: $(SERVERFILES)

preflight: $(SERVERFILES)
	test -f "$(ANSWERFILE)" || exit 1

$(TMPDIR):
	@mkdir -pv $(TMPDIR)

$(TMPDIR)/controller.txt: $(TMPDIR)
	echo "$(CONFIG_CONTROLLER_HOST)" > $(@)

$(TMPDIR)/compute.txt: $(TMPDIR)
	echo "$(CONFIG_COMPUTE_HOSTS)" > $(@)

$(TMPDIR)/gateways.txt: $(TMPDIR)
	cat conf/gateways.txt > $(@)

$(TMPDIR)/nsdb.txt: $(TMPDIR)
	(echo "$(CONFIG_CONTROLLER_HOST)"; echo "$(CONFIG_COMPUTE_HOSTS)") | sort | uniq > $(@)

#
# the pssh macro to run the scripts on the machines
#
PSSH_OPTS = -O StrictHostKeyChecking=no

ROLES = "$(shell cat $(TMPDIR)/controller.txt)" "$(shell cat $(TMPDIR)/compute.txt)" "$(shell cat $(TMPDIR)/gateways.txt)" "$(shell cat $(TMPDIR)/nsdb.txt)"

#
# prepare script (will install epel, MEM repo and puppet module from forge)
#
PSSH1 = pssh $(PSSH_OPTS) -I --hosts="$(TMPDIR)/$(@).txt" -- "tee /tmp/prepare.sh | chmod 0755 /tmp/prepare.sh" <"usr/bin/prepare.sh"
PSSH2 = pssh $(PSSH_OPTS) -i -v --hosts="$(TMPDIR)/$(@).txt" -- "/tmp/prepare.sh" $(ROLES)

#
# run the script of the role for this box
#
PSSH3 = pssh $(PSSH_OPTS) -I --hosts="$(TMPDIR)/$(@).txt" -- "tee /tmp/$(@).sh | chmod 0755 /tmp/$(@).sh" <"usr/bin/$(@).sh"
PSSH4 = pssh $(PSSH_OPTS) -i -v --hosts="$(TMPDIR)/$(@).txt" -- "/tmp/$(@).sh" $(ROLES)

PSSH = echo "running pssh task $(@)" && $(PSSH1) && $(PSSH2) && $(PSSH3) && $(PSSH4)

