#!/bin/bash

#ghcr.io/liangyuanpeng/workspace:$imagetag


if [ $1 = "rebuild" ]
then
    IMAGE_EXIST=`oras manifest fetch $2 -uliangyuanpeng -p$GITHUB_TOKEN_PACKAGE | grep mediaType | wc -l `
    if [ $IMAGE_EXIST -eq 0 ]; then exit 0;fi

    oras pull -uliangyuanpeng -p$GITHUB_TOKEN_PACKAGE $IMAGE --output $3

    dir=$(ls *.tar.gz)
    for d in ${dir}
    do
        echo $d
        tar -xzf $d
        rm -f $d 
    done
    ls
fi

if [ $1 = "restore" ]
then
    tar -czf tekton.tar.gz tekton
    oras push -uliangyuanpeng -p$GITHUB_TOKEN_PACKAGE $2 tekton.tar.gz 
fi 