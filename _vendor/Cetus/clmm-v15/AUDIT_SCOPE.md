# Cetus CLMM v15 Audit Scope

This document identifies the immutable deployment and reproducible source scope
for an independent audit of Cetus CLMM v15.

## Audit target

- Repository path: `packages/cetus_clmm`
- Release: `clmm-v15`
- Mainnet package: `0x260693ec785a6e6c9d81d58c7d2ff72f1288ae0fa6a9725abe05a6478b11f084`
- Original package ID: `0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7a35689b2fb`
- Upgrade transaction: `5sSoTfTiti8kXjJhZeYuFWFcxxvjbZpFQ96rZ3dzeQbC`
- Package object digest: `9rZP5D79m4Yfq9fvtPujtpvU5rhfiYm1JS6LaxcMZVSu`

The package is published as version 15. On 2026-09-18, the mainnet
`GlobalConfig.package_version` was still 14; publication and operational
activation are separate steps.

## Reproduction

Use Sui CLI 1.74.1 from this directory:

```bash
sui client verify-source --build-env mainnet --silence-warnings --json .
sui move test --coverage --trace
```

At synchronization time, source verification succeeded and all 343 tests
passed. Dependency revisions are recorded in `Move.lock`.

## v15 security change

The principal v15 change separates emergency pause and emergency unpause
authorization. Legacy ACL bit 5 remains the emergency-unpause permission, while
new ACL bit 6 is used for emergency pause. Auditors should verify permission
migration, version gating, upgrade/activation ordering, and every call path that
can pause or unpause the protocol.

The audit report should identify the audited Git commit (and release tag once
created), package ID, toolchain version, dependency revisions, and all files in
scope so its conclusions can be reproduced against this deployment.
