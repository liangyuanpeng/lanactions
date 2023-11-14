#/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ACTIONS_COMMON_SLEEP=${ACTIONS_COMMON_SLEEP:-"3h"}
echo "begin sleep "$ACTIONS_COMMON_SLEEP
sleep $ACTIONS_COMMON_SLEEP