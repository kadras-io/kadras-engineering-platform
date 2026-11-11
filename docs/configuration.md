# Configuration

The platform values cover the concerns shared by the packages. For everything else, each package can be configured in its own section of the values.

## Profiles

The `profile` adapts the platform to where it runs.

| Profile | Use it for | What changes |
|---------|-----------|--------------|
| `run` (default) | Clusters with a load balancer | Nothing: the external Gateway is exposed via a `LoadBalancer` Service. |
| `local` | Local clusters like kind and k3d | The default domain is `127.0.0.1.sslip.io`, the external Gateway is exposed via the node ports 30080 (HTTP) and 30443 (HTTPS), and Metrics Server accepts the self-signed Kubelet certificates. |

```yaml
profile: local
```

With the `local` profile, map the host ports 80 and 443 to the node ports when creating the cluster. See [getting-started.md](getting-started.md).

## Packages

The platform installs a default set of packages: `cert-manager`, `envoy-gateway`, `flux`, `gateway-api`, `knative-serving`, `secretgen-controller`, and `workspace-provisioner`. Include optional packages, or exclude default ones, by name.

```yaml
packages:
  include:
    - kyverno
    - metrics-server
  exclude:
    - flux
```

A package can't be installed without the packages it requires, like `dependency-track`, which requires `postgresql-operator` and `secretgen-controller`: the values are rejected with the missing packages. The PackageInstalls are created in the `kadras-system` namespace (`namespace`), and kapp installs the packages in order, after the ones they depend on. When changing `namespace`, add the Kadras package repository to that namespace too, or to the global packaging namespace of kapp-controller.

## Workspaces

The workspaces are the namespaces where the platform users deploy their workloads. They're provisioned by the [Workspace Provisioner](https://github.com/kadras-io/workspace-provisioner) package, which enforces the `restricted` Pod Security Standard on them, and grants access to their members via the Kubernetes default roles. Each workspace also gets an HTTPS hostname on the external Gateway, for its Knative Services. See [ingress.md](ingress.md).

```yaml
workspaces:
  - name: team-a
    members:
      - kind: Group
        name: team-a-developers
        role: edit
  - name: legacy
    pod_security: baseline
```

The credentials shared with the workspaces are configured in the Workspace Provisioner section. See [credentials](https://github.com/kadras-io/workspace-provisioner/blob/main/docs/credentials.md).

```yaml
workspace_provisioner:
  oci:
    pull_secret:
      name: registry-credentials
      namespace: kadras-system
```

Knative Serving is configured to set the secure defaults required by the `restricted` Pod Security Standard on the Knative Services that don't set them (`secure-pod-defaults`). Other workloads must set them explicitly.

## Shared settings

The shared settings are applied to all the packages supporting them.

| Setting | Packages |
|---------|----------|
| `ca_cert_data` | crossplane, dependency-track, flagger, flux, knative-serving, kyverno |
| `observability.logging.level` | All, except developer-portal, gitops-configurer, secretgen-controller, and workspace-provisioner |
| `observability.logging.format` | cert-manager, dependency-track, flagger, flux, kyverno, metrics-server |
| `observability.metrics.enabled` | All, except developer-portal, gitops-configurer, metrics-server, and workspace-provisioner |
| `observability.metrics.exporter` and `endpoint` | envoy-gateway, knative-serving, kyverno |
| `observability.tracing` | envoy-gateway, knative-serving, kyverno (without `sampling_rate`) |
| `policies.enabled` | cert-manager, flagger, flux, knative-serving, metrics-server |
| `security.network_policies` | cert-manager, cert-manager-webhook-hetzner, kyverno, secretgen-controller |
| `proxy` | cert-manager, cert-manager-webhook-hetzner, crossplane, dependency-track, flagger, flux, knative-serving, kyverno |

For example, to export the metrics and traces to an OpenTelemetry collector, and to verify the signatures of the package images with Kyverno:

```yaml
observability:
  metrics:
    exporter: otlp
    endpoint: http://otel-collector.observability.svc:4317
  tracing:
    enabled: true
    endpoint: http://otel-collector.observability.svc:4317
packages:
  include:
    - kyverno
policies:
  enabled: true
```

## Package configuration

Each package can be configured in its own section of the values, named after the package, like `cert_manager` and `knative_serving`. See the documentation of each package for its values. The section is merged on top of the values computed by the platform, so it always takes precedence: maps are merged, while lists and other values are replaced.

```yaml
flux:
  observability:
    logging:
      level: trace
knative_serving:
  workloads:
    activator:
      replicas: 2
```

To see the values the platform computes for each package, render the platform locally with your values, from a clone of this repository:

```shell
ytt -f package/config --data-values-file values.yml | yq 'select(.kind == "Secret") | .stringData["values.yaml"]'
```

## Troubleshooting

The platform validates its own values when installed. The package configuration sections are validated by each package instead, when its PackageInstall is reconciled: an invalid value makes the platform installation fail, and the error is reported in the status of the package. List the packages and their status, then inspect the failing one.

```shell
kctrl package installed list -n kadras-system
kctrl package installed status -i knative-serving -n kadras-system
```

## ytt overlays

Any resource of the platform package, like the PackageInstalls, can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic engineering-platform-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall engineering-platform -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=engineering-platform-overlays
```

For example, to install a different version of a package than the one the platform pins:

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "PackageInstall", "metadata": {"name": "flux"}})
---
spec:
  packageRef:
    versionSelection:
      constraints: 2.10.1
```
