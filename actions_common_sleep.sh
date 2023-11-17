#/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#/bin/bash

set -o errexit
set -o nounset
set -o pipefail

function util::initenv(){
  if [ -f .env ];then 
    #cat .env
    while read line; do
      # 用等号分割键值对
      if [ "$line" = "" ];then 
        continue
      fi

      prefix="#"

      if [[ $line =~ ^$prefix ]]; then
        continue
      fi

      key=$(echo $line | cut -d'=' -f1)
      value=$(echo $line | cut -d'=' -f2)
      # echo "key:"$key",value:"$value
      # 导出变量
      export $key="$value"
    done < .env
  fi
}

util::initenv

ACTIONS_COMMON_SLEEP=${ACTIONS_COMMON_SLEEP:-"1s"}
echo "begin sleep "$ACTIONS_COMMON_SLEEP
sleep $ACTIONS_COMMON_SLEEP


