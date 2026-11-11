load("@ytt:assert", "assert")
load("@ytt:data", "data")
load("@ytt:struct", "struct")

# The values the platform computes for each package, from the platform values. The package configuration
# provided in the platform values (like `cert_manager`) is merged on top of them, so it always takes precedence.

# ###########
# SHARED SETTINGS
# ###########

def _is_local():
  return data.values.profile == "local"
end

# The base domain of the applications. The `local` profile serves them on the loopback address via sslip.io.
def _domain():
  if data.values.ingress.domain:
    return data.values.ingress.domain
  elif _is_local():
    return "127.0.0.1.sslip.io"
  end
  return ""
end

def _logging(format=True):
  logging = {"level": data.values.observability.logging.level}
  if format:
    logging["format"] = data.values.observability.logging.format
  end
  return logging
end

def _metrics(otlp=False):
  metrics = data.values.observability.metrics
  if not otlp:
    return {"enabled": metrics.enabled}
  end
  return {"enabled": metrics.enabled, "exporter": metrics.exporter, "endpoint": metrics.endpoint}
end

def _tracing(sampling=True):
  tracing = data.values.observability.tracing
  values = {"enabled": tracing.enabled, "endpoint": tracing.endpoint}
  if sampling:
    values["sampling_rate"] = tracing.sampling_rate
  end
  return values
end

def _proxy():
  return struct.decode(data.values.proxy)
end

def _policies():
  return {"enabled": data.values.policies.enabled}
end

def _security():
  return {"network_policies": data.values.security.network_policies}
end

# ###########
# PACKAGES
# ###########

def _cert_manager():
  return {
    "observability": {"logging": _logging(), "metrics": _metrics()},
    "policies": _policies(),
    "proxy": _proxy(),
    "security": _security(),
  }
end

def _cert_manager_webhook_hetzner():
  return {
    "observability": {"logging": _logging(format=False), "metrics": _metrics()},
    "proxy": _proxy(),
    "security": _security(),
  }
end

def _crossplane():
  return {
    "ca_cert_data": data.values.ca_cert_data,
    "observability": {"logging": _logging(format=False), "metrics": _metrics()},
    "proxy": _proxy(),
  }
end

# Dependency Track is served on a subdomain of the base domain, covered by the `*.<domain>` certificate of the Gateway.
def _dependency_track():
  values = {
    "ca_cert_data": data.values.ca_cert_data,
    "observability": {"logging": _logging(), "metrics": _metrics()},
    "proxy": _proxy(),
  }
  if _domain():
    values["ingress"] = {"hostname": "dependency-track." + _domain()}
  end
  return values
end

# The Developer Portal is configured only via its own values.
def _developer_portal():
  return {}
end

# The external Gateway serves `*.<domain>` and `*.<workspace>.<domain>` over HTTPS, for the Knative Services of each workspace.
def _envoy_gateway():
  values = {
    "observability": {"logging": _logging(format=False), "metrics": _metrics(otlp=True), "tracing": _tracing()},
    "tls": {"internal": {"provider": "cert-manager"}},
  }
  if _domain():
    values["gateways"] = {
      "external": {
        "domain": _domain(),
        "tls": {
          "issuer": data.values.ingress.issuer,
          "hostnames": ["*.{}.{}".format(workspace.name, _domain()) for workspace in data.values.workspaces],
        },
      },
    }
  end
  if _is_local():
    values["envoy"] = {
      "service": {
        "type": "NodePort",
        "external_traffic_policy": "Cluster",
        "node_ports": {"http": 30080, "https": 30443},
      },
    }
  end
  return values
end

def _flagger():
  return {
    "ca_cert_data": data.values.ca_cert_data,
    "observability": {"logging": _logging(), "metrics": _metrics()},
    "policies": _policies(),
    "proxy": _proxy(),
  }
end

def _flux():
  return {
    "ca_cert_data": data.values.ca_cert_data,
    "observability": {"logging": _logging(), "metrics": _metrics()},
    "policies": _policies(),
    "proxy": _proxy(),
  }
end

# GitOps Configurer is configured only via its own values.
def _gitops_configurer():
  return {}
end

# The workspaces enforce the restricted Pod Security Standard by default, so Knative sets the secure defaults
# on the Knative Services that don't set them.
def _knative_serving():
  return {
    "ca_cert_data": data.values.ca_cert_data,
    "config": {"features": {"secure-pod-defaults": "Enabled"}},
    "ingress": {"domain": _domain(), "https": _domain() != ""},
    "observability": {"logging": _logging(format=False), "metrics": _metrics(otlp=True), "tracing": _tracing()},
    "policies": _policies(),
    "proxy": _proxy(),
  }
end

def _kyverno():
  return {
    "ca_cert_data": data.values.ca_cert_data,
    "observability": {"logging": _logging(), "metrics": _metrics(otlp=True), "tracing": _tracing(sampling=False)},
    "proxy": _proxy(),
    "security": _security(),
  }
end

# Local clusters like kind and k3d use self-signed Kubelet certificates.
def _metrics_server():
  values = {
    "observability": {"logging": _logging()},
    "policies": _policies(),
  }
  if _is_local():
    values["kubelet"] = {"insecure_tls": True}
  end
  return values
end

def _opentelemetry_operator():
  return {"observability": {"logging": _logging(format=False), "metrics": _metrics()}}
end

def _postgresql_operator():
  return {"observability": {"logging": _logging(format=False), "metrics": _metrics()}}
end

def _rabbitmq_operator():
  return {"observability": {"logging": _logging(format=False), "metrics": _metrics()}}
end

def _secretgen_controller():
  return {
    "observability": {"metrics": _metrics()},
    "security": _security(),
  }
end

def _workspace_provisioner():
  return {"namespaces": struct.decode(data.values.workspaces)}
end

_computed_values = {
  "cert-manager": _cert_manager,
  "cert-manager-webhook-hetzner": _cert_manager_webhook_hetzner,
  "crossplane": _crossplane,
  "dependency-track": _dependency_track,
  "developer-portal": _developer_portal,
  "envoy-gateway": _envoy_gateway,
  "flagger": _flagger,
  "flux": _flux,
  "gitops-configurer": _gitops_configurer,
  "knative-serving": _knative_serving,
  "kyverno": _kyverno,
  "metrics-server": _metrics_server,
  "opentelemetry-operator": _opentelemetry_operator,
  "postgresql-operator": _postgresql_operator,
  "rabbitmq-operator": _rabbitmq_operator,
  "secretgen-controller": _secretgen_controller,
  "workspace-provisioner": _workspace_provisioner,
}

# ###########
# MERGE
# ###########

# Merges the maps recursively. The values in `override` take precedence, including lists, which are replaced.
def _merge(base, override):
  merged = dict(base)
  for key, value in override.items():
    if type(value) == "dict" and type(merged.get(key)) == "dict":
      merged[key] = _merge(merged[key], value)
    else:
      merged[key] = value
    end
  end
  return merged
end

# The values of a package: the computed ones, with the package configuration from the platform values on top.
def package_values(package):
  if package.name not in _computed_values:
    assert.fail("no values function for the {} package in lib/values.star".format(package.name))
  end
  return _merge(_computed_values[package.name](), struct.decode(getattr(data.values, package.key)))
end
