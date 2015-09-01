#!/bin/bash
ANSWERFILE="${1:-/root/answers.txt}"
CONFIG_KEY="${2}"

CONFIG_VALUE="$(grep -- "^${CONFIG_KEY}=" "${ANSWERFILE}" | head -n1 | sed 's,^'"${CONFIG_KEY}"'=,,g;')"

if [[ "CONFIG_COMPUTE_HOSTS" == "${CONFIG_KEY}" ]]; then
    echo "${CONFIG_VALUE}" | sed 's|,| |g;'
else
    echo "${CONFIG_VALUE}"
fi

