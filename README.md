# Lustre on OpenShift

This repository demonstrates how to mount Lustre (specifically AWS FSx Lustre) on OpenShift and utilize it similar to a traditional HPC environment.

## Overview

This solution enables:

- Building Lustre kernel modules for Red Hat CoreOS (RHCOS) workers in OpenShift
- Mounting Lustre filesystems on OpenShift worker nodes
- Dynamically patching user workloads to bind mount Lustre into Pods using Open Policy Agent

## Kernel Module Deployment Approaches

There are two approaches for deploying the Lustre client kernel modules:

### 1. Cluster Layering (Recommended)

Cluster layering integrates the Lustre client kernel modules directly into the RHCOS node image itself. This method:
- Provides better integration with OpenShift's lifecycle management
- Offers improved stability and reliability
- Is the officially recommended approach

**To implement the cluster layering approach, see:** [cluster-layering/](cluster-layering/)

### 2. Kernel Module Management (Alternative)

The KMM operator builds the kernel modules in a container and installs them in the live kernel. While functional, this approach is provided as an alternative when cluster layering cannot be implemented.

**For the alternative KMM approach, see:** [kernel-module-management/](kernel-module-management/)

## Mutating Webhooks with Open Policy Agent

To dynamically patch user workloads with the correct UIDs and volume mount information, we use [admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/). This allows us to access and modify each API request as it comes to Kubernetes.

### Deploying Open Policy Agent and MutatingWebhookConfiguration

Open Policy Agent (OPA) is one of several possible approaches for implementing admission webhooks, alongside alternatives like Kyverno or custom webhooks built with Operator-SDK.

#### Safety Considerations

Misconfigured webhooks can severely impact cluster functionality, so we carefully limit the scope:

- We restrict webhook rules to only CREATE operations on namespace-scoped resources:

```
  - operations: ["CREATE"]
    apiGroups: ["*"]
    apiVersions: ["*"]
    resources: ["*"]
    scope: "Namespaced"
```

- We use namespace selectors to apply webhooks only to namespaces with our label: `openpolicyagent.org/webhook=`
- We set `failurePolicy: Fail` to ensure user workloads won't be created if OPA is unavailable (fail-closed approach)

### Installation

Install OPA + kube-mgmt:

```
$ helm repo add opa https://open-policy-agent.github.io/kube-mgmt/charts
$ helm repo update
$ helm inspect values opa/opa-kube-mgmt > values.yaml

$ helm upgrade -i -n opa --create-namespace opa opa/opa-kube-mgmt --values opa/values.yaml
$ oc apply -k opa/
```

OPA uses Rego, a custom policy language (based loosely on datalog/prolog), which we deploy via ConfigMap to enforce our policies.

## Testing the Solution

To test the complete solution, we've included a sample project namespace with the correct annotations for OPA mutation:

```
$ oc apply -k project1/
```

## Architecture Diagrams

### Technologies Involved

![technologies](img/technologies.jpg)

### Node View

![node-view](img/node-view2.jpg)

### Request Flow

![flow](img/flow.jpg)