# Using Cluster Layering for RHCOS

This uses Red Hat CoreOS's layering to ship the lustre kernel modules to the host. [Read more about it.](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/machine_configuration/mco-coreos-layering)

There are two strategies, **on-cluster layering** and **out-of-cluster layering** which describe where the container image is built, on-cluster layering is GA as of OCP 4.19 and is brand new. This example uses out-of-cluster layering.

## The Containerfile

In order to build our RHCOS layer container image with Lustre, we need two specific images that are unique to the version of the cluster. These images must be pulled with a [OCP registry pull secret](https://console.redhat.com/openshift/install/pull-secret):

- The driver-toolkit image (oc adm release info --image-for driver-toolkit)
- The rhcos image (oc adm release info --image-for rhel-coreos)

These plug into the [Containerfile](Containerfile), the driver-toolkit ships with RPMs like kernel-devel for the kernel in the rhel-coreos image.

The other requirement is that the container build will need to be entitled in order to access some of the build requirements we need access to the RHEL repos beyond what UBI gives us. This can be done on a subscribed RHEL host or in a OpenShift cluster. The next section will describe how we can use a OpenShift cluster to build the image.

## Building the container on a OpenShift Cluster

Even though we are doing "out-of-cluster layering" we are still going to be building the container image in a cluster. The name is a bit of a misnomer and really means that the cluster (specifically the Machine Config Operator) will not do the image build and will expect a image that it can pull and apply to the nodes.

There is no requirement to use a OpenShift cluster to build, you can build the container image anywhere and host it on any docker v2 registry you want.

First we need to install Builds for OpenShift to more easily access the entitlement secret that exists in the cluster.

```
oc apply -f install-operator.yaml
```

Next we will install the build recipe, this creates the `lustre-build` namespace and sets up our Build.

```
oc apply -f build.yaml
```

In order to set up the entitlement for the build, we will use a SharedSecret which is installed alongside Builds for OpenShift

```
oc apply -f entitled-build.yaml
```

Finally we can kick off a build with BuildRun

```
cat << EOF | oc create -f -
apiVersion: shipwright.io/v1beta1
kind: BuildRun
metadata:
  generateName: buildah-lustre-node-image-
  namespace: lustre-build
spec:
  build:
    name: buildah-lustre-node-image
EOF
```

Once the build completes (building Lustre client from source takes a minute), then we can apply our MachineConfig to roll out the new image to the worker nodes:

```
oc apply -f machineconfig.yaml
```
