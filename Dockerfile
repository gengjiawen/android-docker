FROM openjdk:8-jdk

ARG sdk_version=sdk-tools-linux-3859397.zip
ARG android_home=/opt/android/sdk

RUN sudo apt-get update && \
    sudo apt-get install --yes \
        xvfb gcc-multilib lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev \
        libglu1-mesa-dev

# Download and install Android SDK
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
ENV ANDROID_SDK_HOME ${android_home}
ENV ADB_INSTALL_TIMEOUT 120
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN yes | sdkmanager --licenses && sdkmanager --update

# Update SDK manager and install system image, platform and build tools
RUN sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "extras;android;m2repository" \
  "extras;google;m2repository" \
  "extras;google;google_play_services"

RUN sdkmanager \
  "build-tools;25.0.3" \
  "build-tools;26.0.2" \
  "build-tools;27.0.3"

RUN sdkmanager "platforms;android-27"

#install ndk
RUN sdkmanager \
  "ndk-bundle" \
  "lldb;3.0" \
  "cmake;3.6.4111459"

ENV ANDROID_NDK_HOME ${ANDROID_HOME}/ndk-bundle
ENV PATH ${ANDROID_NDK_HOME}:$PATH
