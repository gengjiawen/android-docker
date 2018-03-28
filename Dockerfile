FROM openjdk:8-jdk

LABEL maintainer="gengjiawen@qq.com"

# Initial Command run as `root`.

ADD https://raw.githubusercontent.com/circleci/circleci-images/master/android/bin/circle-android /bin/circle-android
RUN chmod +rx /bin/circle-android

# Skip the first line of the Dockerfile template (FROM ${BASE})

# make Apt non-interactive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci

ENV DEBIAN_FRONTEND=noninteractive

# man directory is missing in some base images
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN apt-get update \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y \
    git mercurial xvfb \
    locales sudo openssh-client ca-certificates tar gzip parallel \
    net-tools netcat unzip zip bzip2 gnupg curl wget

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

USER circleci

CMD ["/bin/sh"]

# Switching user can confuse Docker's idea of $HOME, so we set it explicitly
ENV HOME /home/circleci

ARG sdk_version=sdk-tools-linux-3859397.zip
ARG android_home=/opt/android/sdk


RUN sudo apt-get update && \
    sudo apt-get install --yes \
        xvfb gcc-multilib lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev \
        libglu1-mesa-dev

# Download and install Android SDK
RUN sudo mkdir -p ${android_home} && \
    sudo chown -R circleci:circleci ${android_home} && \
    curl --silent --show-error --location --fail --retry 3 --output /tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
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

RUN sdkmanager \
  "ndk-bundle" \
  "lldb;3.0" \
  "cmake;3.6.4111459"

ENV ANDROID_NDK_HOME ${ANDROID_HOME}/ndk-bundle
ENV PATH ${ANDROID_NDK_HOME}:$PATH
