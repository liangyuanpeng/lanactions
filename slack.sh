#!/bin/bash

#$KUBECONFIG
echo SLACK_CHANNEL

curl -X POST  -F file=@/tmp/admin.conf -F "init kind success!" -F channels=$SLACK_CHANNEL -H "Authorization: Bearer $SLACK_TOKEN" https://slack.com/api/files.upload