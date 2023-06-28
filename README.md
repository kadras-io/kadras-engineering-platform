# Kadras Engineering Platform

![Test Workflow](https://github.com/kadras-io/engineering-platform/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/engineering-platform/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Twitter](https://img.shields.io/static/v1?label=Twitter&message=Follow&color=1DA1F2)](https://twitter.com/kadrasIO)

A curated set of Carvel packages to build an engineering platform supporting application developers with paved paths to production on Kubernetes.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.25+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
  ```

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

  ```shell
  kctrl package repository add -r kadras-packages \
    --url ghcr.io/kadras-io/kadras-packages \
    -n kadras-packages --create-namespace
  ```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Engineering Platform package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

  ```shell
  kubectl create namespace kadras-packages
  kapp deploy -a engineering-platform-package -n kadras-packages -y \
    -f https://github.com/kadras-io/engineering-platform/releases/latest/download/metadata.yml \
    -f https://github.com/kadras-io/engineering-platform/releases/latest/download/package.yml
  ```
</details>

Install the Engineering Platform package:

  ```shell
  kctrl package install -i engineering-platform \
    -p engineering-platform.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-packages
  ```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
>   ```shell
>   kctrl package available list -p engineering-platform.packages.kadras.io -n kadras-packages
>   ```

Verify the installed packages and their status:

  ```shell
  kctrl package installed list -n kadras-packages
  ```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.

## 🎯&nbsp; Configuration

The Engineering Platform package can be customized via a `values.yml` file.

  ```yaml
  platform:
    platform:
      profile: serving
    ingress:
      domain: thomasvitale.com
  ```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

  ```shell
  kctrl package install -i engineering-platform \
    -p engineering-platform.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-packages \
    --values-file values.yml
  ```

### Values

The Engineering Platform package has the following configurable properties.

<details><summary>Configurable properties</summary>

| Config | Default | Description |
|-------|-------------------|-------------|
| `platform.profile` | `full` | The platform profile to install. Options: `full`, `serving`. |
| `platform.namespace` | `kadras-packages` | The namespace where to install the platform. |
| `platform.excluded_packages` | `[]` | A list of packages to exclude from being installed. |
| `platform.ca_cert_data` | `""` | PEM-encoded certificate data to trust TLS connections with a custom CA. |
| `platform.infrastructure_provider` | `""` | The underlying infrastructure provider. Options are `local` and `vsphere`. This field is not required, but it enables better validation and defaulting if provided. |
| `platform.ingress.domain` | `""` | The base domain name the platform will use to configure the Ingress controller. It must be a valid DNS name. |
| `platform.ingress.issuer.type` | `private` | The type of ClusterIssuer the platform will use to enable TLS communications. Options: `private`, `letsencrypt_staging`, `letsencrypt`, `custom`. |
| `platform.ingress.issuer.name` | `""` | A reference to a custom ClusterIssuer previously created on the cluster where the platform will be installed. Required when the type is `custom`. |
| `platform.ingress.issuer.email` | `""` | The email address that Let's Encrypt will use to send info on expiring certificates or other issues. Required when the type is `letsencrypt_staging` or `letsencrypt`. |
| `platform.oci_registry.server` | `""` | The server of the OCI Registry where the platform will publish and consume OCI images. |
| `platform.oci_registry.repository` | `""` | The repository in the OCI Registry where the platform will publish and consume OCI images. |
| `platform.oci_registry.secret.name` | `supply-chain-registry-credentials` | The name of the Secret holding the credentials to access the OCI registry. |
| `platform.oci_registry.secret.namespace` | `kadras-packages` | The namespace of the Secret holding the credentials to access the OCI registry. |
| `platform.cosign.secret.name` | `supply-chain-cosign-key-pair` | The name of the Secret holding the Cosign key pair. |
| `platform.cosign.secret.namespace` | `kadras-packages` | The namespace of the Secret holding the Cosign key pair. |
| `platform.git.server` | `https://github.com` | The server hosting the Git repositories used by the plaform. |
| `platform.git.secret.name` | `supply-chain-git-credentials` | The name of the Secret holding the credentials to access the Git server. |
| `platform.git.secret.namespace` | `kadras-packages` | The namespace of the Secret holding the credentials to access the Git server. |

Each Kadras package included in the platform can be configured independently.

| Config | Default | Description |
|-------|-------------------|-------------|
| `buildpacks.catalog` | `{}` | Configuration for the Buildpacks Catalog package. |
| `buildpacks.kpack` | `{}` | Configuration for the Kpack package. |
| `cartographer.core` | `{}` | Configuration for the Cartographer Core package including Cartographer and Cartographer Conventions. |
| `cartographer.blueprints` | `{}` | Configuration for the Cartographer Blueprints package. |
| `cartographer.delivery` | `{}` | Configuration for the Cartographer Delivery package. |
| `cartographer.supply_chains` | `{}` | Configuration for the Cartographer Supply Chains package. |
| `cert_manager.core` | `{}` | Configuration for the Cert Manager package. |
| `cert_manager.issuers` | `{}` | Configuration for the Cert Manager Issuers package. |
| `contour` | `{}` | Configuration for the Contour package. |
| `conventions.spring_boot` | `{}` | Configuration for the Spring Boot Conventions package. |
| `flux.source_controller` | `{}` | Configuration for the FluxCD Source Controller package. |
| `knative.serving` | `{}` | Configuration for the Knative Serving package. |
| `metrics_server` | `{}` | Configuration for the Metrics Server package. |
| `secretgen_controller` | `{}` | Configuration for the Secretgen Controller package. |
| `tekton.catalog` | `{}` | Configuration for the Tekton Catalog package. |
| `tekton.pipelines` | `{}` | Configuration for the Tekton Pipelines package. |
| `workspace_provisioner` | `{}` | Configuration for the Workspace Provisioner package. |

</details>

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.

## 🙏&nbsp; Acknowledgments

This package is inspired by the App Toolkit package used in [Tanzu Community Edition](https://github.com/vmware-tanzu/community-edition) before its retirement and the [open-source example](https://github.com/vrabbi/tap-oss) of [Tanzu Application Platform](https://tanzu.vmware.com/application-platform) by [Scott Rosenberg](https://vrabbi.cloud).
