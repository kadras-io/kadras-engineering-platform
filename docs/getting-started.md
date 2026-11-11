# Getting Started with Kadras Engineering Platform

This guide describes how to install the Kadras Engineering Platform on a local Kubernetes cluster and deploy a sample application that takes advantage of the platform capabilities, such as serverless runtime, HTTPS, and GitOps.

## Objectives

* Install the platform on a local Kubernetes cluster
* Deploy an application in a workspace
* Deploy the same application via GitOps

## Before you begin

Ensure you have the following tools installed in your local environment:

* Kubernetes [`kubectl`](https://kubectl.docs.kubernetes.io/installation/kubectl)
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl)
* Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install)
* [kind](https://kind.sigs.k8s.io)

Create a local Kubernetes cluster with kind. The platform exposes the applications via the node ports 30080 (HTTP) and 30443 (HTTPS), mapped to the ports 80 and 443 of your machine.

```shell
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kadras
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
  - containerPort: 30443
    hostPort: 443
EOF
```

<details><summary>Using k3d</summary>

```shell
k3d cluster create kadras \
  --port "80:30080@server:0" --port "443:30443@server:0" \
  --k3s-arg "--disable=traefik@server:0"
```
</details>

## Deploy Carvel kapp-controller

The platform relies on the Kubernetes-native package management capabilities offered by Carvel [kapp-controller](https://carvel.dev/kapp-controller).

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

## Add the Kadras Package Repository

Add the Kadras repository to make the platform packages available to the cluster.

```shell
kctrl package repository add -r kadras-packages \
  --url ghcr.io/kadras-io/kadras-packages \
  -n kadras-system --create-namespace
```

## Configure the Platform

Create a `values.yml` file with the configuration of the platform. The `local` profile serves the applications on the `127.0.0.1.sslip.io` domain, which resolves to your machine, over HTTPS with certificates from a private CA. The `apps` workspace is the namespace where you deploy your applications.

```yaml title="values.yml"
profile: local
workspaces:
  - name: apps
```

## Install the Platform

Install the Kadras Engineering Platform with the `values.yml` file you created.

```shell
kctrl package install -i engineering-platform \
  -p engineering-platform.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

> **Note**
> You can find the `${VERSION}` value by listing the versions available in the Kadras package repository.
>
> ```shell
> kctrl package available list -p engineering-platform.packages.kadras.io -n kadras-system
> ```

Verify that all the platform packages have been installed and reconciled.

```shell
kctrl package installed list -n kadras-system
```

## Deploy an Application

Deploy an application as a Knative Service in the `apps` workspace. Knative scales it based on the traffic, down to zero when it's not used.

```shell
kubectl apply -f - <<EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
  namespace: apps
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go
          securityContext:
            runAsUser: 1001
          env:
            - name: TARGET
              value: Kadras
EOF
```

Wait for it to be ready, then call it over HTTPS. The certificate is issued by the private CA of the platform, so skip its verification.

```shell
kubectl wait --for=condition=Ready ksvc/hello -n apps
curl -k https://hello.apps.127.0.0.1.sslip.io
```

The workspace enforces the `restricted` Pod Security Standard: Knative sets the secure defaults on the application containers, like dropping all capabilities and requiring a non-root user. Images that run as root by default, like this one, need a non-root user (`runAsUser`).

Delete the application when you're done.

```shell
kubectl delete ksvc hello -n apps
```

## Deploy an Application via GitOps

Deploy the same application from a Git repository via [Flux](https://fluxcd.io). The Kustomization applies the manifests with the `gitops-reconciler` ServiceAccount of the workspace, which can only manage the resources in the workspace.

```shell
kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: hello
  namespace: apps
spec:
  interval: 1m
  url: https://github.com/ThomasVitale/band-service
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: hello
  namespace: apps
spec:
  serviceAccountName: gitops-reconciler
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: hello
  path: ./k8s
  targetNamespace: apps
  prune: true
  wait: true
EOF
```

## Clean Up

Delete the local cluster.

```shell
kind delete cluster --name kadras
```
