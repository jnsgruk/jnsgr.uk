---
title: "Introducing Debcrafters"
summary: |
  Introducing Canonical's new Debcrafters team, dedicated to maintaining
  the health of the Ubuntu Archive, but also to fostering collaboration
  among Linux distributions, including paid time to contribute elsewhere
  in the open source ecosystem.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Debcrafters
  - Productivity
  - Open Source
layout: post
cover: cover.jpg
coverAlt: |
  A hand finding the "missing piece" in a puzzle.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/63674), and is reposted here. I welcome comments and further discussion in that thread.

Earlier this year, Canonical's Ubuntu Engineering organisation gained a new team, seeded with some of our most prolific contributors to Ubuntu. Debcrafters is a new team dedicated to the maintenance of the Ubuntu Archive.

The team's primary goal is to maintain the health of the Ubuntu Archive, but its unique construction aims to attract a broad range of Linux distribution expertise; contributors to distributions like Debian, Arch Linux, NixOS and others are encouraged to join the team, and will even get paid to contribute one day per week to those projects to foster learning and idea sharing

### Bootstrapping the team

The Debcrafters team is a global team. We have a squad in the Americas, a squad in EMEA and will have a squad in APAC. At present, we've staffed the AMER and EMEA teams with existing Canonical employees from our Foundations, Desktop, Server and Public Cloud teams. Each team currently has a manager, and four engineers.

The team comprises Debian Developers, Stable Release Updates (SRU) team members and archive administrators, and began working together for the first time at our recent Engineering Sprint in Frankfurt held in early May 2025.

### Mission

The Debcrafters' primary mission is to maintain the health of the Ubuntu Archive.

This team will take the lead on syncing & merging packages from Debian, reviewing proposed migration issues, upstreaming Ubuntu deltas, and take ownership of major transitions such as upgrades to `glibc` and past examples such as the `t64` and `python3` transitions.

They'll manage the scheduling, triggering and reporting on archive test rebuilds which we conduct when making major changes to critical packages. We did this when we enabled frame pointers by default, and when we switched `coreutils` to the `uutils` implementation in Ubuntu 25.10.

They'll be responsible for the evolution and maintenance of the `autopkgtest` infrastructure for Ubuntu, as well as taking an instrumental role in introducing more distro-scale integration tests.

They'll work on improving the reporting and dashboarding of the Ubuntu Archive, its contributors and status, as well as taking a broader interest in shaping the tools we use to build and shape Ubuntu.

What sets this team apart from the likes of Desktop, Server and Foundations is the range of packages they will work on. Members of the Debcrafters team will move thousands of packages every cycle - many of which they will not be intimately familiar with, but will use their growing distro maintenance and packaging skills to perform maintenance where there is no other clear or present owner.

### Tools & processes

One of the key goals in my first [post](https://jnsgr.uk/2025/02/engineering-ubuntu-for-the-next-20-years/) was to modernise the contribution experience for Ubuntu Developers by focusing on tools and processes.

The Debian project recently adopted [tag2upload](https://wiki.debian.org/tag2upload), which allows Debian Developers to use [git-debpush](https://packages.debian.org/search?keywords=git-debpush) to push a signed `git` tag when uploading packages. While we’re not following that exact path, we share many of the same goals and intentions.

For some time Ubuntu Developers have been able to use [`git-ubuntu`](https://canonical-git-ubuntu.readthedocs-hosted.com/en/latest/) as part of their development workflow, which aims to provide "unified git-based workflows for the development of Ubuntu source packages". This project brought us closer to our desired experience, but still needs work to achieve our complete vision. I'd like to put more emphasis on the experience we provide for *testing* packages, as well as signing, uploading and releasing packages.

In the coming weeks our Starcraft team (responsible for [Snapcraft](https://github.com/canonical/snapcraft), [Rockcraft](https://github.com/canonical/rockcraft), [Charmcraft](https://github.com/canonical/charmcraft)) will begin prototyping `debcraft`, which will (in time) become the de facto method for creating, testing and uploading packages to the Ubuntu archive.

The first prototype of `debcraft` will focus on unifying the current workflow adopted by most Ubuntu Developers at Canonical. It will wrap existing tools (such as `git-ubuntu`, `lintian`, `autopkgtest`) to provide familiar, streamlined commands such as `debcraft pack`, `debcraft lint` and `debcraft test`. Uploading packages, and a more native "craft" experience for constructing packages will come later.

Details will make their way into the new [Ubuntu Project Docs](https://canonical-ubuntu-project.readthedocs-hosted.com/) throughout the course of the 25.10 Questing Quokka cycle, including the newly renovated "Ubuntu Packaging Guide", which will aim to provide a "one ring to rule them all" approach to documenting how to package software for Ubuntu.

### Attracting contributors

While the team has been seeded with seasoned Ubuntu contributors, one of the primary goals of the team is to grow the contributor base across generations.

One of the sub-teams is currently leading the roll out of a new contributor journey that will soon be publicly available. This process lays out the journey from complete beginner to "Core Dev", stopping off at "Package Maintainer", "Package Set Maintainer", "[MOTU](https://canonical-ubuntu-project.readthedocs-hosted.com/reference/glossary/#term-MOTU)", etc. along the way. The process also aims to help candidates prepare for Developer Membership Board interviews.

Whether you're a junior engineer just graduating from University, or you're a seasoned Linux contributor elsewhere in the Linux ecosystem, the Debcrafters team is an excellent place to learn software packaging skills and contribute to the world's most deployed Linux distribution.

### Contribution beyond Ubuntu

The Debcrafters' primary commitment is to Ubuntu, but we recognise the enormous value in collaborating with other distributions. Many of the hard lessons I've personally learned resulted from contributing to NixOS and building Snaps. Packaging is a complex and ever-changing discipline, and other distributions are facing many of the complex problems we are - often with different or novel approaches to solving them.

In recognition of this, we're actively seeking maintainers from other distributions - be that Debian, Arch, NixOS, Guix, Fedora, Universal Blue or any other - packaging and distribution engineering skills are often common across distributions, and we believe that Ubuntu can benefit from broader perspectives, while contributing back to the wider ecosystem of distributions in the process.

The Debcrafters must spend the majority of their work time on Ubuntu, but they will be encouraged to spend a day per week contributing to other distributions to gain understanding, and bring fresh perspectives to Ubuntu (and the reverse, hopefully!). This will be structured as a *literal* day per week, agreed with the team management - for example "I work on NixOS on Tuesdays".

### Summary

Canonical has launched a new team, the Debcrafters, who are dedicated to maintaining the very core of Ubuntu: the archive. This team has a global footprint, and deep expertise in software packaging drawn from across the Linux ecosystem. They'll lead transitions, improve tooling improvements and strengthen our distribution testing infrastructure.

Whether you're an experienced Debian Developer, a maintainer from another Linux distribution or a new engineer starting your career in open source, Debcrafters offers a unique opportunity to learn, grow, and contribute to the world’s most widely deployed Linux distribution.
