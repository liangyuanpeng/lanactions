#!/bin/bash
curl -X POST  -F file=@/tmp/admin.conf -F "initial_comment=Hello, Leadville" -F channels=$SLACK_CHANNEL -H "Authorization: Bearer $SLACK_TOKEN" https://slack.com/api/files.upload