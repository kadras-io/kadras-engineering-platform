load("@ytt:struct", "struct")

# The packages of the platform, from the Kadras package repository (https://github.com/kadras-io/kadras-packages).
# This file doesn't depend on data values, since it's also used by the values schema to validate them.
#
# * name: the package name, also used for its PackageInstall, its values Secret, and its kapp change group.
# * key: the section in the platform values with the package configuration, or None when the package has no values.
# * version: the package version installed by the platform.
# * default: whether the package is installed by default, or only when listed in `packages.include`.
# * requires: the packages that must be installed too.
# * after: the packages installed before this one, when they're installed.
#
# To add a package, add it here, add its configuration section to the values schema (named after `key`),
# and add the function computing its values to lib/values.star.

def _package(name, key, version, default=False, requires=[], after=[]):
  return struct.make(name=name, key=key, version=version, default=default, requires=requires, after=requires + after)
end

packages = [
  _package("cert-manager", "cert_manager", "1.21.3+kadras.1", default=True, after=["gateway-api", "kyverno"]),
  _package("cert-manager-webhook-hetzner", "cert_manager_webhook_hetzner", "0.9.1", requires=["cert-manager"]),
  _package("crossplane", "crossplane", "2.4.3"),
  _package("dependency-track", "dependency_track", "5.2.1+kadras.1", requires=["postgresql-operator", "secretgen-controller"], after=["envoy-gateway"]),
  _package("developer-portal", "developer_portal", "0.8.0"),
  _package("envoy-gateway", "envoy_gateway", "1.10.0+kadras.2", default=True, requires=["cert-manager"], after=["gateway-api"]),
  _package("flagger", "flagger", "1.45.0", after=["envoy-gateway", "knative-serving", "kyverno"]),
  _package("flux", "flux", "2.10.0", default=True, after=["kyverno"]),
  _package("gateway-api", None, "1.6.1", default=True),
  _package("gitops-configurer", "gitops_configurer", "0.4.0", requires=["flux"], after=["cert-manager", "crossplane", "envoy-gateway", "knative-serving", "kyverno", "postgresql-operator", "rabbitmq-operator", "workspace-provisioner"]),
  _package("knative-serving", "knative_serving", "1.24.0", default=True, requires=["envoy-gateway"], after=["cert-manager", "kyverno"]),
  _package("kyverno", "kyverno", "1.19.2+kadras.1"),
  _package("metrics-server", "metrics_server", "0.9.1+kadras.1", after=["kyverno"]),
  _package("opentelemetry-operator", "opentelemetry_operator", "0.162.0", requires=["cert-manager"]),
  _package("postgresql-operator", "postgresql_operator", "1.30.1+kadras.1"),
  _package("rabbitmq-operator", "rabbitmq_operator", "2.23.2", requires=["cert-manager"]),
  _package("secretgen-controller", "secretgen_controller", "0.21.4", default=True),
  _package("workspace-provisioner", "workspace_provisioner", "0.6.0", default=True, requires=["secretgen-controller"]),
]

package_names = [package.name for package in packages]

# The names of the installed packages: the default ones, plus the included ones, minus the excluded ones.
# The lists are converted, since the values schema passes them as YAML fragments, which don't support `in`.
def installed_package_names(include, exclude):
  include, exclude = list(include), list(exclude)
  return [package.name for package in packages if (package.default or package.name in include) and package.name not in exclude]
end
