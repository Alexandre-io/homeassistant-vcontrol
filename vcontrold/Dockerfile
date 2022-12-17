# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Execute during the build of the image
ARG TEMPIO_VERSION BUILD_ARCH
RUN \
    curl -sSLf -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"

RUN \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential git cmake telnet libxml2-dev && \    
    mkdir openv && \
    cd openv && \
    git clone https://github.com/openv/vcontrold.git && \
    cd vcontrold && \
    mkdir build && \
    cd build && \
    cmake -DMANPAGES=OFF .. && \
    make install

# Copy root filesystem
COPY rootfs /

EXPOSE 3002
