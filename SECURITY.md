# Security notes

## What this chart sends where
- The server image is pulled from `docker.io/dxflrs/garage:v2.4.1` (public, multi-arch amd64/arm64/arm/386); the init container uses `beclab/aboveos-busybox:1.37.0` (amd64/arm64).
- No telemetry endpoints are added by this packaging. Garage itself contacts nothing by default.
- Secrets: the S3 access key/secret key and Admin API token are supplied by you at install time; the cluster RPC secret is generated on first install and persisted. All are stored in the `garage-config` Secret inside the app namespace only — **no secrets live in this repository**, nothing is baked into any image.

## Reporting
Please open an issue in this repository for packaging problems. For vulnerabilities
in Garage itself, use the upstream project's security process:
https://garagehq.deuxfleurs.fr/security/

## Known limitations
- Single-node mode (replication factor 1) — there is no built-in redundancy; back up the app Data folder.
- Anonymous S3 requests are rejected by design; clients must sign requests (SigV4).
- Only path-style requests are supported through the Olares gateway (no virtual-host bucket addressing).