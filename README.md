# Garage for Olares

[![Release](https://img.shields.io/github/v/release/abidals/Garage-Olares)](../../releases)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](#license)
[![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-blue)](#requirements)

**Garage** is an open-source, S3-compatible object storage service built by [Deuxfleurs](https://git.deuxfleurs.fr/Deuxfleurs/garage) — extremely light and reliable, designed for self-hosting — packaged here as a native **Olares** application.

This repository hosts the Olares chart (packaging) only. It runs upstream Garage **v2.5.0** from the official `dxflrs/garage` image in **single-node** mode (replication factor 1):

- **S3 API** exposed through an Olares entrance (`:3900`, path-style, region `garage`) — **`authLevel: internal`**: reachable only from apps on the same Olares instance (e.g. Silo) and LarePass traffic, never from the open internet
- **Admin API v2** entrance (`:3903`, `/v2/...` endpoints) — same internal level; Garage authenticates every request itself (SigV4 / bearer token)
- On first start the cluster RPC secret is generated automatically and the default access key + bucket from your install form are created — usable right away
- SQLite metadata and object data live in the app's Olares data folder

## Requirements

| Requirement | Notes |
|---|---|
| Olares | 1.12.6 or newer |
| Architecture | `amd64` or `arm64` (the upstream image is multi-arch) |
| Resources | 250m CPU request / 1-core limit, 512 Mi RAM request / 2 Gi limit, 1 Gi disk |
| Storage | The app's own data area (Garage data + meta) |

## Install

### Option A — install the release package (recommended)

1. Grab the package straight from Releases:

   ```sh
   curl -fsSLO https://github.com/abidals/Garage-Olares/releases/latest/download/garage-0.0.3.tgz
   ```

   (For this release: `garage-0.0.3.tgz`.)
2. On your Olares:

   ```sh
   olares-cli market upload garage-0.0.3.tgz
   olares-cli market install garage -s upload --version 0.0.3 --watch
   ```

   Omit `--version` to install the newest uploaded chart.
3. The install form asks for:

   | Field | What to enter |
   |---|---|
   | `GARAGE_DEFAULT_ACCESS_KEY` | S3 access key ID — e.g. `GK` + 32 hex chars (generate with `openssl rand -hex 32` for the suffix) |
   | `GARAGE_DEFAULT_SECRET_KEY` | Matching secret key — 32 hex chars (`openssl rand -hex 32`) |
   | `GARAGE_DEFAULT_BUCKET` | First bucket created automatically at start (default `garage`) |
   | `GARAGE_ADMIN_TOKEN` | Bearer token for the Admin API (`openssl rand -base64 32`) |
   | `GARAGE_S3_PUBLIC_ENDPOINT` | *Optional* — the public HTTPS URL of the S3 entrance; rendered as Garage's `s3_api.public_endpoint`. Leave empty to skip. |

4. Garage appears in **Market → My Apps** with two entrances: **Garage S3 API** and **Garage Admin (API)**.

### Option B — build and upload yourself

```sh
git clone https://github.com/abidals/Garage-Olares.git
cd Garage-Olares
olares-cli chart lint garage
olares-cli chart package garage
olares-cli market upload garage-<version>.tgz
olares-cli market install garage -s upload --version <version> --watch
```

## Using the S3 API

```sh
export AWS_ACCESS_KEY_ID=<access key from install>
export AWS_SECRET_ACCESS_KEY=<secret key from install>
export AWS_DEFAULT_REGION=garage
export AWS_ENDPOINT_URL=https://<s3-url-of-this-app>/

aws s3 ls
aws s3 cp file.txt s3://<bucket>/file.txt
```

Notes:
- Path-style only (no virtual-host buckets through the Olares gateway).
- Region is fixed to `garage` in this deployment.
- Anonymous requests are rejected by design; clients must sign with SigV4.
- Since chart 0.0.4 both entrances default to `authLevel: internal` — the URLs work from apps on the same Olares instance and LarePass traffic, but **not** from external machines (an `aws s3 ls` from your laptop fails). For external CLI access switch the entrance to `public` in the app's settings (survives upgrades on Olares 1.12.7+) or run tools from within the instance.

## Admin API

```sh
curl -s -H "Authorization: Bearer <admin token>" \
  https://<admin-url-of-this-app>/v2/GetClusterStatus | jq
```

Useful calls: `/v2/GetClusterStatus`, `/v2/GetClusterStatistics`, `/v2/ListBuckets`,
`/v2/CreateKey`, `/v2/ImportKey`, `/v2/CreateBucket`.

Full reference: <https://garagehq.deuxfleurs.fr/api/garage-admin-v2.html>

## Pairing with Silo

This chart was packaged as the S3 backend for [Silo for Olares](https://github.com/abidals/Silo-Olares) (media streaming server). In Silo (**Admin → Settings → Storage**), connect Garage to the **Internal / Private (operational) storage** — that's the recommended wiring; the Public section is optional:

1. **Internal (Private / operational) storage**: endpoint = the Garage **S3 API** entrance URL, region = `garage` (exact spelling — Silo defaults to `us-east-1` and Garage rejects the mismatched signature), bucket `silo-internal`, and a dedicated access key / secret key (create one named `silo` via the Admin API `/v2/CreateKey`, grant it read+write on the bucket with `/v2/AllowBucketKey`).
2. Public assets only if you also want Garage to front them: same endpoint/keys with bucket `silo-assets`.
3. Buckets are created automatically on first start from the install form, or anytime via the Admin API (`/v2/CreateBucket`).

## Updating

Upload a newer chart package, then:

```sh
olares-cli market upgrade garage -s upload --version <version> --watch
```

The `garage-config` Secret (access key, secret key, RPC secret) is kept across upgrades. Note: once a data node is upgraded to Garage v2.5.0+ it cannot be downgraded back.

## Uninstalling

Market → My Apps → Garage → Uninstall. Uninstalling removes the app workload; (as with all Olares apps) `--delete-data` additionally clears the app's private Data folder — where Garage's objects and metadata live.

## Troubleshooting

- **Silo (as of v0.1.7): "Connection check failed. Verify the submitted settings and provider availability."** — nine times out of ten this is a **region mismatch**: Silo's S3 client falls back to `us-east-1` when the region field is empty, while this deployment always signs with region `garage`. Set **Region = `garage`** in both storage sections and re-run the check. (Silo intentionally hides the provider's error text, so the failure looks generic.)
- **403 "Garage does not support anonymous access yet" when opening the S3 URL in a browser** — that is normal: Garage only answers signed requests. Verify with `aws s3 ls` or the Admin API instead.
- **Logs**: `olares-cli cluster pod logs -n <namespace> <pod> -c garage --follow`.
- See the upstream docs: <https://garagehq.deuxfleurs.fr/documentation/>

## License

- This Olares packaging (chart, manifests, docs) is released under **AGPL-3.0**, matching the upstream project.
- Upstream Garage: [Deuxfleurs/garage](https://git.deuxfleurs.fr/Deuxfleurs/garage) (GitHub mirror: [deuxfleurs-org/garage](https://github.com/deuxfleurs-org/garage)) — AGPL-3.0, © Deuxfleurs contributors.

Submitter of this packaging: **abidals**

## Disclaimers

- This is an unofficial community packaging; for official docs and support visit <https://garagehq.deuxfleurs.fr/>.
- Single-node mode (replication factor 1) — not a distributed/HA cluster; keep backups of the app Data folder. For multi-node deployments follow the official upstream guide.