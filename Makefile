all: build-deps lustre-client-2.12.8-1.fsx5.el8.src.rpm
	rpmbuild --rebuild lustre-client-2.12.8-1.fsx5.el8.src.rpm

lustre-client-2.12.8-1.fsx5.el8.src.rpm:
	yumdownloader --source lustre-client

build-deps:
	dnf install -y dnf-utils rpm-build libselinux-devel libtool libyaml-devel

install:
	dnf install /root/rpmbuild/RPMS/x86_64/kmod-lustre-client-2.12.8-1.fsx5.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/lustre-client-2.12.8-1.fsx5.el8.x86_64.rpm
