
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

PREPAREFILES = $(SERVERFILES) $(TMPDIR)/prepare.txt

AGENTFILES = $(SERVERFILES) $(TMPDIR)/agents.txt

.PHONY: $(SERVERFILES) $(PREPAREFILES) $(AGENTFILES)

preflight: $(SERVERFILES) $(PREPAREFILES) $(AGENTFILES)
	test -f "$(ANSWERFILE)" || exit 1

$(TMPDIR):
	@mkdir -pv $(TMPDIR)

DEDUP = xargs --no-run-if-empty -n1 -- echo | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 -- | uniq -- | tee --

$(TMPDIR)/controller.txt: $(TMPDIR)
	echo "$(CONFIG_CONTROLLER_HOST)" | $(DEDUP) $(@)

$(TMPDIR)/compute.txt: $(TMPDIR)
	echo "$(CONFIG_COMPUTE_HOSTS)" | $(DEDUP) $(@)

$(TMPDIR)/gateways.txt: $(TMPDIR)
	cat conf/gateways.txt | $(DEDUP) $(@)

$(TMPDIR)/nsdb.txt: $(TMPDIR)
	(echo "$(CONFIG_CONTROLLER_HOST)"; echo "$(CONFIG_COMPUTE_HOSTS)") | $(DEDUP) $(@)

$(TMPDIR)/prepare.txt: $(TMPDIR) $(SERVERFILES)
	cat $(SERVERFILES) | $(DEDUP) $(@)

$(TMPDIR)/agents.txt: $(TMPDIR) $(SERVERFILES)
	cat $(SERVERFILES) | $(DEDUP) $(@)

#
#  parallel-ssh options
#
PSSH_OPTS = -O StrictHostKeyChecking=no

#
# role memberships as shell arguments to the scripts, whitespace separated
#
ROLES = "$(shell cat $(TMPDIR)/controller.txt)" "$(shell cat $(TMPDIR)/compute.txt)" "$(shell cat $(TMPDIR)/gateways.txt)" "$(shell cat $(TMPDIR)/nsdb.txt)"

#
# this macro will show the list
#
PSSH0 = cat "$(TMPDIR)/$(@).txt" | awk '{ print ">>> running pssh task '"$(@)"' on machine [" $$0 "]"; }'

#
# this macro will be used by prepare steps and role install steps
#
PSSH1 = pssh $(PSSH_OPTS) -I --hosts="$(TMPDIR)/$(@).txt" -- "tee /tmp/$(@).sh | chmod 0755 /tmp/$(@).sh" <"usr/bin/$(@).sh" 1>/dev/null

#
# upload the script to the destination box
#
PSSH2 = pssh $(PSSH_OPTS) --print -v --hosts="$(TMPDIR)/$(@).txt" -- "/tmp/$(@).sh" "$(OS_MIDOKURA_REPOSITORY_USER)" "$(OS_MIDOKURA_REPOSITORY_PASS)" $(ROLES)

#
# run the script of the role for this box
#
PSSH = echo "running pssh task $(@)" && $(PSSH0) && $(PSSH1) && $(PSSH2)

