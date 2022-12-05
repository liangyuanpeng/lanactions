#!/bin/bash

#ghcr.io/liangyuanpeng/workspace:$imagetag

IMAGE_EXIST=`oras manifest fetch $IMAGE -uliangyuanpeng -p$GITHUB_TOKEN_PACKAGE | grep mediaType | wc -l `
if [ $IMAGE_EXIST -eq 0 ]; then exit 0;fi

oras pull -uliangyuanpeng -p$GITHUB_TOKEN_PACKAGE $IMAGE --output $1


dir=$(ls *.tar.gz)
for d in ${dir}
do
    echo $d
    tar -xzf $d
    rm -f $d 
done
ls