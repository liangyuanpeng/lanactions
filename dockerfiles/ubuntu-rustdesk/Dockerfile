# 基础镜像
FROM ubuntu:20.04
# 维护者信息
MAINTAINER liangyuanpeng <liangyuanpengem@163.com>

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    SIZE=1024x768 \
    PASSWD=123456 \
    TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=${LANG} \
    LANGUAGE=${LANG}

USER root
WORKDIR /root

# 设定密码
RUN echo "root:$PASSWD" | chpasswd

RUN apt-get -y update && \
    apt-get install -y vim git subversion wget curl net-tools locales bzip2 unzip iputils-ping traceroute firefox firefox-locale-zh-hans ttf-wqy-microhei gedit ibus-pinyin && \
    locale-gen zh_CN.UTF-8 && \
    # xfce
    apt-get install -y xfce4 xfce4-terminal && \
    apt-get purge -y pm-utils xscreensaver* && \
    # Rustdesk
    apt install -y libxcb-randr0 libxdo3 python3-pip && \
    wget https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.deb && \
    apt-get install -y -f ./rustdesk-1.1.9.deb && \
    rm -f *.deb && \
    apt install -y ubuntu-desktop && \
    # clean
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 配置xfce图形界面
ADD ./xfce/ /root/

# 用户目录不使用中文
RUN LANG=C xdg-user-dirs-update --force

# COPY idea.tar.gz idea.tar.gz
# RUN mv idea.tar.gz soft/ && cd soft && tar -xzf idea.tar.gz
# RUN cd soft && wget https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz && tar -xzf apache-maven-3.8.6-bin.tar.gz
# RUN cd soft && wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jdk_x64_linux_hotspot_17.0.5_8.tar.gz && tar -xzf OpenJDK17U-jdk_x64_linux_hotspot_17.0.5_8.tar.gz
# RUn cd soft &&  rm -f *.gz

# 启动脚本
# CMD ["/root/startup.sh"]

