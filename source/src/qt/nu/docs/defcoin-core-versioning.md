# Defcoin Core Versioning Specification

Defcoin Core uses an Epoch-SemVer Hybrid three-digit versioning system:

```text
Defcoin Core Nu [Epoch].[Feature].[Patch]
```

The version advances because of code behavior and release compatibility, not
calendar dates.

## Format

- `Epoch`: Static generation and upstream framework lineage. For the current
  Nu cycle, rebased on Litecoin Core v0.21.5.5, this value is locked to `26`.
  It does not change with months or years.
- `Feature`: Backward-compatible feature milestone. Increment this when adding
  new UI features, user-visible workflows, RPC commands, or compatible protocol
  capabilities. Reset `Patch` to `0` when this changes.
- `Patch`: Backward-compatible bug fix, security fix, stability fix,
  performance tweak, packaging fix, or emergency hotfix.

Official public releases must use the strict three-number form. Letter suffixes
such as `26.6.7b` are local candidate, test, or staging labels only unless the
project explicitly promotes that suffix as a named candidate build. Do not treat
letter suffixes as the canonical public release version.

## Concrete Reference: Nu 26.6.8

When reading or generating documentation for `Defcoin Core Nu 26.6.8`, interpret
the digits as:

- `26`: Core architecture era, based on Litecoin Core v0.21.x lineage with
  Defcoin parameters and Nu extensions.
- `6`: Sixth feature milestone on this base engine.
- `8`: Eighth maintenance patch for feature milestone `6`.

## Increment Rules

- Bug, crash, performance, packaging, or security fixes:

  ```text
  26.6.7 -> 26.6.8
  ```

- Backward-compatible features or UI/RPC additions:

  ```text
  26.6.8 -> 26.7.0
  ```

- Mandatory network, consensus, hardfork, or other breaking compatibility
  changes:

  ```text
  26.6.8 -> 26.8.0
  ```

Use release notes to explain the actual behavior change. Do not use placeholder
examples as release facts.

## Codebase Mapping

For `26.6.8`, the source constants and user agent must map as:

```text
CLIENT_VERSION_MAJOR: 26
CLIENT_VERSION_MINOR: 6
CLIENT_VERSION_REVISION: 8
strSubVersion: /Defcoin Core Nu:26.6.8/
```

Any CMake, QML, package, Velopack, installer, about-box, splash-screen, and
release-note version labels must match the intended public release or be
clearly marked as a local candidate suffix.

## References

- Dynamic binary instrumentation release-style precedent:
  <https://dynamorio.org/page_new_release.html>
- Bitcoin hardfork compatibility context:
  <https://blog.lopp.net/has-bitcoin-ever-hard-forked/>
