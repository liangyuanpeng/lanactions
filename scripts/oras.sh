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
#    find $hashdir -name "pom.xml" > pomfilesmd5
    find $hashdir -name $2 > pomfilesmd5
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
JDKS_HOME=${JDKS_HOME-~/.jdks}

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
    gethash $4 "pom.xml"
    imagetag=`md5sum cachehash |cut -d ' ' -f1`
    rm -f cachehash
    echo "get the imagetag is:" $imagetag
    #/home/lan/.m2/repository/ca
    echo "MAVEN_PACKAGE_HOME is " $MAVEN_PACKAGE_HOME
    tar_dir czf $MAVEN_PACKAGE_HOME  &&  mkdir -p $3 && mv $MAVEN_PACKAGE_HOME/*.tar.gz $3
    cd $3 
    oras push $IMAGE:$imagetag `ls` -u$OCI_USERNAME -p$GITHUB_TOKEN_PACKAGE
    cd $workspace
    rm -rf $3
fi

if [ $1 = "push-maven-latest" ]
then
    gethash $4 "pom.xml"
    imagetag="latest"
    rm -f cachehash
    echo "get the imagetag is:" $imagetag
    echo "MAVEN_PACKAGE_HOME is " $MAVEN_PACKAGE_HOME
    tar_dir czf $MAVEN_PACKAGE_HOME  &&  mkdir -p $3 && mv $MAVEN_PACKAGE_HOME/*.tar.gz $3
    cd $3 
    oras push $IMAGE:$imagetag `ls` -u$OCI_USERNAME -p$GITHUB_TOKEN_PACKAGE
    cd $workspace
    rm -rf $3
fi

#GITHUB_TOKEN_PACKAGE= scripts/oras.sh push-jdk ghcr.io/liangyuanpeng/jdk orastmp ~/.jdks/temurin-17.0.3.7 temurin-17.0.3.7

if [ $1 = "push-jdk" ]
then
    gethash $4 "release"
    imagetag=$5
    rm -f cachehash
    echo "get the imagetag is:" $imagetag
    tar_dir czf $4  &&  mkdir -p $3 && mv $4/*.tar.gz $3
    cd $3 
    oras push $IMAGE:$imagetag `ls` -u$OCI_USERNAME -p$GITHUB_TOKEN_PACKAGE
    cd $workspace
    rm -rf $3
fi

#GITHUB_TOKEN_PACKAGE= scripts/oras.sh push-jdk ghcr.io/liangyuanpeng/jdk orastmp ~/soft/idea-IC-221.5787.30 idea-IC-221.5787.30
if [ $1 = "push-idea" ]
then
    gethash $4 "build.txt"
    imagetag=$5
    rm -f cachehash
    echo "get the imagetag is:" $imagetag
    tar_dir czf $4  &&  mkdir -p $3 && mv $4/*.tar.gz $3
    cd $3 
    oras push $IMAGE:$imagetag `ls` -u$OCI_USERNAME -p$GITHUB_TOKEN_PACKAGE
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



