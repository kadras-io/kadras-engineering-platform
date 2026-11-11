# Ingress and TLS

The applications are exposed outside the cluster via the `external` Gateway of the [Envoy Gateway](https://github.com/kadras-io/package-for-envoy-gateway) package, configured via the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io). TLS is terminated on the Gateway, with certificates issued by [cert-manager](https://github.com/kadras-io/package-for-cert-manager).

## Domain

Set the base domain of the applications. The external Gateway serves it over HTTPS with a wildcard certificate (`*.<domain>`), and redirects HTTP requests to HTTPS.

```yaml
ingress:
  domain: example.com
```

Each workspace gets its own wildcard certificate (`*.<workspace>.<domain>`), since Knative Services are served as `<name>.<workspace>.<domain>`, and a wildcard certificate only covers one level of subdomains. Other applications, like Dependency Track (`dependency-track.<domain>`), are served on a subdomain of the base domain.

| Workspace | Knative Service | URL |
|-----------|-----------------|-----|
| `team-a` | `hello` | `https://hello.team-a.example.com` |

Point the DNS records of `*.<domain>` and `*.<workspace>.<domain>` to the address of the `envoy-external` Service in the `envoy-gateway-system` namespace.

```shell
kubectl get service envoy-external -n envoy-gateway-system
```

Without a domain, and outside of the `local` profile, the applications aren't served over HTTPS.

## Issuer

By default, the certificates are issued by `kadras-ca-issuer`, a ClusterIssuer backed by the private CA of the cert-manager package. It's useful for local development and internal environments, but browsers and clients don't trust it unless you add its certificate to their trust store.

```shell
kubectl get secret kadras-root-ca -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 --decode
```

Use any other ClusterIssuer via `ingress.issuer`.

```yaml
ingress:
  domain: example.com
  issuer: my-issuer
```

### Let's Encrypt

The cert-manager package includes a ClusterIssuer for [Let's Encrypt](https://letsencrypt.org). Let's Encrypt issues wildcard certificates only via DNS-01 challenges, so configure the provider of your DNS zone. For example, with Hetzner, via the [cert-manager-webhook-hetzner](https://github.com/kadras-io/package-for-cert-manager-webhook-hetzner) package:

```yaml
ingress:
  domain: example.com
  issuer: letsencrypt-prod-issuer
packages:
  include:
    - cert-manager-webhook-hetzner
cert_manager:
  issuers:
    letsencrypt:
      enabled: true
      environment: production
      email: platform@example.com
      solver: dns01
      dns01:
        provider: hetzner
        credentials:
          secret: hetzner-dns-token
          key: token
          namespace: kadras-system
```

Start with the `staging` environment (`letsencrypt-staging-issuer`), since `production` enforces strict rate limits. For the other DNS providers, see the [cert-manager package issuers](https://github.com/kadras-io/package-for-cert-manager/blob/main/docs/issuers.md).

## Load balancer

With the `run` profile, the external Gateway is exposed via a `LoadBalancer` Service. Configure it in the Envoy Gateway section, for example on Hetzner Cloud:

```yaml
envoy_gateway:
  envoy:
    service:
      annotations:
        load-balancer.hetzner.cloud/location: nbg1
        load-balancer.hetzner.cloud/name: kadras
```

With the `local` profile, it's exposed via the node ports 30080 (HTTP) and 30443 (HTTPS), mapped to the host ports 80 and 443 by the local cluster, and the default domain is `127.0.0.1.sslip.io`, which resolves to the loopback address. See [getting-started.md](getting-started.md).

For the other Gateway settings, like the minimum TLS version and the internal Gateway, see the [Envoy Gateway package](https://github.com/kadras-io/package-for-envoy-gateway).
