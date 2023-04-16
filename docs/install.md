# Install the Kadras Engineering Platform

## 1. Prerequisites

* Kubernetes 1.24+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Sigstore [`cosign`](https://docs.sigstore.dev/cosign/installation/) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
  ```

## 2. Add the Kadras Repository

Add the Kadras repository to make all Kadras packages available to the cluster.

  ```shell
  kubectl create namespace kadras-packages
  kctrl package repository add -r kadras-packages \
    --url ghcr.io/kadras-io/kadras-packages \
    -n kadras-packages
  ```

You can check the full list of available packages as follows.

  ```shell
  kctrl package available list -n kadras-packages 
  ```

## 3. Create Secret for OCI Registry

First, create a Secret with the credentials to access your container registry in read/write mode. It will be used by the platform to publish and consume OCI artifacts.

  ```shell
  export SUPPLY_CHAIN_REGISTRY_HOSTNAME=<hostname>
  export SUPPLY_CHAIN_REGISTRY_USERNAME=<username>
  export SUPPLY_CHAIN_REGISTRY_TOKEN=<token>
  ```

* `<hostname>` is the server hosting the OCI registry. For example, `ghcr.io`, `gcr.io`, `quay.io`, `index.docker.io`.
* `<username>` is the username to access the OCI registry. Use `_json_key` if the hostname is `gcr.io`.
* `<token>` is a token with read/write permissions to access the OCI registry. Use the contents of the service account key json if the hostname is `gcr.io`.

  ```shell
  kubectl create secret docker-registry supply-chain-registry-credentials \
    --docker-server="${SUPPLY_CHAIN_REGISTRY_HOSTNAME}" \
    --docker-username="${SUPPLY_CHAIN_REGISTRY_USERNAME}" \
    --docker-password="${SUPPLY_CHAIN_REGISTRY_TOKEN}" \
    --namespace=kadras-packages
  ```

## 4. Create Secret for Cosign

Next, use Cosign to generate a key-pair that will be used by the platform to sign and verify OCI artifacts.

  ```shell
  cosign generate-key-pair k8s://kadras-packages/supply-chain-cosign-key-pair
  ```

The previous command will create a cosign.pub file in the current directory. That's the public key you can use the verify OCI artifacts built and signed by the platform.

## 5. Configure the Platform

The installation of the Kadras Engineering Platform can be configured via YAML. Create a `values.yml` file with any configuration you need for the platform. The following is a minimal configuration example.

```yaml
platform:
  ingress:
    domain: <domain>

  oci_registry:
    server: <oci-server>
    repository: <oci-repository>
  
  cosign:
    secret:
      name: supply-chain-cosign-key-pair
      namespace: kadras-packages

workspace_provisioner:
  namespaces:
    - name: default
  git:
    credentials:
      username: <github-username>
      password: <github-token>
```

* `<domain>` is the base domain name the platform will use to configure the Ingress controller. It must be a valid DNS name. For example, `lab.thomasvitale.com`.
* `<oci-server>` is the server of the OCI registry where the platform will publish and consume OCI images. It must be the same used in step 3 when creating a Secret with the OCI registry credentials. For example, `ghcr.io`, `gcr.io`, `quay.io`, `index.docker.io`.
* `<oci-repository>` is the repository in the OCI registry where the platform will publish and consume OCI images. It must be the same used in step 3 when creating a Secret with the OCI registry credentials. For example, it might be your username or organization name depending on which OCI server you're using.
* `<github-username>` is your username to access your Git repositories on GitHub. It's not needed if you won't use the GitOps workflows offered by the platform and only use public Git repositories.
* `<github-token>` is a token with read/write permissions to access your Git repositories on GitHub. It's not needed if you won't use the GitOps workflows offered by the platform and only use public Git repositories.

## 6. Install the Platform

Reference the `values.yml` file you created in the previous step and install the Kadras Engineering Platform.

  ```shell
  kctrl package install -i engineering-platform \
    -p engineering-platform.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-packages \
    --values-file values.yml
  ```

You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.

  ```shell
  kctrl package available list -p engineering-platform.packages.kadras.io -n kadras-packages
  ```

## 7. Verify the Installation

Verify that all the platform components have been installed and properly reconciled.

  ```shell
  kctrl package installed list -n kadras-packages 
  ```
