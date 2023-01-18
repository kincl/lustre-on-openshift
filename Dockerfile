FROM registry.redhat.io/openshift4/driver-toolkit-rhel8:v4.11

WORKDIR /build/

ADD . .

RUN make && make install

# # Add the helper tools
# WORKDIR /root/kvc-simple-kmod
# ADD Makefile .
# ADD simple-kmod-lib.sh .
# ADD simple-kmod-wrapper.sh .
# ADD simple-kmod.conf .
# RUN mkdir -p /usr/lib/kvc/ \
# && mkdir -p /etc/kvc/ \
# && make install

# RUN systemctl enable kmods-via-containers@simple-kmod