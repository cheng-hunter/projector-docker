#
# Copyright 2019-2020 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM debian:10

ARG ideUrl
ARG jdkUrl
ARG goUrl
ARG projectorUrl


RUN true \
# Any command which returns non-zero exit code will cause this shell script to exit immediately:
   && set -e \
# Activate debugging to show execution details: all commands will be printed before execution
   && set -x \
   && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
# install packages:
    && apt-get update \
    && apt-get install wget unzip  -y \	
# packages for awt:
    && apt-get install libxext6 libxrender1 libxtst6 libxi6 libfreetype6 -y \
# packages for user convenience:
    && apt-get install git bash-completion -y \
# packages for IDEA (to disable warnings):
    && apt-get install procps -y \
	&& if [ "${ideUrl#*CLion}" != "$ideUrl" ]; then apt-get install build-essential clang -y; else echo "Not CLion"; fi \
    && if [ "${ideUrl#*pycharm}" != "$ideUrl" ]; then apt-get install python2 python3 python3-distutils python3-pip python3-setuptools -y; else echo "Not pycharm"; fi \
    && if [ "${ideUrl#*rider}" != "$ideUrl" ]; then apt install apt-transport-https dirmngr gnupg ca-certificates -y && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list && apt update && apt install mono-devel -y && apt install wget -y && wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && apt-get update && apt-get install -y apt-transport-https && apt-get update && apt-get install -y dotnet-sdk-3.1 aspnetcore-runtime-3.1; else echo "Not rider"; fi \
# clean apt to reduce image size:
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt


# copy the Projector dir:
ENV PROJECTOR_DIR /projector
RUN mkdir  $PROJECTOR_DIR


# download ide
RUN wget -q $ideUrl -O $PROJECTOR_DIR/ide.tar.gz && tar -xvf $PROJECTOR_DIR/ide.tar.gz -C $PROJECTOR_DIR/  \
          && rm -rf $PROJECTOR_DIR/ide.tar.gz \
          && find $PROJECTOR_DIR  -maxdepth 1 -type d ! -name *projector* -exec mv {} $PROJECTOR_DIR/ide \;


# download jdk
RUN if [ "${ideUrl#*idea}" != "$ideUrl" ]; then \
    wget -q $jdkUrl -O $PROJECTOR_DIR/jdk.tar.gz && tar -xvf $PROJECTOR_DIR/jdk.tar.gz -C $PROJECTOR_DIR/  \
    && rm -rf $PROJECTOR_DIR/jdk.tar.gz \
    && find $PROJECTOR_DIR/  -maxdepth 1 -type d -name "*jdk*" -exec mv {} $PROJECTOR_DIR/jdk \;  \
	
	&& wget -q $goUrl -O $PROJECTOR_DIR/go.tar.gz && tar -xvf $PROJECTOR_DIR/go.tar.gz -C $PROJECTOR_DIR/  \
    && rm -rf $PROJECTOR_DIR/go.tar.gz ;\
	fi 

		  
# download go
RUN if [ "${ideUrl#*go}" != "$ideUrl" ]; then \ 
    wget -q $goUrl -O $PROJECTOR_DIR/go.tar.gz && tar -xvf $PROJECTOR_DIR/go.tar.gz -C $PROJECTOR_DIR/  \
    && rm -rf $PROJECTOR_DIR/go.tar.gz ;\
    fi



RUN if [ "${ideUrl#*idea}" != "$ideUrl" ]; then \      
    echo "export JAVA_HOME=$PROJECTOR_DIR/jdk" >> /etc/profile \
    &&echo "export PATH=\${JAVA_HOME}/bin:$PATH">> /etc/profile \
    &&echo "export CLASSPATH=.:\${JAVA_HOME}/lib/dt.jar:\${JAVA_HOME}/lib/tools.jar">> /etc/profile \
	
	&&echo "export GOROOT=$PROJECTOR_DIR/go" >> /etc/profile \
    &&echo "export GOBIN=$GOROOT/bin" >> /etc/profile  \
    &&echo "export GOOS=linux" >> /etc/profile \
    &&echo "export PATH=.:$PATH:$GOBIN" >> /etc/profile  ; fi


RUN if [ "${ideUrl#*go}" != "$ideUrl" ]; then \      
	echo "export GOROOT=$PROJECTOR_DIR/go" >> /etc/profile \
    &&echo "export GOBIN=$GOROOT/bin" >> /etc/profile  \
    &&echo "export GOOS=linux" >> /etc/profile \
    &&echo "export PATH=.:$PATH:$GOBIN" >> /etc/profile  ; fi

# download projector-server 
RUN wget -q $projectorUrl -O $PROJECTOR_DIR/ide/projector-server.zip && unzip $PROJECTOR_DIR/ide/projector-server.zip -d $PROJECTOR_DIR/ide/  \
    && rm -rf $PROJECTOR_DIR/ide/projector-server.zip \
    && find $PROJECTOR_DIR/ide/  -maxdepth 1 -type d -name projector-server-* -exec mv {} $PROJECTOR_DIR/ide/projector-server \;



ADD projector-docker/static $PROJECTOR_DIR
RUN mv $PROJECTOR_DIR/ide-projector-launcher.sh $PROJECTOR_DIR/ide/bin
RUN chmod 644 $PROJECTOR_DIR/ide/projector-server/lib/*





ENV PROJECTOR_USER_NAME projector-user

RUN true \
# Any command which returns non-zero exit code will cause this shell script to exit immediately:
    && set -e \
# Activate debugging to show execution details: all commands will be printed before execution
    && set -x \
# move run scipt:
    && mv $PROJECTOR_DIR/run.sh run.sh \
# change user to non-root (http://pjdietz.com/2016/08/28/nginx-in-docker-without-root.html):
    && mv $PROJECTOR_DIR/$PROJECTOR_USER_NAME /home \
    && useradd -m -d /home/$PROJECTOR_USER_NAME -s /bin/bash $PROJECTOR_USER_NAME \
    && chown -R $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME /home/$PROJECTOR_USER_NAME \
    && chown -R $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME $PROJECTOR_DIR/ide/bin \
    && chown $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME run.sh

USER $PROJECTOR_USER_NAME
ENV HOME /home/$PROJECTOR_USER_NAME

EXPOSE 8887

CMD ["bash", "-c", "/run.sh"]
