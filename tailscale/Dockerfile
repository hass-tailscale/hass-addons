ARG BUILD_ARCH
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base-debian:latest

ARG BUILD_ARCH
ARG TAILSCALE_VERSION="1.102.3"

ENV LANG C.UTF-8

RUN apt update &&\
    apt install -y wget iptables iproute2 procps iputils-ping &&\
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set iptables /usr/sbin/iptables-nft
RUN update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

COPY install.sh /
RUN chmod a+x /install.sh
RUN /install.sh $BUILD_ARCH $TAILSCALE_VERSION

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
