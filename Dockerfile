FROM registry.redhat.io/openshift4/driver-toolkit-rhel8:v4.11 as builder
ARG KERNEL_VERSION=4.18.0-372.36.1.el8_6.x86_64
ARG LUSTRE_VERSION=2.12.8

WORKDIR /build/

RUN curl https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -o /tmp/fsx-rpm-public-key.asc && \
    rpm --import /tmp/fsx-rpm-public-key.asc && \
    curl https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/fsx-lustre-client.repo -o /etc/yum.repos.d/aws-fsx.repo && \
    sed -i 's#8#8.6#' /etc/yum.repos.d/aws-fsx.repo && \
    dnf install -y dnf-utils rpm-build libselinux-devel libtool libyaml-devel

RUN yumdownloader --source lustre-client-${LUSTRE_VERSION} && \
    rpmbuild -v --rebuild lustre-client-*.src.rpm && \
    dnf install -y /root/rpmbuild/RPMS/x86_64/kmod-lustre-client-${LUSTRE_VERSION}*.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/lustre-client-${LUSTRE_VERSION}*.el8.x86_64.rpm

FROM registry.access.redhat.com/ubi8/ubi:latest
ARG KERNEL_VERSION=4.18.0-372.36.1.el8_6.x86_64
ARG LUSTRE_VERSION=2.12.8

COPY --from=builder /root/rpmbuild/RPMS/x86_64/kmod-lustre-client-${LUSTRE_VERSION}*.el8.x86_64.rpm /root
COPY --from=builder /root/rpmbuild/RPMS/x86_64/lustre-client-${LUSTRE_VERSION}*.el8.x86_64.rpm /root

RUN dnf install -y kmod /root/kmod-lustre-client-${LUSTRE_VERSION}*.rpm /root/lustre-client-${LUSTRE_VERSION}*.rpm

COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/fid.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/fid.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/fld.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/fld.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lmv.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lmv.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lov.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lov.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lustre.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/lustre.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/mdc.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/mdc.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/mgc.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/mgc.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/obdclass.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/obdclass.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/obdecho.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/obdecho.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/osc.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/osc.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/ptlrpc.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/fs/ptlrpc.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/ko2iblnd.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/ko2iblnd.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/ksocklnd.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/ksocklnd.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/libcfs.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/libcfs.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/lnet.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/lnet.ko
COPY --from=builder /lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/lnet_selftest.ko /opt/lib/modules/${KERNEL_VERSION}/extra/lustre-client/net/lnet_selftest.ko

RUN depmod -b /opt
