---
title: "An update on upki"
summary: |
  This post provides an update on the Canonical-supported upki project, which brings
  browser-grade Public Key Infrastructure to Linux through the efficient CRLite data
  format, with the core revocation engine now functional and available to test.

  Beyond current progress, this post explores broader integration, performance,
  and future capabilities like Certificate Transparency enforcement and Merkle Tree
  Certificates.
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

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/an-update-on-upki/77063), and is reposted here. I welcome comments and further discussion in that thread.

Last year, I [announced](https://jnsgr.uk/2025/12/addressing-linuxs-missing-pki-infra/) that Canonical had begun supporting the development of [upki](https://jnsgr.uk/2025/12/addressing-linuxs-missing-pki-infra/), a project that will bring browser-grade Public Key Infrastructure (PKI) to Linux. Since then, development has been moving at pace thanks to the tireless work of [Dirkjan](https://dirkjan.ochtman.nl/) and [Joe](https://jbp.io/).

In this post, I’ll explore the progress we’ve made, how you can try an early version, and where we’re going next.

### Architecture & Progress

As a reminder, upki’s primary goal is to provide a reliable, privacy-preserving, and efficient certificate revocation mechanism for Linux system utilities, package managers, and language runtimes. The solution is built around [CRLite](https://blog.mozilla.org/security/2020/01/09/crlite-part-1-all-web-pki-revocations-compressed/), an efficient data format that compresses and distributes certificate revocation information at scale.

The upki [repository](https://github.com/rustls/upki) is structured as a Cargo workspace containing five crates, each serving a distinct role:

- **`upki`**: the core library and CLI tool. This crate contains the revocation query engine, the client-side sync logic for fetching filter updates, and the command-line interface. The revocation interface was originally embedded in the CLI, but has since been promoted into the library so that other Rust projects can use it directly as a dependency.
- **`upki-mirror`**: the server-side mirroring tool. This binary fetches and validates CRLite filters from Mozilla's infrastructure such that they can be served using a standard web server like `nginx` or `apache`.
- **`upki-ffi`**: the C Foreign Function Interface. Built as a `cdylib`, this crate uses [`cbindgen`](https://github.com/mozilla/cbindgen) to auto-generate a `upki.h` header file, exposing the revocation query API to C, C++, Go and any other language with C FFI support.
- **`rustls-upki`**: an integration crate that wires upki's revocation engine into [rustls](https://github.com/rustls/rustls), enabling any Rust application using rustls to perform CRLite-backed revocation checks transparently.
- **`revoke-test`**: testing infrastructure for validating revocation queries against known-revoked certificates.

The team recently released [v0.1.0](https://github.com/rustls/upki/releases/tag/upki-0.1.0), which should help us to gather more feedback on the work we've done so far.

### How to try it

If you'd like to try the code in its current form, you'll need to have a version of the Rust toolchain installed. The easiest way to do this on Ubuntu is [using the `rustup` snap](https://documentation.ubuntu.com/ubuntu-for-developers/howto/rust-setup/#installing-the-latest-rust-toolchain-using-rustup):

```shell
# Ensure you have a C compiler in your PATH
sudo apt update
sudo apt install -y build-essential curl

# Install the rustup snap and get the stable toolchain
sudo snap install --classic rustup
rustup install stable

# Install upki
cargo install upki
export PATH="$HOME/.cargo/bin:$PATH"

# Fetch revocation data. This will be done in the background
# when installed through the distro in the future
upki fetch
```

That should be all you need to install the development version of `upki`, and you can now use it to run a revocation check by piping certificate output from `curl` into `upki`:

```shell
curl -sw '%{certs}' https://google.com | upki revocation check
NotRevoked
```

Early versions of docs for the [C FFI crate](https://docs.rs/upki-ffi/latest/upki/) and [Rust crate documentation](https://docs.rs/upki/latest/upki/) are available, but if you'd like to explore, build the project from source, or contribute, the [repository](https://github.com/rustls/upki) is the best place to start. For an example of the C FFI interface in action you can take a look at the [upki-go-demo](https://github.com/rustls/upki-go-demo) Dirkjan published.

### Next Steps

Now the foundational pieces are in place, our focus is shifting to external consumption, performance, and integration with the wider Linux ecosystem. In the coming days there should be an early `0.1.0` binary release.

We'll also be doing some performance benchmarking on the initial fetch and of the revocation checks themselves. Currently, each revocation check reads several CRLite filter files into memory. There may be quick wins to improve this, but we’ll benchmark first and see if it warrants optimisation at this time.

We also need to deploy some production infrastructure for serving the CRLite filters. If you follow the steps above, you'll be fetching from a pre-production web server hosted at [https://upki.rustls.dev](https://upki.rustls.dev). We've built a [Juju charm](https://github.com/jnsgruk/upki-mirror-k8s-operator) for operating the CRLite mirror on Kubernetes. This charm packages the `upki-mirror` binary in a [chiselled Rock](https://ubuntu.com/blog/combining-distroless-and-ubuntu-chiselled-containers), and will be deployed into Canonical's datacentres to serve CRLite data at [crlite.ubuntu.com](https://crlite.ubuntu.com/).

Our Ubuntu Foundations team is also working on packaging the various upki components for inclusion in the Ubuntu archive, which will enable you to `apt install upki` in the future, and also enable us to package and enable it by default in Ubuntu 26.10 and beyond.

### Further Down the Road

While the work above covers what's immediately in front of us, there is scope to expand upki's capabilities further. Two areas of interest are Certificate Transparency enforcement, and support for Merkle Tree Certificates.

#### Certificate Transparency Enforcement

While upki's initial focus is on revocation checking, the project also aims to eventually support [Certificate Transparency](https://certificate.transparency.dev/) (CT) enforcement. CT is a more modern security measure that relies upon a set of publicly auditable, append-only logs that record every TLS certificate issued by a Certificate Authority (CA). This prevents CAs from issuing fraudulent or erroneous certificates without a means for that fraudulent activity to be discovered \- a problem that has [bitten organisations](https://blog.cloudflare.com/unauthorized-issuance-of-certificates-for-1-1-1-1/) in the past.

CT Enforcement would enable clients to refuse to establish a connection unless the server provides cryptographic proof that its certificate has been correctly logged. Browsers like Chrome and Firefox already enforce this, but the rest of the Linux ecosystem would need a tool such as upki to enable such functionality.

#### Intermediate Preloading

A correctly configured TLS server should not only send its own certificate, but also the intermediate certificates needed to chain back to a trusted root. In practice, many servers omit the intermediate certificates, and because browsers have quietly worked around this for years, the misconfiguration often goes unnoticed.

Firefox has been [preloading all intermediates](https://blog.mozilla.org/security/2020/11/13/preloading-intermediate-ca-certificates-into-firefox/) disclosed to the [Common CA Database](https://www.ccadb.org/) (CCADB) since Firefox 75, while Chrome and Edge will silently fetch missing intermediates using the Authority Information Access (AIA) extension in the server's certificate. The result is that a broken certificate chain that works perfectly in every browser will produce an opaque `UNKNOWN_ISSUER` error when accessed by Linux utilities like `curl`.

Because upki already maintains a regularly synced local data store, it's well positioned to ship the known set of intermediates alongside the CRLite filters. This wouldn't provide a security improvement so much as a usability improvement. It would also bring non-browser clients up to parity with browsers with respect to connection reliability. There is an additional privacy benefit too: rather than fetching a missing intermediate from the issuing CA (which discloses browsing activity to the CA), the intermediate is already present locally.

#### Merkle Tree Certificates

Looking even further ahead, upki could support the next generation of web PKI by including support for [Merkle Tree Certificates (MTCs)](https://datatracker.ietf.org/doc/draft-davidben-tls-merkle-tree-certs/). This is an area of active development in the IETF, with Cloudflare and Chrome recently [announcing an experimental deployment](https://blog.cloudflare.com/bootstrap-mtc/).

The motivation for MTCs comes largely from the transition to [Post-Quantum (PQ) cryptography](https://openquantumsafe.org/post-quantum-crypto.html). PQ signatures are significantly larger than their non-PQ counterparts. The signatures for [ML-DSA-44](https://openquantumsafe.org/liboqs/algorithms/sig/ml-dsa.html) are 2,420 bytes compared to 64 bytes for ECDSA-P256. A typical TLS handshake today involves multiple signatures and public keys across the certificate chain and CT proofs, which means a simple swap to PQ algorithms would add tens of kilobytes of overhead per connection and likely a noticeable increase in connection latency.

MTCs address this by rethinking how certificates are validated. Rather than transmitting a full certificate chain with multiple signatures, a Certificate Authority can batch certificates into a Merkle Tree and sign only the tree's root hash. The client then receives just a single signature, a public key, and a compact Merkle tree inclusion proof that demonstrates the certificate's presence in the batch. The signed tree heads can be distributed to clients out-of-band, meaning the per-handshake overhead is drastically reduced.

Because upki already maintains a local data store that is regularly synced, it could cache tree head data alongside CRLite filters, thereby enabling the inclusion proofs sent during TLS handshakes to be even smaller. Rather than proving inclusion all the way from the leaf to the root, the server could send a "truncated" proof that starts partway up the tree, with the client computing the remainder from data it already has locally. There is a [TLS extension](https://datatracker.ietf.org/doc/draft-davidben-tls-merkle-tree-certs/) being developed to negotiate this.

The implementation of MTCs for TLS is still highly experimental. MTCs are not yet deployed in any browser, but upki will lay the groundwork for Linux system utilities to benefit from this evolution as the technology is adopted.

### Summary

In the few weeks since we announced upki, the core revocation engine has been established and is now functional, the CRLite mirroring tool is working and a production deployment in Canonical's datacentres is ongoing. We're now preparing for an alpha release and remain on track for an opt-in preview for Ubuntu 26.04 LTS.

Beyond revocation, we're keeping a close eye on the evolving PKI landscape and particularly CT enforcement and Merkle Tree Certificates.

I'd like to extend my thanks again to [Dirkjan](https://dirkjan.ochtman.nl/) and [Joe](https://jbp.io/) for their continued collaboration on this work, and the utmost professionalism they've demonstrated throughout.
