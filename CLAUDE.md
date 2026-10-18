# live.capturly.app

Capturly Live: Capturly's self-hosted, branded deployment of VDO.Ninja (browser
peer-to-peer live audio/video for remote guests), served as a static site from
`Dockerfile` + `nginx.conf` at https://live.capturly.app. A fork under AGPL-3.0;
the complete corresponding source of the deployed instance is this repository.

<!-- SYNCED FROM framework/agents/base.md -->
<!-- END SYNC: framework/agents/base.md -->

## Rules of this repo

- The engine is upstream's: only branding, deployment configuration and the
  files README.md lists under "What differs from upstream" change here. Fixes to
  the engine go upstream.
- Keep attribution and the footer "Source Code" link (AGPL compliance).
- No package.json at the root: there is no lint, type-check or test gate; the
  signaling server lives in `capturly-live-signaling`.
