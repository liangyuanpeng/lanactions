#!/bin/bash

#$KUBECONFIG
echo "slack.sh" $SLACK_CHANNEL
echo "slack.sh" $SLACKT_TOKEN

curl -X POST  -F file=@/tmp/admin.conf -F "init kind success!" -F channels=$SLACK_CHANNEL -H "Authorization: Bearer $SLACK_TOKEN" https://slack.com/api/files.upload