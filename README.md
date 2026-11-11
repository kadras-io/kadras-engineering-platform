# Kadras Engineering Platform

![Test Workflow](https://github.com/kadras-io/kadras-engineering-platform/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/kadras-engineering-platform/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A cloud native platform aimed at supporting application developers with paved paths to production on Kubernetes and shipped as a Carvel package.

## ✨&nbsp; What's Included

The platform installs and configures a curated set of packages from the Kadras [package repository](https://github.com/kadras-io/kadras-packages), with a common configuration for the concerns they share: ingress, workspaces, observability, security, and the corporate proxy.

| Package | Default | Description |
|---------|---------|-------------|
| [cert-manager](https://github.com/kadras-io/package-for-cert-manager) | ✅ | Certificates, issued by a private CA or Let's Encrypt. |
| [cert-manager-webhook-hetzner](https://github.com/kadras-io/package-for-cert-manager-webhook-hetzner) | | DNS-01 challenges with Hetzner, for Let's Encrypt wildcard certificates. |
| [crossplane](https://github.com/kadras-io/package-for-crossplane) | | Infrastructure provisioning via Kubernetes APIs. |
| [dependency-track](https://github.com/kadras-io/package-for-dependency-track) | | Software supply chain security, via SBOM analysis. |
| [developer-portal](https://github.com/kadras-io/package-for-developer-portal) | | Developer portal, based on Backstage. |
| [envoy-gateway](https://github.com/kadras-io/package-for-envoy-gateway) | ✅ | The Gateways exposing the applications, via the Kubernetes Gateway API. |
| [flagger](https://github.com/kadras-io/package-for-flagger) | | Progressive delivery. |
| [flux](https://github.com/kadras-io/package-for-flux) | ✅ | GitOps. |
| [gateway-api](https://github.com/kadras-io/package-for-gateway-api) | ✅ | The Kubernetes Gateway API CRDs. |
| [gitops-configurer](https://github.com/kadras-io/gitops-configurer) | | GitOps configuration of the cluster, via Flux. |
| [knative-serving](https://github.com/kadras-io/package-for-knative-serving) | ✅ | Serverless runtime for applications. |
| [kyverno](https://github.com/kadras-io/package-for-kyverno) | | Policies, like the verification of image signatures. |
| [metrics-server](https://github.com/kadras-io/package-for-metrics-server) | | Container resource metrics, for autoscaling. |
| [opentelemetry-operator](https://github.com/kadras-io/package-for-opentelemetry-operator) | | OpenTelemetry collectors and auto-instrumentation. |
| [postgresql-operator](https://github.com/kadras-io/package-for-postgresql-operator) | | PostgreSQL databases, via CloudNativePG. |
| [rabbitmq-operator](https://github.com/kadras-io/package-for-rabbitmq-operator) | | RabbitMQ message brokers. |
| [secretgen-controller](https://github.com/kadras-io/package-for-secretgen-controller) | ✅ | Secrets generation and sharing across namespaces. |
| [workspace-provisioner](https://github.com/kadras-io/workspace-provisioner) | ✅ | Namespaces configured as workspaces for the platform users. |

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+
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
  -n kadras-system --create-namespace
```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Engineering Platform package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>, which also provides the platform packages. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>, but you'll need to add the definitions of all the platform packages too.

```shell
kubectl create namespace kadras-system
kapp deploy -a engineering-platform-package -n kadras-system -y \
  -f https://github.com/kadras-io/kadras-engineering-platform/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/kadras-engineering-platform/releases/latest/download/package.yml
```
</details>

Create a `values.yml` file with the configuration of the platform. For example, on a cluster with a load balancer:

```yaml
ingress:
  domain: example.com
workspaces:
  - name: team-a
```

Install the Engineering Platform package:

```shell
kctrl package install -i engineering-platform \
  -p engineering-platform.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
> ```shell
> kctrl package available list -p engineering-platform.packages.kadras.io -n kadras-system
> ```

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

For a complete walkthrough on a local cluster, see [Getting Started](docs/getting-started.md).

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.

* [Getting started on a local cluster](docs/getting-started.md)
* [Configuration](docs/configuration.md)
* [Ingress and TLS](docs/ingress.md)
* [Upgrading and uninstalling](docs/upgrade.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Engineering Platform package can be customized via a `values.yml` file. The platform values cover the concerns shared by the packages, and each package can be configured further in its own section, which takes precedence over the platform values.

```yaml
ingress:
  domain: example.com
workspaces:
  - name: team-a
    members:
      - kind: Group
        name: team-a-developers
        role: edit
packages:
  include:
    - kyverno
policies:
  enabled: true
knative_serving:
  workloads:
    activator:
      replicas: 2
```

See [configuration.md](docs/configuration.md) for the details.

### Values

The Engineering Platform package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `profile` | `"run"` | The installation profile. `run` for clusters exposing the applications via a load balancer. `local` for local clusters like kind and k3d: the default domain is `127.0.0.1.sslip.io`, the Gateway is exposed via the node ports 30080 (HTTP) and 30443 (HTTPS), and Metrics Server accepts the self-signed Kubelet certificates. |
| `namespace` | `"kadras-system"` | The namespace where the PackageInstalls of the platform packages are created. The packages deploy their workloads in their own namespaces. |
| `packages.include` | `[]` | The optional packages to install. |
| `packages.exclude` | `[]` | The default packages not to install. |
| `ingress.domain` | `""` | The base domain of the applications, served over HTTPS. Knative Services are served as `<name>.<workspace>.<domain>`. When empty, the `local` profile uses `127.0.0.1.sslip.io`, while the `run` profile serves no domain over HTTPS. |
| `ingress.issuer` | `"kadras-ca-issuer"` | The cert-manager ClusterIssuer that issues the certificates for `*.<domain>` and `*.<workspace>.<domain>`. The default one uses the private CA of the cert-manager package. For Let's Encrypt, wildcard certificates require a DNS-01 challenge: see docs/ingress.md. |
| `workspaces` | `[]` | The namespaces where the platform users deploy their workloads, provisioned by the Workspace Provisioner package. Each workspace gets its own HTTPS hostname on the external Gateway. |
| `ca_cert_data` | `""` | PEM-encoded certificates of additional certificate authorities to trust, for example to reach a private OCI registry or Git server. Applied to all the packages supporting it. |
| `observability.logging.level` | `"info"` | The log level. |
| `observability.logging.format` | `"json"` | The log format, for the packages where it's configurable. |
| `observability.metrics.enabled` | `true` | Whether the components produce metrics. |
| `observability.metrics.exporter` | `"prometheus"` | How the metrics are exported. With `prometheus`, the Pods are annotated for scraping. With `otlp`, Envoy Gateway, Knative Serving, and Kyverno push them to `endpoint`, while the other packages keep exposing them for scraping. |
| `observability.metrics.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector, with the `otlp` exporter. |
| `observability.tracing.enabled` | `false` | Whether Envoy Gateway, Knative Serving, and Kyverno export traces via OTLP/gRPC. |
| `observability.tracing.endpoint` | `""` | The OTLP/gRPC endpoint of an in-cluster OpenTelemetry collector. |
| `observability.tracing.sampling_rate` | `1` | The fraction of requests to trace, from 0 (never) to 1 (always), for Envoy Gateway and Knative Serving. |
| `policies.enabled` | `false` | Whether to include the Kyverno policies, in the packages supporting them. It requires the `kyverno` package. |
| `security.network_policies` | `false` | Whether to restrict the inbound traffic to the platform workloads via NetworkPolicies, in the packages supporting them. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. Include the in-cluster domains. |
| `cert_manager` | `{}` | Configuration for the cert-manager package. See https://github.com/kadras-io/package-for-cert-manager. |
| `cert_manager_webhook_hetzner` | `{}` | Configuration for the cert-manager-webhook-hetzner package. See https://github.com/kadras-io/package-for-cert-manager-webhook-hetzner. |
| `crossplane` | `{}` | Configuration for the Crossplane package. See https://github.com/kadras-io/package-for-crossplane. |
| `dependency_track` | `{}` | Configuration for the Dependency Track package. See https://github.com/kadras-io/package-for-dependency-track. |
| `developer_portal` | `{}` | Configuration for the Developer Portal package. See https://github.com/kadras-io/package-for-developer-portal. |
| `envoy_gateway` | `{}` | Configuration for the Envoy Gateway package. See https://github.com/kadras-io/package-for-envoy-gateway. |
| `flagger` | `{}` | Configuration for the Flagger package. See https://github.com/kadras-io/package-for-flagger. |
| `flux` | `{}` | Configuration for the Flux package. See https://github.com/kadras-io/package-for-flux. |
| `gitops_configurer` | `{}` | Configuration for the GitOps Configurer package. See https://github.com/kadras-io/gitops-configurer. |
| `knative_serving` | `{}` | Configuration for the Knative Serving package. See https://github.com/kadras-io/package-for-knative-serving. |
| `kyverno` | `{}` | Configuration for the Kyverno package. See https://github.com/kadras-io/package-for-kyverno. |
| `metrics_server` | `{}` | Configuration for the Metrics Server package. See https://github.com/kadras-io/package-for-metrics-server. |
| `opentelemetry_operator` | `{}` | Configuration for the OpenTelemetry Operator package. See https://github.com/kadras-io/package-for-opentelemetry-operator. |
| `postgresql_operator` | `{}` | Configuration for the PostgreSQL Operator package. See https://github.com/kadras-io/package-for-postgresql-operator. |
| `rabbitmq_operator` | `{}` | Configuration for the RabbitMQ Operator package. See https://github.com/kadras-io/package-for-rabbitmq-operator. |
| `secretgen_controller` | `{}` | Configuration for the secretgen-controller package. See https://github.com/kadras-io/package-for-secretgen-controller. |
| `workspace_provisioner` | `{}` | Configuration for the Workspace Provisioner package. See https://github.com/kadras-io/workspace-provisioner. |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Run the integration tests, on a kind cluster created for them.
task test:integration

# Create a local kind cluster with kapp-controller and the Kadras package repository,
# then deploy the platform from the local sources with the `local` profile.
task cluster:setup
task dev

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The packages, their versions, and their installation order are defined in [package/config/lib/catalog.star](package/config/lib/catalog.star), and the values the platform computes for each of them in [package/config/lib/values.star](package/config/lib/values.star). The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
