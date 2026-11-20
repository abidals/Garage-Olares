# Changelog — Garage Olares packaging

Packaging-only changes; server features follow upstream
https://git.deuxfleurs.fr/Deuxfleurs/garage.

## 0.0.3 — 2026-11-01
- Server upgraded to Garage **v2.5.0** (official `dxflrs/garage` image). Upstream
  notes: a node upgraded to v2.5.0 cannot be downgraded; access to
  Put/Get/DeleteBucketLifecycle is now restricted to owner-permission keys.
- New optional install field `GARAGE_S3_PUBLIC_ENDPOINT` — rendered as the
  recommended `s3_api.public_endpoint` parameter (public HTTPS URL of the S3
  entrance). Leave empty to skip.

## 0.0.2 — 2026-11-01
- Added `submitter` metadata (abidals).
- Declared `arm64` support (the official `dxflrs/garage:v2.4.1` image ships
  amd64/arm64/arm/386, and the init container image ships amd64/arm64).
- `sourceCode` now points at the upstream repository
  https://git.deuxfleurs.fr/Deuxfleurs/garage (GitHub mirror kept in the
  app description).

## 0.0.1 — 2026-09-09
- Initial packaging: Garage v2.4.1 (official `dxflrs/garage` image),
  single-node mode (replication factor 1), default bucket created
  automatically on first start, public entrances for the S3 API (:3900)
  and the Admin API v2 (:3903), generated RPC secret persisted across
  upgrades via lookups.