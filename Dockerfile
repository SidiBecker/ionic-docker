FROM sidibecker/ubuntu22-jdk21-node16
MAINTAINER sidibecker [at] hotmail [dot] com

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_DIR=/opt/android \
    IONIC_VERSION=latest \
    CORDOVA_VERSION=10.0.0 \
    GRADLE_VERSION=8.7 \
    ANDROID_COMPILE_SDK=34 \
    ANDROID_BUILD_TOOLS=34.0.0 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null

RUN date

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN pip list

# Install Node.js and npm packages
RUN node -v && java -version && npm -v

RUN echo $JAVA_HOME && echo $JAVA_HOME

RUN npm install -g \
    cordova@$CORDOVA_VERSION \
    @ionic/cli@$IONIC_VERSION && \
    npm cache clean --force && \
    mkdir -p /root/.cache/yarn/  

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android Tools
RUN mkdir $ANDROID_DIR && cd $ANDROID_DIR && \
    wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip && \
    unzip -q android-tools-sdk.zip && \
    rm -f android-tools-sdk.zip && \
    mv cmdline-tools latest && \
    mkdir sdk && \
    mkdir sdk/cmdline-tools && \
    mv latest sdk/cmdline-tools

# Install Gradle
RUN mkdir /opt/gradle && cd /opt/gradle && \
    wget --output-document=gradle.zip --quiet https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip && \
    unzip -q gradle.zip && \
    rm -f gradle.zip && \
    chown -R root:root /opt/gradle

# Setup environment
ENV ANDROID_HOME="${ANDROID_DIR}/sdk"
ENV ANDROID_SDK_ROOT="${ANDROID_DIR}/sdk"
ENV PATH="${PATH}:${ANDROID_HOME}:${ANDROID_HOME}/cmdline-tools:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}:/opt/gradle/gradle-${GRADLE_VERSION}/bin"

# Install Android SDK
RUN yes | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS" "platforms;android-$ANDROID_COMPILE_SDK" "platform-tools"

WORKDIR Sources
