# Verifying the Tekton Pipelines Package Release

This package is published as an OCI artifact, signed with Sigstore [Cosign](https://docs.sigstore.dev/cosign/overview), and associated with a [SLSA Provenance](https://slsa.dev/provenance) attestation.

Using `cosign`, you can display the supply chain security related artifacts for the `ghcr.io/kadras-io/engineering-platform` images. Use the specific digest you'd like to verify.

```shell
cosign tree ghcr.io/kadras-io/engineering-platform
```

The result:

```shell
📦 Supply Chain Security Related artifacts for an image: ghcr.io/kadras-io/engineering-platform
└── 🔐 Signatures for an image tag: ghcr.io/kadras-io/engineering-platform:sha256-be16d0c9bf7238e991fd7082e4e22707d8969b7904266c2d4476d45fc043555a.sig
   └── 🍒 sha256:3155f34d804f7c0c1b7067db6b200591835c5612faaa45469952b1bb8ace8f4c
└── 💾 Attestations for an image tag: ghcr.io/kadras-io/engineering-platform:sha256-be16d0c9bf7238e991fd7082e4e22707d8969b7904266c2d4476d45fc043555a.att
   └── 🍒 sha256:ce0068e03c1b25884ab7a774408956a930f5c6e087c431ee24f9c692d3c761f5
```

You can verify the signature and its claims:

```shell
cosign verify \
   --certificate-identity-regexp https://github.com/kadras-io \
   --certificate-oidc-issuer https://token.actions.githubusercontent.com \
   ghcr.io/kadras-io/engineering-platform | jq
```

You can also verify the SLSA Provenance attestation associated with the image.

```shell
cosign verify-attestation --type slsaprovenance \
   --certificate-identity-regexp https://github.com/slsa-framework \
   --certificate-oidc-issuer https://token.actions.githubusercontent.com \
   ghcr.io/kadras-io/engineering-platform | jq .payload -r | base64 --decode | jq
```
