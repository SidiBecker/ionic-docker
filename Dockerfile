FROM alpine/java:21-jdk
MAINTAINER sidibecker [at] hotmail [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_DIR=/opt/android \
    NPM_VERSION=8.19.4 \
    IONIC_VERSION=latest \
    CORDOVA_VERSION=10.0.0 \
    GRADLE_VERSION=8.7 \
    ANDROID_COMPILE_SDK=34 \
    ANDROID_BUILD_TOOLS=34.0.0 \
    ALPINE_REPOSITORY_VERSION=v3.9 \
    NODE_JS_VERSION=16.20.2 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null 

ENV  NODE_PACKAGE_URL=https://unofficial-builds.nodejs.org/download/release/v"$NODE_JS_VERSION"/node-v"$NODE_JS_VERSION"-linux-x64-musl.tar.gz

# Timezone
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
RUN echo "America/Sao_Paulo" > /etc/timezone
RUN date

RUN echo "https://dl-cdn.alpinelinux.org/alpine/$ALPINE_REPOSITORY_VERSION/main/" >> /etc/apk/repositories

RUN more /etc/apk/repositories

# Install basics
RUN apk update 
RUN apk add --no-cache --upgrade bash
RUN apk add expect apache-ant wget libgcc qemu kmod util-linux

RUN apk add --virtual build-dependencies
RUN apk add git wget curl unzip jq 

WORKDIR /opt
RUN wget $NODE_PACKAGE_URL -O nodejs.tar.gz
RUN mkdir -p /opt/nodejs
RUN tar -zxvf nodejs.tar.gz --directory /opt/nodejs --strip-components=1
RUN rm nodejs.tar.gz
RUN ln -s /opt/nodejs/bin/node /usr/local/bin/node
RUN ln -s /opt/nodejs/bin/npm /usr/local/bin/npm

WORKDIR /
RUN apk add npm
RUN apk update &&  \
    npm install -g \ 
    npm@"$NPM_VERSION" \
    cordova@"$CORDOVA_VERSION" \
    @ionic/cli@"$IONIC_VERSION" && \
    npm cache clear --force && \
    mkdir Sources && \
    mkdir -p /root/.cache/yarn/  

# Set the locale
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Python instalation
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3  py-pip && ln -sf python3 /usr/bin/python
RUN apk add py3-pillow
RUN pip list

WORKDIR /

RUN  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android Tools
RUN mkdir $ANDROID_DIR && cd $ANDROID_DIR && \
    wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip -q android-tools-sdk.zip && \
    rm -f android-tools-sdk.zip  && \
    mv cmdline-tools latest && \
    mkdir sdk && \
    mkdir sdk/cmdline-tools && \
    mv latest sdk/cmdline-tools


# Install Gradle
RUN mkdir /opt/gradle && cd /opt/gradle && \
    wget --output-document=gradle.zip --quiet https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
    unzip -q gradle.zip && \
    rm -f gradle.zip && \
    chown -R root. /opt


# Setup environment
ENV ANDROID_HOME "${ANDROID_DIR}/sdk"
ENV ANDROID_SDK_ROOT "${ANDROID_DIR}/sdk"
ENV PATH ${PATH}:${ANDROID_HOME}:${ANDROID_HOME}/cmdline-tools:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}:/opt/gradle/gradle-${GRADLE_VERSION}/bin

# Install Android SDK
RUN yes Y | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS" "platforms;android-$ANDROID_COMPILE_SDK" "platform-tools"

WORKDIR Sources
