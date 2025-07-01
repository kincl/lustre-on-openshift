# Using Cluster Layering for Lustre on RHCOS

This guide demonstrates how to use Red Hat CoreOS (RHCOS) layering to deploy Lustre kernel modules to OpenShift Container Platform (OCP) hosts.

## Overview

RHCOS layering is a mechanism that allows extending CoreOS functionality by installing additional packages. [Read more about CoreOS layering](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/machine_configuration/mco-coreos-layering).

There are two strategies for RHCOS layering:
- **On-cluster layering**: The container image is built within the cluster (GA as of OCP 4.19)
- **Out-of-cluster layering**: The container image is built externally and applied to the cluster

On-cluster layering should be possible but I have not yet investigated it.

This example uses **out-of-cluster layering**.

## Prerequisites

- OpenShift Container Platform cluster
- `oc` command-line tool
- [OCP registry pull secret](https://console.redhat.com/openshift/install/pull-secret)
- RHEL entitlement (for accessing required repositories)

## Building the RHCOS Layer Container Image

### Required Base Images

To build the RHCOS layer container image with Lustre, you need two specific images unique to your cluster version:

1. **Driver Toolkit Image**: Contains kernel development packages
   ```
   oc adm release info --image-for driver-toolkit
   ```

2. **RHEL CoreOS Image**: The base OS image
   ```
   oc adm release info --image-for rhel-coreos
   ```

These images are referenced in the [Containerfile](Containerfile) included in this directory.

### Entitlement Requirements

The build requires entitlement to access RHEL repositories beyond what UBI provides. This can be accomplished:
- On a subscribed RHEL host
- On an OpenShift cluster (described below)

## Building on OpenShift Cluster

Although we're doing "out-of-cluster layering," we're still building the container image in a cluster. The term refers to how the Machine Config Operator consumes the image, not where it's built.

**Note**: You can build this container image in any environment and host it on any Docker v2-compatible registry.

### Step 1: Install Builds for OpenShift

This provides easier access to the entitlement secret in the cluster:

```
oc apply -f install-operator.yaml
```

### Step 2: Set Up Build Configuration

Create the `lustre-build` namespace and set up the Build:

```
oc apply -f build.yaml
```

### Step 3: Configure Build Entitlement

Use a SharedSecret which is installed with Builds for OpenShift:

```
oc apply -f entitled-build.yaml
```

### Step 4: Start the Build

Initiate the build with BuildRun:

```
oc create -f buildrun.yaml
```

Alternatively, you can use:

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

**Note**: Building the Lustre client from source takes several minutes.

### Step 5: Apply the Machine Configuration

Once the build completes, apply the MachineConfig to roll out the new image to worker nodes:

```
oc apply -f machineconfig.yaml
```

This will trigger a rolling update of your worker nodes to apply the Lustre kernel modules.

## Verification

After the MachineConfig has been applied and nodes have finished updating, you can verify the Lustre client modules are available:

```
oc debug node/<worker-node> -- chroot /host modprobe lustre
```

## Troubleshooting

- Check MachineConfig status: `oc get mcp`
- View MachineConfig logs: `oc logs -f -n openshift-machine-config-operator <machine-config-daemon-pod>`
- Inspect node journal: `oc debug node/<node> -- chroot /host journalctl -xeu coreos-layering`
