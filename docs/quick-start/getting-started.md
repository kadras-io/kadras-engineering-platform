# Getting Started with Kadras Engineering Platform

This guide describes how to install the Kadras Engineering Platform on a local Kubernetes cluster and deploy a sample application workload that will take advantage of the platform capabilities such as serverless runtime, ingress and certificate management, and GitOps.

## Objectives

* Install Kadras on a Kubernetes cluster
* Deploy a sample application
* Explore the capabilities provided by the platform

## Before you begin

To follow the guide, Ensure you have the following tools installed in your local environment:

* Kubernetes [`kubectl`](https://kubectl.docs.kubernetes.io/installation/kubectl)
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install)
* Carvel [`kapp`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl).

Then, create a local Kubernetes cluster with [kind](https://kind.sigs.k8s.io).

```shell
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kadras
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

## Deploy Carvel kapp-controller

The platform relies on the Kubernetes-native package management capabilities offered by Carvel [kapp-controller](https://carvel.dev/kapp-controller). You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

## Add the Kadras Package Repository

Add the Kadras repository to make the platform packages available to the cluster.

  ```shell
  kctrl package repository add -r kadras-packages \
    --url ghcr.io/kadras-io/kadras-packages:0.21.0 \
    -n kadras-system --create-namespace
  ```

## Configure the Platform

The installation of the Kadras Engineering Platform can be configured via YAML. Create a `values.yml` file with any configuration you need for the platform. The following is a minimal configuration example for a local environment, based on the `run` installation profile.

```yaml title="values.yml"
platform:
  profile: run
  ingress:
    domain: 127.0.0.1.sslip.io
contour:
  envoy:
    service:
      type: NodePort
```

The Ingress is configured with the special domain `127.0.0.1.sslip.io` which will resolve to your localhost and be accessible via the kind cluster.

## Install the Platform

Reference the `values.yml` file you created in the previous step and install the Kadras Engineering Platform.

  ```shell
  kctrl package install -i engineering-platform \
    -p engineering-platform.packages.kadras.io \
    -v 0.19.0 \
    -n kadras-system \
    --values-file values.yml
  ```

## Verify the Installation

Verify that all the platform components have been installed and properly reconciled.

  ```shell
  kctrl package installed list -n kadras-system
  ```

## Run an Application via CLI

Kadras Engineering Platform provides capabilities to support application deployment workflows from image to URL based on Knative or plain Kubernetes. Furthermore, you can optionally use the built-in GitOps capabilities provided by Flux or Carvel.

For this example, let's use the [kn](https://knative.dev/docs/client) CLI to deploy an application workload in a serverless runtime provided by Knative.

```shell
kn service create band-service \
  --image ghcr.io/thomasvitale/band-service \
  --security-context strict
```

The application will be available through a local URL with a self-signed certificate (via Contour and cert-manager) and autoscaling capabilities (thanks to Knative). You can open the URL in the browser or use a CLI like [httpie](https://httpie.io).

```shell
https band-service.default.127.0.0.1.sslip.io --verify no
```

After testing the application, remember to delete it.

```shell
kn service delete band-service
```

## Run an Application via GitOps

Let's now deploy the same application using a GitOps workflow powered by Flux. You can either apply the Flux resources directly to the cluster or use the convenient [Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli). We'll use the second approach.

First, configure a Git repository for Flux to monitor.

```shell
flux create source git band-service \
  --url=https://github.com/ThomasVitale/band-service \
  --branch=main \
  --interval=1m
```

Then, create a Flux Kustomization that will deploy the application.

```shell
flux create kustomization band-service \
  --target-namespace=default \
  --source=band-service \
  --path="./k8s" \
  --wait=true
```

The application will be available through a local URL with a self-signed certificate (via Contour and cert-manager) and autoscaling capabilities (thanks to Knative). You can open the URL in the browser or use a CLI like [httpie](https://httpie.io).

```shell
https band-service.default.127.0.0.1.sslip.io --verify no
```
