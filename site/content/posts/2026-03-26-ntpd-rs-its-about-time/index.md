---
title: "ntpd-rs: it's about time!"
summary: |
  Ubuntu is transitioning to the Rust-based ntpd-rs as its
  default time synchronization utility, replacing chrony,
  linuxptp, and gpsd to deliver a unified, memory-safe solution
  for NTP, NTS, and PTP.
  
  This move, in partnership with the Trifecta Tech Foundation,
  strengthens Ubuntu’s resilience goals, with full adoption
  planned across the Ubuntu 26.10 and 27.04 releases.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
  - Security
  - PTP
  - NTP
  - nptd-rs
  - chrony
layout: post
cover: cover.jpg
coverAlt: |
  An ornate mechanical clock movement.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/ntpd-rs-its-about-time/79154), and is reposted here. I welcome comments and further discussion in that thread.

## Introduction

I am thrilled to announce the next target in our campaign to replace core system utilities with memory-safe Rust rewrites in Ubuntu. In upcoming releases, Ubuntu will be adopting [ntpd-rs](https://trifectatech.org/projects/ntpd-rs/) as the default time synchronization client and server, eventually replacing [`chrony`](https://chrony-project.org/), [`linuxptp`](https://www.linuxptp.org/) and with any luck, [`gpsd`](https://gpsd.io/) for time syncing use-cases.

[`ntpd-rs`](https://trifectatech.org/projects/ntpd-rs/) is a full-featured implementation of the Network Time Protocol (NTP), written entirely in Rust. Maintained by the Trifecta Tech Foundation as part of [Project Pendulum](https://github.com/pendulum-project), `ntpd-rs` places a strong focus on security, stability, and memory safety.

To deliver on this goal, we're building on our partnership with the [Trifecta Tech Foundation](https://trifectatech.org/) who are behind [sudo-rs](https://trifectatech.org/projects/sudo-rs/), [zlib-rs](https://trifectatech.org/projects/zlib-rs/) and more. We will be funding the Trifecta Tech Foundation to build new features, enhance security isolation, and ultimately deliver a unified, memory-safe time synchronization utility for the Linux ecosystem. This work meshes well with the Trifecta Tech Foundations goals to improve the security of time synchronization everywhere.

## NTP, NTS, and PTP

Before diving into the mechanics and reasoning behind the transition, I wanted to give some background on the protocols at play, and the problems we're hoping to solve. Keeping accurate time is a critical system function, not least because it involves constant interaction with the internet and forms the basis for cryptographic verification in protocols such as Transport Layer Security (TLS).

**NTP (Network Time Protocol)** is the foundational protocol that most operating systems implement to accurately determine the current time from a network source.

**NTS (Network Time Security)** is to NTP what HTTPS is to HTTP. Historically, the Network Time Protocol was used unencrypted, like many of the early web protocols. NTS introduces cryptographic security to time synchronization, ensuring that bad actors cannot intercept or spoof time data. We already pushed to make NTS the default out-of-the-box in Ubuntu 25.10, which we accomplished by migrating away from `ntpd` to `chrony` as the default time-syncing implementation.

**PTP (Precision Time Protocol)** is used for systems that require sub-microsecond synchronization. While the precision offered by a standard NTP deployment is sufficient for general-purpose computing, PTP is often used for complex, specialized deployments like telecommunications networks, power grids, and automotive applications.

## Proven at Scale

Transitioning core utilities in Ubuntu comes with a responsibility to ensure that replacements are of high quality, resilient and offer something to the platform. We may be the first major Linux distribution to adopt ntpd-rs by default, but we aren't the first to recognize the readiness of `ntpd-rs` \- it has already been [proven at scale by Let's Encrypt](https://letsencrypt.org/2024/06/24/ntpd-rs-deployment).

While Let's Encrypt's core Certificate Authority software has always been written in memory-safe Go, their server operating systems and network infrastructure historically relied on memory-unsafe languages like C and C++, which routinely led to vulnerabilities requiring patching. 

Following extensive development, `ntpd-rs` was deployed to Let's Encrypt's staging environment in April 2024, and rolled out to full production by June 2024, marking a major milestone for ntpd-rs.

The fact that one of the world's most prolific and security-conscious certificate authorities trusts `ntpd-rs` to keep time across its fleet should provide us, and our enterprise customers, with tremendous confidence in its resilience and suitability.

## A Single, Memory-Safe Utility for NTP and PTP

We want to provide a single utility for configuring both NTP/NTS and Precision Time Protocol (PTP) on Linux. The Trifecta Tech Foundation is concurrently developing [Statime](https://trifectatech.org/projects/statime/), a memory-safe PTP implementation that delivers synchronization performance on par with `linuxptp`, but with the goal of being easier to configure and use.

The goal is to integrate Statime's PTP capabilities directly into `ntpd-rs`, improving the user experience by bringing all time synchronization concerns into one utility with common configuration and usage patterns, obviating the need for complex manual configuration (and troubleshooting) that users of `linuxptp` may be familiar with.

## Timelines and Goals

As with our transition to `sudo-rs` and `uutils coreutils`, leading the mainstream adoption of foundational system utilities comes with responsibility. We want to ensure that `ntpd-rs` matches the security isolation and performance standards our users expect from `chrony`.

Canonical is funding the Trifecta Tech Foundation's development efforts toward these goals over the coming cycles. This work will take place between July 2026 and January 2027 in several major milestones. Our current timeline and targeted goals are:

* **Ubuntu 26.10:** If all goes well, we aim to land the latest version of `ntpd-rs` in the archive, making it available to test.  
* **Ubuntu 27.04:** By 27.04, `ntpd-rs` should have integrated `statime`, and we will ship the unified client/server binary for NTP, NTS and PTP in Ubuntu by default, with the aim of providing a smooth migration path for those who already manage complex `chrony` configs.

To get us there, the Trifecta Tech Foundation will be working on the following items:

* **Feature Parity & Hardware Support:** Adding `gpsd` IP socket support, multi-threading support for NTP servers, and support for multi-homed servers.  
* **Security & Isolation:** `chrony` is isolated via AppArmor and seccomp. We'll be working on robust AppArmor and seccomp profiles for `ntpd-rs` to ensure we don't buy memory safety at the cost of system-level privilege boundaries. We are also ensuring `rustls` can use `openssl` as a crypto provider to satisfy strict corporate cryptography policies.  
* **PTP & Automotive Profiles:** Adding support for gPTP, which will allow us to support complex deployments like the Automotive profile directly from `nptd-rs` (via Statime). Additionally, experimental support for the proposed Client-Server PTP protocol (CSPTP, IEEE 1588.1) will be added.  
* **Benchmarking & Testing:** Comprehensive benchmarking of long-term memory, CPU usage, and synchronization performance against `chrony` to give our cloud partners and enterprise users complete confidence in the transition.  
* **User-experience:** Logging improvements and enhancements to configuration that help users configure the time synchronisation target to optimise network usage, as well as improvements to the ntp-cli

## About the Trifecta Tech Foundation

Trifecta Tech Foundation is a non-profit and a Public Benefit Organisation (501(c)(3) equivalent) that creates open-source building blocks for critical infrastructure software. Their initiatives on data compression, time synchronization, and privilege boundary, impact the digital security of millions of people. If you'd like to support their work, please contact them via https://trifectatech.org/support.

## Summary

I am really excited to deepen our already productive relationship with the Trifecta Tech Foundation to make these transitions viable for the wider ecosystem. We'll be working hard on testing and integration to ensure seamless migration paths, and heavily document the changes ahead of the 26.10 and 27.04 releases.

Stay tuned!
