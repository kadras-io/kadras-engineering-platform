# Upgrading and Uninstalling

## Upgrading

Upgrade the platform to a new version via `kctrl`, with your values file.

```shell
kctrl package installed update -i engineering-platform \
  -p engineering-platform.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

Each platform version pins the versions of its packages. Read the release notes of the platform and of the packages being upgraded first.

## Upgrading from 0.32

Version 0.33 redesigns the platform values, and replaces Contour with Envoy Gateway and the Gateway API. Update your `values.yml` before upgrading: the platform rejects the old values.

| Old value | New value |
|-----------|-----------|
| `platform.profile` (`standalone`, `run`) | `profile` (`run`, `local`) |
| `platform.namespace` | `namespace` |
| `platform.additional_packages` | `packages.include` |
| `platform.excluded_packages` | `packages.exclude` |
| `platform.ca_cert_data` | `ca_cert_data` |
| `platform.ingress.domain` | `ingress.domain` |
| `platform.ingress.issuer` | `ingress.issuer`, the name of a ClusterIssuer. Let's Encrypt is configured in `cert_manager`: see [ingress.md](ingress.md#lets-encrypt) |
| `platform.oci`, `platform.git` | `workspace_provisioner.oci`, `workspace_provisioner.git` |
| `platform.cosign` | Removed, together with the supply chains |
| `workspace_provisioner.namespaces` | `workspaces` |
| `contour` | `envoy_gateway`, with different values: see the [Envoy Gateway package](https://github.com/kadras-io/package-for-envoy-gateway) |
| `knative.serving` | `knative_serving` |
| `kyverno.core` | `kyverno` |

The values of most packages changed too, since they were redesigned with a common structure. Check the upgrade notes of each package you configure.

Other changes:

* The `gateway-api` package is installed by default. Install it before upgrading the platform if you have Gateway API resources, so that it takes over the CRDs: see the [Gateway API package](https://github.com/kadras-io/package-for-gateway-api/blob/main/docs/upgrade.md).
* Contour is replaced by Envoy Gateway. The applications are served by the `envoy-external` Service in the `envoy-gateway-system` namespace: update your DNS records to point to its address.
* The `rbac-configurer` package is removed, together with the supply chain roles. The workspaces use the Kubernetes default roles instead.
* The workspaces enforce the `restricted` Pod Security Standard by default. Workloads that don't comply are rejected: relax the standard per workspace via `pod_security`, if needed.
* The `platform-info` ConfigMap isn't created anymore.

## Uninstalling

```shell
kctrl package installed delete -i engineering-platform -n kadras-system
```

Uninstalling the platform uninstalls its packages, in the reverse order of their installation. Some packages keep resources on purpose, to avoid losing data or workloads: for example, the workspace namespaces with their workloads, the Gateway API CRDs with the Gateways and routes, and the Flux CRDs with the Flux resources. See the documentation of each package to remove them too.
