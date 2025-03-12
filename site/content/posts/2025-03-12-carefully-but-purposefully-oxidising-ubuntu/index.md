---
title: "Carefully But Purposefully Oxidising Ubuntu"
summary: |
  This post explores modern equivalents of foundational system utilities such as coreutils and
  sudo, introduces an experimental utility for testing them, and maps out a path to their
  widespread adoption in Ubuntu.
tags:
  - Development
  - Ubuntu
  - Canonical
  - Blog
  - Rust
  - Resilience
  - coreutils
  - uutils
  - sudo
  - oxidizr
layout: post
cover: cover.jpg
coverAlt: |
  Metal, slightly rusted tools hanging above a wooden workbench.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/carefully-but-purposefully-oxidising-ubuntu/56995), and is reposted here. I welcome comments and further discussion in that thread.

## Introduction

Last month I published [Engineering Ubuntu For The Next 20 Years](https://jnsgr.uk/2025/02/engineering-ubuntu-for-the-next-20-years/), which outlines four key themes for how I intend to evolve Ubuntu in the coming years. In this post, I'll focus on "Modernisation". There are many areas we could look to modernise in Ubuntu: we could focus on the graphical shell experience, the virtualisation stack, core system utilities, default shell utilities, etc.

Over the years, projects like GNU Coreutils have been instrumental in shaping the Unix-like experience that Ubuntu and other Linux distributions ship to millions of users. According to the GNU [website](https://www.gnu.org/software/coreutils/):

> The GNU Core Utilities are the basic file, shell and text manipulation utilities of the GNU operating system. These are the core utilities which are expected to exist on every operating system.

This package provides utilities which have become synonymous with Linux to many - the likes of `ls`, `cp`, and `mv`. In recent years, there has been an [effort](https://uutils.github.io/) to reimplement this suite of tools in Rust, with the goal of reaching 100% compatibility with the existing tools. Similar projects, like [sudo-rs](https://github.com/trifectatechfoundation/sudo-rs), aim to replace key security-critical utilities with more modern, memory-safe alternatives.

Starting with Ubuntu 25.10, my goal is to adopt some of these modern implementations as the default. My immediate goal is to make uutils' coreutils implementation the default in Ubuntu 25.10, and subsequently in our next Long Term Support (LTS) release, Ubuntu 26.04 LTS, if the conditions are right.

## But… why?

Performance is a frequently cited rationale for "Rewrite it in Rust" projects. While performance is high on my list of priorities, it's not the primary driver behind this change. These utilities are at the heart of the distribution - and it's the enhanced resilience and safety that is more easily achieved with Rust ports that are most attractive to me.

The Rust language, its type system and its borrow checker (and its community!) work together to encourage developers to write safe, sound, resilient software. With added safety comes an increase in security guarantees, and with an increase in security comes an increase in overall resilience of the system - and where better to start than with the foundational tools that build the distribution?

I recently read an [article](https://smallcultfollowing.com/babysteps/blog/2025/03/10/rust-2025-intro/) about targeting foundational software with Rust in 2025. Among other things, the article asserts that "foundational software needs performance, reliability — and productivity". If foundational software fails, so do all of the other layers built on top. If foundational packages have performance bottlenecks, they become a floor on the performance achievable by the layers above.

Ubuntu powers millions of devices around the world, from servers in your data centre, to safety critical systems in autonomous systems, so it behooves us to be absolutely certain we're shipping the most resilient and trustworthy software we can.

There are lots of ways to achieve this: we can provide [long term support for projects like Kubernetes](https://canonical.com/blog/12-year-lts-for-kubernetes), we can [assure the code we write](https://canonical.com/blog/canonicals-commitment-to-quality-management), and we can [strive to achieve compliance with safety-centric standards](https://canonical.com/blog/canonical-achieves-iso-21434-certification), but another is by shipping software with the values of safety, soundness, correctness and resilience at their core.

That's not to throw shade on the existing implementations, of course. Many of these tools have been stable for many years, quietly improving performance and fixing bugs. A lovely side benefit of working on newer implementations, is that it [sometimes facilitates](https://ferrous-systems.com/blog/testing-sudo-rs/) improvements in the original upstream projects, too!

I've written about my desire to increase the number of Ubuntu contributors, and I think projects like this will help. Rust may present a steeper learning curve than C in some ways, but by providing such a strong framework around the use of memory it also lowers the chances that a contributor accidentally commits potentially unsafe code.

## Introducing `oxidizr`

I did my homework before writing this post. I wanted to see how easy it was for me to live with these newer implementations and get a sense of their readiness for prime-time within the distribution. I also wanted a means of toggling between implementations so that I could easily switch back should I run into incompatibilities - and so [`oxidizr`](https://github.com/jnsgruk/oxidizr) was born!

> `oxidizr` is a command-line utility for managing system experiments that replace traditional Unix utilities with modern Rust-based alternatives on Ubuntu systems.

The `oxidizr` utility enables you to quickly swap in and out newer implementations of certain packages with _relatively_ low risk. It has the notion of _Experiments_, where each experiment is a package that already exists in the archive that can be swapped in as an alternative to the default.

Version [1.0.0](https://github.com/jnsgruk/oxidizr/releases/tag/v1.0.0) supports the following experiments:

- [uutils coreutils](https://github.com/uutils/coreutils)
- [uutils findutils](https://github.com/uutils/findutils)
- [uutils diffutils](https://github.com/uutils/diffutils)
- [sudo-rs](https://github.com/trifectatechfoundation/sudo-rs)

### How does it work?

Each experiment is subtly different since the paths of the utilities being replaced vary, but the process for enabling an experiment is generally:

- Install the alternative package (e.g. `apt install rust-coreutils`)
- For each binary shipped in the new package:
  - Lookup the default path for that utility (e.g `which date`)
  - Back up that file (e.g. `cp /usr/bin/date /usr/bin/.date.oxidizr.bak`)
  - Symlink the new implementation in place (e.g. `ln -s /usr/bin/coreutils /usr/bin/date`)

There is also the facility to "disable" an experiment, which does the reverse of the sequence above:

- For each binary shipped in the new package:
  - Lookup the default path for the utility (e.g `which date`)
  - Check for and restore any backed up versions (e.g `cp /usr/bin/.date.oxidizr.bak /usr/bin/date`)
- Uninstall the package (e.g. `apt remove rust-coreutils`)

Thereby returning the system back to its original state! The tool is covered by a suite of integration tests which illustrate this behaviour which you can find [on Github](https://github.com/jnsgruk/oxidizr/tree/ca955677b4f5549e5d7f06726f5c5cf1846fe448/tests)

### Get started

> ⚠️ WARNING ⚠️: `oxidizr` is an experimental tool to play with alternatives to foundational system utilities. It may cause a loss of data, or prevent your system from booting, so use with caution!

There are a couple of ways to get `oxidizr` on your system. If you already use `cargo`, you can do the following:

```bash
cargo install --git https://github.com/jnsgruk/oxidizr
```

Otherwise, you can download and install binary releases from [Github](https://github.com/jnsgruk/oxidizr/releases):

```bash
# Download version 1.0.0 and extract to /usr/bin/oxidizr
curl -sL "https://github.com/jnsgruk/oxidizr/releases/download/v1.0.0/oxidizr_Linux_$(uname -m).tar.gz" | sudo tar -xvzf - -C /usr/bin oxidizr
```

Once installed you can invoke `oxidizr` to selectively enable/disable experiments. The default set of experiments in `v1.0.0` is `rust-coreutils` and `sudo-rs`:

```bash
# Enable default experiments
sudo oxidizr enable
# Disable default experiments
sudo oxidizr disable
# Enable just coreutils
sudo oxidizr enable --experiments coreutils
# Enable all experiments without prompting with debug logging enabled
sudo oxidizr enable --all --yes -v
# Disable all experiments without prompting
sudo oxidizr disable --all --yes
```

The tool should work on all versions of Ubuntu after 24.04 LTS - though the `diffutils` experiment is only available from Ubuntu 24.10 onward.

The tool itself is stable and well covered with unit and integration tests, but nonetheless I'd urge you to start with a test virtual machine or a machine that _isn't_ your production workstation or server! I've been running the `coreutils` and `sudo-rs` experiments for around 2 weeks now on my Ubuntu 24.10 machines and haven't had many issues (more on that below…).

## How to Help

If you're interested in helping out on this mission, then I'd encourage you to play with the packages, either by installing them yourself or using `oxidizr`. Reply to the Discourse post with your experiences, file bugs and perhaps even dedicate some time to the relevant upstream projects to help with resolving bugs, implementing features or improving documentation, depending on your skill set.

You can also join us to discuss on our [Matrix instance](https://ubuntu.com/community/communications/matrix/onboarding).

## Next Steps

Earlier this week, I met with [@sylvestre](https://github.com/sylvestre) to discuss my proposal to make uutils coreutils the default in Ubuntu 25.10. I was pleased to hear that he feels the project is ready for that level of exposure, so now we just need to work out the specifics. The Ubuntu Foundations team is already working up a plan for next cycle.

There will certainly be a few rough edges we'll need to work out. In my testing, for example, the only incompatibility I've come across is that the `update-initramfs` script for Ubuntu uses `cp -Z` to preserve `selinux` labels when copying files. The `cp`, `mv` and `ls` commands from uutils [don't yet support](https://github.com/uutils/coreutils/issues/2404) the `-Z` flag, but I think we've worked out a way to unblock that work going forward, both in the upstream and in the next release of Ubuntu.

I'm going to do some more digging on [`sudo-rs`](https://github.com/trifectatechfoundation/sudo-rs) over the coming weeks, with a view to assessing a similar transition.

## Summary

I'm really excited to see so much investment in the foundational utilities behind Linux. The uutils project seems to be picking up speed after their recent [appearance at FOSDEM 2025](https://fosdem.org/2025/schedule/event/fosdem-2025-6196-rewriting-the-future-of-the-linux-essential-packages-in-rust-/), with efforts ongoing to rework [procps](https://github.com/uutils/procps), [util-linux](https://github.com/uutils/util-linux) and more.

The `sudo-rs` project is now maintained by the [Trifecta Tech Foundation](https://trifectatech.org/), who are focused on "open infrastructure software in the public interest" . Their [`zlib-rs`](https://github.com/trifectatechfoundation/zlib-rs) recently released v0.4.2, which appears to now be [the fastest API-compatible zlib implementation](https://trifectatech.org/blog/zlib-rs-is-faster-than-c/). They're also behind the [Pendulum Project](https://github.com/pendulum-project) and [`ntpd-rs`](https://github.com/pendulum-project/ntpd-rs) for memory-safe time synchronisation.

With Ubuntu, we're in a position to drive awareness and adoption of these modern equivalents by making them either trivially available, or the default implementation for the world's most deployed Linux distribution.

We will need to do so carefully, and be willing to scale back on the ambition where appropriate to avoid diluting the promise of stability and reliability that the Ubuntu LTS releases have become known for, but I'm confident that we can make progress on these topics over the coming months.
