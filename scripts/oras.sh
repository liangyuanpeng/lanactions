#!/bin/bash

function tar_dir(){
    if [ $1 = "czf" ]
    then
    ls -l $2
    dir=$(ls -l $2 |grep "^d" |awk '{print $NF}'|cut -c 1|sort|uniq)
    echo $dir
    cd $2
    for d in ${dir}
    do
        echo $d
        tar -czf ${d}.tar.gz ${d}*
    done
    cd $workspace
    fi

    if [ $1 = "xzf" ]
    then
    cd $2
    dir=$(ls *.tar.gz)
    for d in ${dir}
    do
        echo $d
        tar -xzf $d
        rm -f $d 
    done
    ls
    fi
}

function gethash(){
    hashdir=$1
    if [ $hashdir="" ]
    then
        hashdir=.
    fi  
    echo "get hash for:" $hashdir
    find $hashdir -name "pom.xml" > pomfilesmd5
    touch cachehash && echo "" > cachehash
    # echo "begin write md5 for" `cat pomfilesmd5`
    cat pomfilesmd5 | while read line
    do
        md5sum $line >> cachehash
    done
    rm -f pomfilesmd5

    cat cachehash
}


workspace=$PWD
IMAGE=$2
MAVEN_PACKAGE_HOME=${MAVEN_PACKAGE_HOME-~/.m2/repository}

# 1. command
# 2. image
# 3. cache foilder for command of push-maven

if [ $1 = "push" ]
then
    cd $3 && tar -czvf cache.tar.gz repository/  && mv cache.tar.gz $workspace && cd $workspace

    oras push $IMAGE cache.tar.gz -uyunhorn-bot -p$GITHUB_TOKEN_PACKAGE
    rm -f cache.tar.gz
fi

#sh deploy/scripts/tar.sh czf /root/.m2/repository/  && mkdir -p orastmp && mv /root/.m2/repository/*.tar.gz orastmp/ && cd orastmp && cd ..

if [ $1 = "push-maven" ]
then
    gethash $4
    imagetag=`md5sum cachehash |cut -d ' ' -f1`
    rm -f cachehash
    echo "get the imagetag is:" $imagetag
    #/home/lan/.m2/repository/ca
    echo "MAVEN_PACKAGE_HOME is " $MAVEN_PACKAGE_HOME
    tar_dir czf $MAVEN_PACKAGE_HOME  &&  mkdir -p $3 && mv $MAVEN_PACKAGE_HOME/*.tar.gz $3
    cd $3 
    oras push $IMAGE:$imagetag `ls` -uyunhorn-bot -p$GITHUB_TOKEN_PACKAGE
    cd $workspace
    rm -rf $3
fi

if [ $1 = "pull" ]
then 
    oras pull  --plain-http  $IMAGE --output $3
fi

if [ $1 = "check" ]
then
  oras manifest fetch $IMAGE
fi 



