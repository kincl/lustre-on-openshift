# Lustre on OpenShift

This shows how it is possible to mount Lustre (in this case AWS FSx Lustre) on
OpenShift and use it similar to a HPC environment.

We will be:

- Building the kernel modules using the Kubernetes Kernel Module Management operator
and OpenShift's Driver Toolkit image
- Mounting the Lustre filesystem on Red Hat CoreOS worker nodes in an OpenShift Cluster
- Dynamically patching user workloads to bind mount Lustre into Pods with Open Policy Agent

## Cluster Layering or KMM

Cluster layering uses RHCOS layers to deploy the kernel modules for lustre client to the nodes in the node image itself. KMM operator builds the kernel modules in a container and installs them in the live kernel.

Look at either `cluster-layering/` or `kernel-module-management/`

## Mutating Webhooks with Open Policy Agent

In order to dynamically patch user workloads with the correct UIDs and volume mount information
we can use a built-in feature of the Kubernetes API server called [admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/).
This let's us access each API request as it comes in to Kubernetes to either accept,
modify, or reject the request.

### Deploying Open Policy Agent and MutatingWebhookConfiguration

Open Policy Agent is just one way of achieving this goal including others such as Kyverno or even the Operator-SDK to
build a webhook receiver with the Kubernetes Golang scaffolding.

One thing to note here is that misconfigured validating and mutating webhooks can severely impair your cluster so we
take care to ensure that our blast radius is as tight as possible and encompasses only user workloads and not cluster-critical workloads:

- Scope our webhook configuration to exactly what we need by setting the rule to only CREATE operations on namespace-scoped resources

```
  - operations: ["CREATE"]
    apiGroups: ["*"]
    apiVersions: ["*"]
    resources: ["*"]
    scope: "Namespaced"
```
- Set a namespace selector on our webhook configuration to only apply to namespaces with our label: `openpolicyagent.org/webhook=`
- Set our webhook configuration to `failurePolicy: Fail` to ensure that we fail closed, user workloads will not be created if OPA is unable to handle requests

We also need to label all of our user namespaces so that our webhook enforces our changes.

### Install

Install OPA + kube-mgmt:

```
$ helm repo add opa https://open-policy-agent.github.io/kube-mgmt/charts
$ helm repo update
$ helm inspect values opa/opa-kube-mgmt > values.yaml

$ helm upgrade -i -n opa --create-namespace opa opa/opa-kube-mgmt --values opa/values.yaml
$ oc apply -k opa/
```

OPA uses a custom policy language called Rego (based loosely on datalog/prolog). We are deploying a ConfigMap with our
policies for OPA to enforce.

## Testing it all out

In order to test it all out I have a simple project namespace which has the correct annotations applied for enabling
the OPA mutation to work.

```
$ oc apply -k project1/
```

## Drawings

### Technologies Involved

![technologies](img/technologies.jpg)

### Node View

![node-view](img/node-view2.jpg)


### Request Flow

![flow](img/flow.jpg)
