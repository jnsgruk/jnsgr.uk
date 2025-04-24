---
title: "Adopting sudo-rs By Default in Ubuntu 25.10"
summary: |
  A follow up to "Carefully But Purposefully Oxidising Ubuntu" in which I describe
  the plan to migrate to sudo-rs by default in Ubuntu 25.10. Additionally, I cover
  some updates on the progress with uutils coreutils, and future plans for SequoiaPGP
  in APT and Ubuntu.
tags:
  - Development
  - Ubuntu
  - Canonical
  - Blog
  - Rust
  - coreutils
  - uutils
  - sudo-rs
  - Sequoia
  - OpenPGP
  - APT
layout: post
cover: cover.svg
coverAlt: |
  Ferris the crab perched on top of the Ubuntu logo.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/60583), and is reposted here. I welcome comments and further discussion in that thread.

## Introduction

Following on from [Carefully But Purposefully Oxidising Ubuntu](https://jnsgr.uk/2025/03/carefully-but-purposefully-oxidising-ubuntu/), Ubuntu will be the first major Linux distribution to adopt `sudo-rs` as the default implementation of `sudo`, in partnership with the [Trifecta Tech Foundation](https://trifectatech.org/)

The change will be effective from the release of Ubuntu 25.10. You can see the Trifecta Tech Foundation's announcement [here](https://trifectatech.org/blog/memory-safe-sudo-to-become-the-default-in-ubuntu/).

## What is `sudo-rs`?

`sudo-rs` is a reimplementation of the traditional `sudo` tool, written in Rust. It’s being developed by the [Trifecta Tech Foundation (TTF)](https://trifectatech.org/), a nonprofit focused on building secure, open source infrastructure components. The project is part of the Trifecta Tech Foundation's [Privilege Boundary initiative](https://trifectatech.org/initiatives/privilege-boundary/), which aims to handle privilege escalation with memory-safe alternatives.

The `sudo` command has long served as the defacto means of privilege escalation on Linux. As described in the [original post](https://jnsgr.uk/2025/03/carefully-but-purposefully-oxidising-ubuntu/), Rust provides strong guarantees against certain classes of memory-safety issues, which is pivotal for components at the privilege boundary.

The `sudo-rs` team is collaborating with [Todd Miller](https://www.millert.dev/), who’s maintained the original `sudo` for over thirty years. `sudo-rs` should not be considered a fork in the road, but rather a handshake across generations of secure systems. Throughout the development of `sudo-rs`, the TTF team have also made contributions to enhance the original `sudo` implementation.

The `sudo-rs` project is designed to be a drop in replacement for the original tool. For the vast majority of users, the upgrade should be completely transparent to their workflow. That said, `sudo-rs` is a not a "blind" reimplementation. The developers are taking a "less is more" approach. This means that some features of the original `sudo` may not be reimplemented if they serve only niche, or more recently considered "outdated" practices.

Erik Jonkers, Chair of the Trifecta Tech Foundation explains:

> While no piece of software - in any language - is flawless, we believe the transition to Rust in systems programming is a vital step forward, it is very exciting to see Ubuntu committing to `sudo-rs` and taking the lead in moving the needle.

## Sponsoring Mainstream Adoption

Leading the mainstream adoption of a replacement to such a universally understood tool comes with responsibility. Before committing to ship `sudo-rs` in Ubuntu 26.04 LTS, we'll test the transition in Ubuntu 25.10. We're also sponsoring the development of some specific items, which has manifested as [Milestone 5](https://trifectatech.org/initiatives/workplans/sudo-rs/#current-work) in the upstream project:

- Coarse-grained shell escape prevention (NOEXEC) on Linux (See [PR #1073](https://github.com/trifectatechfoundation/sudo-rs/pull/1073))
- The ability to control AppArmor profiles (First [PR #1067](https://github.com/trifectatechfoundation/sudo-rs/pull/1067))
- A `sudoedit` implementation
- Support for Linux Kernels older than version 5.9

The final item may seem out of place, but because Ubuntu 20.04 LTS is still in support, without this work there could be situations where `sudo` fails to function if, for example, a 26.04 LTS OCI container was run on a 20.04 LTS host!

The team have also already [begun work](https://github.com/trifectatechfoundation/sudo-rs/pull/1079) on ensuring that the test-suite is as compatible as possible with Ubuntu, to ensure any issues are caught early.

This isn’t just about shipping a new binary. It’s about setting a direction. We're not abandoning C, or even rewriting all the utilities ourselves, but by choosing to replace one of the most security-critical tools in the system with a memory-safe alternative, we're making a statement: resilience and sustainability are not optional in the future of open infrastructure.

## Progress on `coreutils`

Since the initial announcement, we've been working hard to more clearly define a plan for the migration to uutils `coreutils` in 25.10 and beyond. Similarly to our engagement with the Trifecta Tech Foundation, we're also sponsoring the uutils project to ensure that some key gaps are closed before we ship 25.10. The sponsorship will primarily cover the development of SELinux support for common commands such as `mv`, `ls`, `cp`, etc.

The first step toward developing SELinux support was to [add support for automated testing in Github Actions](https://github.com/uutils/coreutils/pull/7440/files), since then the maintainers have begun work on the actual implementation.

The other feature we're sponsoring is internationalisation support. At present, some of the utility implementations (such as `sort`) have an incomplete understanding of locales, and therefore may yield unexpected results. We expect that these two features should land in time for us to ship in 25.10, and we'll continue to work with the uutils project throughout the 26.04 LTS cycle to close any remaining gaps we identify in the interim release.

One of the major concerns outlined in Julian's post is about binary size. We've got a few tricks we can play here to get the size down, and there is already some conversation started [upstream in Debian](https://salsa.debian.org/rust-team/debcargo-conf/-/merge_requests/895) on how that might be achieved. There are also security implications, such as AppArmor’s lack of support for multi-call binaries. We’re currently working with the respective upstreams to discuss addressing this systematically, through in the interim we may need to build small wrapper binaries to enable compatibility with existing AppArmor profiles from the start.

## Migration Mechanics

Julian Klode [posted recently](https://discourse.ubuntu.com/t/migration-to-rust-coreutils-in-25-10/59708) on the Ubuntu Discourse outlining the packaging plan that will enable us both to migrate transparently to uutils `coreutils`, but also provide a convenient means for users to opt-out and switch back to GNU `coreutils` if they wish, or if they identify a gap in the new implementation. I expect this will be rare, but we want to make sure it's as easy as possible to revert, and will be documenting this in detail before release.

Replacing coreutils isn't as simple as swapping binaries. As an `Essential` package, its replacement must work immediately upon unpacking without relying on maintainer scripts, and without conflicting files across packages. To solve this, we’re introducing new `coreutils-from-uutils` and `coreutils-from-gnu` packages, as well as `coreutils-from` itself. For all the gory details, see the [Discourse post](https://discourse.ubuntu.com/t/migration-to-rust-coreutils-in-25-10/59708)!

The packaging work required to switch to `sudo-rs` is somewhat less complicated than with `coreutils`. The package is already available in Ubuntu (which you can still test on Ubuntu 24.04, 24.10 and 25.04 with [oxidizr](https://github.com/jnsgruk/oxidizr)!), but unlike `coreutils`, `sudo` is not an `Essential` package, so we'll be able to make use of the Debian [alternatives](https://wiki.debian.org/DebianAlternatives) system for the transition.

## Summary

Things are progressing nicely. We’ve established strong, productive relationships and are sponsoring work upstream to make these transitions viable.

We've got a strategy for migrating the default implementation of `coreutils` and `sudo` in Ubuntu 25.10 which will enable a seamless revert in cases where that is desired. While `sudo-rs` will be the default in 25.10, the original `sudo` will remain available for users who need it, and we’ll be gathering feedback to ensure a smooth transition before the 26.04 LTS.

Additionally, we've begun investigating the feasibility of providing [SequoiaPGP](https://sequoia-pgp.org/) and using it in APT instead of GnuPG. SequoiaPGP is a new OpenPGP library with a focus on safety and correctness, written in Rust. The GnuPG maintainers have recently forked the OpenPGP standard and are no longer compliant with it. Sequoia provides a modern alternative to GnuPG with strict behavior, and is already used in various other systems. More details to follow!

Stay tuned!
