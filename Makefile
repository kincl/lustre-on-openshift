all: build-deps lustre-client-2.12.8-1.fsx5.el8.src.rpm
	rpmbuild --rebuild lustre-client-2.12.8-1.fsx5.el8.src.rpm

lustre-client-2.12.8-1.fsx5.el8.src.rpm:
	yumdownloader --source lustre-client

build-deps:
	curl https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -o /tmp/fsx-rpm-public-key.asc
	rpm --import /tmp/fsx-rpm-public-key.asc
	
	curl https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/fsx-lustre-client.repo -o /etc/yum.repos.d/aws-fsx.repo
	sed -i 's#8#8.6#' /etc/yum.repos.d/aws-fsx.repo

	dnf install -y dnf-utils rpm-build libselinux-devel libtool libyaml-devel

install:
	dnf install -y /root/rpmbuild/RPMS/x86_64/kmod-lustre-client-2.12.8-1.fsx5.el8.x86_64.rpm /root/rpmbuild/RPMS/x86_64/lustre-client-2.12.8-1.fsx5.el8.x86_64.rpm
