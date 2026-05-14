ARG BUILD_ARCH
FROM homeassistant/${BUILD_ARCH}-base-debian:latest

ARG BUILD_ARCH
ARG TAILSCALE_VERSION="1.96.4"

ENV LANG C.UTF-8

RUN apt update &&\
    apt install -y wget iptables iproute2 procps iputils-ping &&\
    rm -rf /var/lib/apt/lists/*

# Use legacy iptables not nftables, see https://wiki.debian.org/iptables
RUN update-alternatives --set iptables /usr/sbin/iptables-legacy
RUN update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# Download and install tailscale to /bin from https://pkgs.tailscale.com/stable/#static
COPY install.sh /
RUN chmod a+x /install.sh
RUN /install.sh $BUILD_ARCH $TAILSCALE_VERSION

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
