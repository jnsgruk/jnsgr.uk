---
title: "Try the `upki` preview for Ubuntu"
summary: |
  Development of the `upki` project, which aims to bring
  browser-grade cryptography primitives to low-level
  Linux system utilities, continues at pace.

  As of now, users of Ubuntu 26.04 LTS and the Ubuntu
  26.10 development branch can try out the `upki` client
  in a preview provided through a PPA.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
  - Security
  - PKI
  - CRLite
  - upki
layout: post
cover: cover.png
coverAlt: |
  A Canonical branded slide showing the rustls and upki logos
  from a recent conference talk.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/try-the-upki-preview-for-ubuntu/84705), and is reposted here. I welcome comments and further discussion in that thread.

The development of [upki](https://github.com/rustls/upki) has been steadily progressing over the past few months. Since my [last update](https://jnsgr.uk/2026/02/upki-update/), the project has released a beta version of the CLI tool and library, and the Ubuntu Foundations team has released a preview that users of Ubuntu 26.04 LTS and Ubuntu 26.10 development snapshots can try out.

The preview is still experimental, but it contains both the `upki` client packages, and the initial OpenSSL integration. An instance of the upki mirror which serves the CRLite filter data is being hosted in Canonical's infrastructure at `upki.ubuntu.com`.

In this post I’ll briefly recap what upki is trying to achieve, cover the infrastructure and packaging work that has landed, and show how to try the preview on Ubuntu 26.04 LTS or Ubuntu 26.10.

<details>
<summary><strong>Recap: what is upki?</strong></summary>
Linux has long had a gap in how it handles Web PKI data outside browsers. Firefox and Chromium have mature, browser-specific infrastructure for certificate revocation and related PKI data, but system utilities, package managers, language runtimes and many command-line tools have historically lacked a consistent mechanism for checking whether a publicly trusted TLS certificate has been revoked.

upki’s first goal is to bring reliable, efficient and privacy-preserving revocation checking to Linux and other Unix-like operating systems. It builds on Mozilla’s CRLite work, using compact filter data that can be synced locally and queried offline. The client can then answer the question “is this certificate revoked?” without leaking browsing activity to a certificate authority (CA) and without requiring every application to implement its own CRL management stack.

The project is designed around a few interfaces:

- a command-line tool for fetching revocation data and checking certificate chains;
- a Rust library for direct integration with Rust applications;
- a C FFI for integration from C, C++, Go and other runtimes;
- a `rustls-upki` integration crate for Rust applications using rustls;
- and an `upki-openssl` integration layer that exposes an OpenSSL verification callback.

Longer-term, the same local data distribution mechanism could support other browser-grade Web PKI data, including intermediate preloading, Certificate Transparency policy, root distrust information and, further out, Merkle Tree Certificates.
</details>

## Recent progress

The upstream [rustls/upki](https://github.com/rustls/upki) repository has moved on substantially since the initial `upki-0.1.0` release in February. The current beta pre-release is [`upki-1.0.0-beta.1`](https://github.com/rustls/upki/releases/tag/upki-1.0.0-beta.1), published on 10 June 2026.

Since then, the C FFI has been folded into the main `upki` crate and now has a documented minimal example, `upki-openssl` has landed, exposing `upki_openssl_verify_callback()` for OpenSSL-based clients, and the `rustls-upki` crate now provides policy-controlled behaviour for missing data, certificates not covered by revocation data, and certificates without Signed Certificate Timestamps (SCTs).

The `upki` package we're making available in a PPA installs a system-wide configuration file under `/etc/upki/config.toml`, creates a dedicated `upki` service user, and installs an `upki-fetch.timer` that runs every two hours after an initial boot delay.

## Install the development preview

> This preview is intended for testing only. It includes patched OpenSSL packages, so use a disposable VM or test system, not a production machine.

On Ubuntu 26.04 LTS or Ubuntu 26.10, add the preview PPA:

```shell
sudo add-apt-repository ppa:ubuntu-foundations-team/upki-preview
sudo apt install openssl upki libupki-openssl1
```

On Ubuntu 26.10, `upki` is intended to come from the archive while the preview PPA supplies the patched OpenSSL integration. On Ubuntu 26.04 LTS, the PPA supplies both the backported `upki` package and the patched OpenSSL packages.

Once installed, the revocation cache will populate on a timer (run `systemctl status upki-fetch.timer` for details). To trigger a fetch manually:

```shell
sudo -u upki upki fetch
```

For a manual check, pipe a certificate chain from `curl` into upki:

```shell
$ curl -sw '%{certs}' https://google.com | upki revocation check
NotRevoked

$ curl -sw '%{certs}' https://revoked-ctrca.certificates.certum.pl/ | upki revocation check
CertainlyRevoked
```

For the OpenSSL path, tools linked against the patched OpenSSL build can exercise revocation checking during certificate verification. For example, testing against a deliberately revoked certificate endpoint should fail during the TLS handshake with OpenSSL reporting a revoked certificate:

```shell
$ curl https://revoked-ctrca.certificates.certum.pl/
curl: (60) SSL certificate OpenSSL verify result: certificate revoked (23)
More details here: https://curl.se/docs/sslcerts.html.
curl failed to verify the legitimacy of the server and therefore could not establish a secure connection to it.
To learn more about this situation and how to fix it, please visit the webpage mentioned above.
```

The integration with OpenSSL is probably the most important part of this preview. When the packaging is finalised for Ubuntu (and included by default), any utility that links against a patched TLS provider (like OpenSSL), and follow the standard certificate verifications path should benefit from upki-backed revocation checking without application-specific changes.

The current preview is intentionally broad so that we can test the plumbing. The final integration policy may be narrower, and some applications that disable or override OpenSSL verification will need direct application-level integration rather than relying solely on a library callback.

## Canonical-hosted infrastructure

One of the pieces I called out in the last update was production infrastructure. upki needs a mirror for CRLite filter data so that clients are not coupled directly to Mozilla’s internal serving infrastructure, and so that distributions and large deployments can point their systems at a stable, policy-controlled endpoint.

That work is now in place for the preview. The Ubuntu preview packages point at:

```toml
[revocation]
fetch-url = "https://upki.ubuntu.com/revocation/"
```

The endpoint is live and serving a [`manifest.json`](https://upki.ubuntu.com/revocation/manifest.json) describing the current revocation filter set.  The service is operated using the [upki-mirror Kubernetes operator](https://github.com/jnsgruk/upki-mirror-k8s-operator), a Charmed Operator that drives the `upki-mirror` service on Kubernetes. The operator packages the mirror binary in a [chiseled](https://ubuntu.com/containers/chiseled) container and serves the generated filter data with nginx.

## What’s next

The next phase is about polishing the preview into something we can confidently integrate more widely. The aim is to ship `upki` and its early integrations by default in Ubuntu 26.10.

Over the coming weeks we're hoping to gather feedback from this preview and fix any issues in the packaging/Ubuntu integration, while the core team behind upki continues to work on the OpenSSL integration and measuring the fetch performance, cache size and revocation query latency on real systems.

As always, thanks to [Dirkjan](https://github.com/djc), [Joe](https://github.com/ctz), [Julian](https://github.com/julian-klode) and everyone else contributing to the implementation, packaging and infrastructure work that has made this preview possible.  