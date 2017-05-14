#
# Minimum Docker image to build Android
#
FROM ubuntu:16.04

# /bin/sh points to Dash by default, reconfigure to use bash until Android
# build becomes POSIX compliant
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure -p critical dash

# Keep the dependency list as short as reasonable
RUN apt-get update && \
    apt-get install -y \
        git-core python gnupg flex bison gperf libsdl1.2-dev libesd0-dev apt-utils \
        squashfs-tools build-essential zip curl libncurses5-dev zlib1g-dev openjdk-8-jre openjdk-8-jdk pngcrush \
        schedtool libxml2 libxml2-utils xsltproc lzop libc6-dev schedtool g++-multilib lib32z1-dev lib32ncurses5-dev \
        gcc-multilib liblz4-* pngquant ncurses-dev texinfo gcc gperf patch libtool \
        automake g++ gawk subversion expat libexpat1-dev python-all-dev bc libcloog-isl-dev \
        libcap-dev autoconf libgmp-dev build-essential gcc-multilib g++-multilib pkg-config libmpc-dev libmpfr-dev lzma* \
        liblzma* w3m android-tools-adb maven ncftp htop imagemagick  wget sudo vim \
        software-properties-common python-software-properties && \
        #bc bison bsdmainutils build-essential curl \
        #flex g++-multilib gcc-multilib git gnupg gperf lib32ncurses5-dev \
        #lib32z1-dev libesd0-dev libncurses5-dev \
        #libsdl1.2-dev libwxgtk3.0-dev libxml2-utils lzop sudo \
        #openjdk-8-jdk \
        #pngcrush schedtool xsltproc zip zlib1g-dev graphviz \
        #wget vim zip python curl automake gcc g++ ncurses-dev libxml2 texinfo \
        #gperf patch libtool gawk expat python-all-dev && \
    add-apt-repository ppa:cwchien/gradle && \
    apt-get update && \
    apt-cache search gradle && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD https://commondatastorage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

RUN mkdir /opt/gradle
WORKDIR /opt/gradle
RUN wget https://services.gradle.org/distributions/gradle-3.5-bin.zip
RUN unzip gradle-3.5-bin.zip -d .
ENV PATH $PATH:/opt/gradle/gradle-3.5/bin
RUN gradle -v
# Install latest version of JDK
# See http://source.android.com/source/initializing.html#setting-up-a-linux-build-environment
WORKDIR /tmp



# Install Android SDK
#WORKDIR /usr/local/
#RUN wget https://dl.google.com/android/android-sdk_r25.2.3-linux.tgz && \
#    tar -xvzf android-sdk_r24.4.1-linux.tgz && \
#    ls -la android-sdk-linux && \
#    mv android-sdk-linux /usr/local/android-sdk &&\
#    rm android-sdk_r24.4.1-linux.tgz

RUN wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
RUN unzip sdk-tools-linux-3859397.zip -d ./android-sdk && ls -la &&\
    mv ./android-sdk /usr/local/android-sdk && \
    rm sdk-tools-linux-3859397.zip

#ENV ANDROID_COMPONENTS tool,platform-tools,android-25,build-tools-25.0.3,extra-android-m2repository,extra-google-google_play_services,extra-google-m2repository
ENV ANDROID_COMPONENTS "tools" "platform-tools" "platforms;android-24" "platforms;android-25" \
    "sources;android-24" "sources;android-25" "build-tools;25.0.2" "build-tools;25.0.3" \
    "extras;android;m2repository" "extras;google;m2repository" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
    "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" \
    "ndk-bundle"
# Install Android tools
#RUN echo y | /usr/local/android-sdk/tools/android update sdk --filter "${ANDROID_COMPONENTS}" --no-ui -a
RUN echo y | /usr/local/android-sdk/tools/bin/sdkmanager ${ANDROID_COMPONENTS}
#RUN /usr/local/android-sdk/tools/bin/sdkmanager --licenses $ANDROID_COMPONENTS

# Environment variables
ENV ANDROID_HOME /usr/local/android-sdk
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/23.0.2
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/24.0.0
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/25.0.2
ENV PATH $PATH:$ANDROID_NDK_HOME

#RUN mkdir "$ANDROID_HOME/licenses" || true && \
#    echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license" \
#    echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
# All builds will be done by user aosp
COPY gitconfig /root/.gitconfig
COPY ssh_config /root/.ssh/config

# The persistent data will be in these two directories, everything else is
# considered to be ephemeral
VOLUME ["/tmp/ccache", "/rom"]

# Improve rebuild performance by enabling compiler cache
ENV USE_CCACHE 1
ENV CCACHE_DIR /tmp/ccache

# Work in the build directory, repo is expected to be init'd here
WORKDIR /rom


COPY utils/docker_entrypoint.sh /usr/bin/docker_entrypoint.sh
ENTRYPOINT ["/usr/bin/docker_entrypoint.sh"]
