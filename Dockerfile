FROM debian:buster-slim

ARG BUILD_DATE
ARG VCS_REF
ARG DEFAULT_WWW=8080
ARG DEFAULT_SSLWWW=0
# Change to "development" if you want the development version
ARG DOMOTICZ_VERSION="master"

LABEL maintainer                      "BPMb"
LABEL org.label-schema.build-date     $BUILD_DATE
LABEL org.label-schema.name           "Domoticz"
LABEL org.label-schema.description    "Domoticz container using Debian stable-slim"
LABEL org.label-schema.url            "https://domoticz.com"
LABEL org.label-schema.schema-version "1.0.0-rc1"

ENV WWW    $DEFAULT_WWW
ENV SSLWWW $DEFAULT_SSLWWW

RUN \
    # Packages and system setup
    apt-get update && apt-get install -y \
        curl procps wget \
        build-essential git libcereal-dev \
        libboost-thread-dev libboost-system-dev \
        libcoap-1-0-dev libcurl4-gnutls-dev \
        libssl-dev liblua5.3-dev uthash-dev \
        libudev-dev libusb-dev zlib1g-dev \
        python3 python3-dev python3-pip libpython3.7 && \
    # CMake 3.16.0 or higher is required
    echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backport.list && \
    apt-get update && apt-get install -y -t buster-backports cmake && \
    mkdir -p /opt && \
    # Install toonapilib
    pip3 install toonapilib && \
    # OpenZWave
    cd /opt && \
    git clone --depth 1 https://github.com/OpenZWave/open-zwave.git open-zwave-read-only && \
    cd open-zwave-read-only && \
    make && \
    make install && \
    rm -rf /opt/open-zwave-read-only/.git* && \
    # Domoticz
    cd /opt && \
    git clone -b "${DOMOTICZ_VERSION}" --depth 2 https://github.com/domoticz/domoticz.git domoticz && \
    cd domoticz && \
    git fetch --unshallow && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -Wno-dev -Wno-deprecated && \
    make && \
    rm -rf /opt/domoticz/.git* && \
    # Create missing folders and set rights
    mkdir /data && \
    mkdir /opt/domoticz/backups && \
    # Install toonapilib4domoticz
    cd /opt/domoticz/plugins && \
    git clone https://github.com/JohnvandeVrugt/toonapilib4domoticz.git toonapilib4domoticz && \
    chmod -R ug+rw /opt/domoticz/plugins && \
    # Clean
    apt-get remove --purge -y build-essential git wget && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo DONE

WORKDIR /opt/domoticz
COPY start.sh .
COPY healthcheck.sh .
RUN chmod +x *.sh

EXPOSE  6144 ${WWW}
VOLUME  ["/data", "/opt/domoticz/backups", "/opt/domoticz/plugins", "/opt/domoticz/scripts"]

HEALTHCHECK --interval=5m --timeout=5s \
  CMD /opt/domoticz/healthcheck.sh

ENTRYPOINT ["/opt/domoticz/start.sh"]
