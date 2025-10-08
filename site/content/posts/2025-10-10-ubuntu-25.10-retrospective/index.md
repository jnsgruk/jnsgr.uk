---
title: "Ubuntu Engineering in 2025: A Retrospective"
summary: |
  In February this year, I posted a manifesto to
  to modernise the design, build and release of Ubuntu.

  This week, we released Ubuntu 25.10 Questing Quokka, which
  was the first full engineering cycle under this new manifesto,
  This post is a look back at the progress made since that
  original post.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
layout: post
cover: cover.png
coverAlt: |
  The "Resolute Raccoon" in a space scene.
---

> This article was originally posted [on the Ubuntu Discourse](), and is reposted here. I welcome comments and further discussion in that thread.

## Ubuntu 25.10: A Retrospective

In February this year, I published [Engineering Ubuntu For The Next 20 Years](https://discourse.ubuntu.com/t/engineering-ubuntu-for-the-next-20-years/55000), which was something of a manifesto I pledged to enact in the design, build and release of Ubuntu. This week, we released Ubuntu 25.10 Questing Quokka, which was the first full engineering cycle under this new manifesto, and it seems like a good time to reflect on what we achieved in each category, as well as highlight some of the more impactful changes that have just landed in Ubuntu.

In that first article, I outline four themes for Ubuntu Engineering at Canonical to focus on: Communication, Automation, Process and Modernisation.

### Communication

A notable improvement throughout this engineering cycle has been the frequency with which the teams at Canonical have written about their work, often in some detail. Many of these posts can be found under the [blog tag](https://discourse.ubuntu.com/tag/blog), which had never been used until around six months ago, and now sees a couple of new posts per week outlining the work people are doing toward these themes.

I stated that I consider documentation a key part of our communication strategy, and this last six months has seen some of the most substantial changes to Ubuntu documentation in many years. The [Ubuntu Project Docs](https://documentation.ubuntu.com/project/) was a project started in May 2025, and is quickly becoming the single documentation hub that a current or potential Ubuntu contributor needs to understand how, why and when to do their job. Similarly, the [Ubuntu for Developers](https://documentation.ubuntu.com/ubuntu-for-developers/) was created to illuminate a path for developers across numerous languages on Ubuntu.

It's important for us to celebrate such efforts, but also to remember that this is only the start! In order for these efforts to remain useful, both our internal teams and our community must continue to engage with these efforts - adding, refining and pruning content as necessary. As the sun-setting of wiki.ubuntu.com approaches, it's imperative that these new documentation sites continue to get the attention they need.

Lots of the changes we've made in the last cycle have attracted attention from online blogs, news outlets, youtubers, etc. Part of the challenge with such changes is "owning the narrative" and ensuring that legitimate concerns are heard (and taken into account), but also that there are appropriate responses to uncertainty, without getting drawn into unproductive discussions.

Finally, the transition to [Matrix](https://ubuntu.com/community/docs/communications/matrix) as the default synchronous communication means for the project has, in my opinion, made it easier than ever to get in touch with our community of experts - whether it be for support, or to start a journey for contribution to Ubuntu.

### Automation

The largest item we took on here was in pursuit of the [monthly snapshot releases](https://discourse.ubuntu.com/t/61876). This went much better than I expected, and to some extent covers off the "Process" theme as well as "Automation", but through a combination of studying our process and whittling it down as lean as we could, and beginning to automate more of the process, the team were able to release four snapshot releases before the 25.10 Beta.

The scale of the automation efforts was relatively limited this cycle, but the automation of release testing has really accelerated in the past few months. The vast majority of the [test cases](https://github.com/canonical/ubuntu-gui-testing/tree/main/tests) that qualify an Ubuntu Desktop ISO for release are now fully automated, and the [same framework](https://github.com/canonical/yarf) that makes this possible was also used to develop a suite of tests for [TPM FDE](https://discourse.ubuntu.com/t/tpm-fde-progress-for-ubuntu-25-10/65146).

Work was also done on our [craft tools](https://discourse.ubuntu.com/t/crafting-your-software/64809) to better the experience with the `test` sub-command of build tools like `snapcraft`, `rockcraft` and `charmcraft` - all of which will have a trickle-down effect on the upcoming `debcraft`, and make it trivial to include many new kinds of tests in our packaging workflows.

Behind the scenes, every team in Ubuntu Engineering at Canonical has been writing charms that make the underlying infrastructure behind Ubuntu more portable, resilient and scalable. This includes services like [Ubuntu Manpages](https://manpages.ubuntu.com/), [autopkgtest](https://autopkgtest.ubuntu.com/), [error-tracker](https://errors.ubuntu.com/), and a staging deployment of [Temporal](https://temporal.io) to enable the next phase of our release automation.

### Process

This item was probably where the least concrete progress was made, though I probably could have predicted that. Many of the processes in the Ubuntu project serve to ensure that we ship resilient software, and don't break users - so changing them in a hurry is not generally a good idea.

That said, there was some good progress on the [Main Inclusion Review](https://documentation.ubuntu.com/project/MIR/main-inclusion-review/#mir-process-overview) (MIR) process, whose team documentation was moved into the [Ubuntu Project Docs](https://documentation.ubuntu.com/project) after a thorough review, and the [Stable Release Updates](https://documentation.ubuntu.com/project/how-ubuntu-is-made/processes/stable-release-updates/) (SRU) team are in the process of the same transition. Moving and re-reviewing the documentation is essentially the first step of the process improvement I was seeking: understanding where we are!

Internally, we've been piloting a new process for onboarding [Ubuntu Developers](https://documentation.ubuntu.com/project/who-makes-ubuntu/developers/dmb-index/#the-uploader-s-journey) that sees engineers start by working toward gaining upload rights for a single package, but has a complete curriculum that can take them through to Core Developer status. Details of this should be released in the coming months, outlining a clear and well-trodden journey for new contributors. Much of this material already existed, but the team have worked on polishing it, and making it clearer how the process work from end to end.

The next step for each of these processes is measurement. We've begun instrumenting these processes to understand where the most time is spent so we can use that information to guide improvements and streamline processes in future cycles, and even set [Service Level Objectives](https://en.wikipedia.org/wiki/Service-level_objective) (SLOs) against those timelines.

### Modernisation

Much of what I’ve already described could be considered modernisation, but from a technical standpoint the most obvious candidate here was the "[Oxidising Ubuntu](https://discourse.ubuntu.com/t/carefully-but-purposefully-oxidising-ubuntu/56995)" effort, which has seen us replace numerous core utilities in Ubuntu 25.10 with modern Rust rewrites.

We began this effort in close collaboration with the [uutils](https://uutils.github.io/) project and the [Trifecta Tech Foundation](https://trifectatech.org/). The former is the maintainer of a Rust `coreutils` rewrite, and the latter the maintainer of `sudo-rs`, which we [made the default](https://discourse.ubuntu.com/t/adopting-sudo-rs-by-default-in-ubuntu-25-10/60583) in 25.10. The technical impact of these changes in defaults will only truly be known once Ubuntu 25.10 is "out there", but I'm pleased with how we approached the shift. In both cases, we contacted the upstreams in good time to ascertain their view on their projects' readiness, then agreed funding to ensure they had the financial support they needed to land changes in support of Ubuntu, and then worked closely with them throughout the cycle to solve various performance and implementation issues we discovered along the way.

As it stands today, `sudo-rs` is the default `sudo` implementation on Ubuntu 25.10, and uutils' `coreutils` has *mostly* replaced the GNU implementation, with a [few exceptions](https://git.launchpad.net/ubuntu/+source/coreutils-from/tree/debian/coreutils-from-uutils.links), many of which will be resolved by releases in the coming weeks. These diversions back to the existing implementations demonstrate that stability and resilience are more important than "hype" in our approach: I expect us to have completed the migration during the next cycle, but not before the tools are ready.

Following the ["Switch to Dracut" specification](https://discourse.ubuntu.com/t/spec-switch-to-dracut/54776),  Ubuntu Desktop 25.10 will use [Dracut](https://dracut-ng.github.io/dracut-ng/) as its default initrd infrastructure (replacing initramfs-tools). Dracut will use systemd in the initrd and supports new features like Bluetooth and NVMe over Fabric (NVM-oF) support. Ubuntu Server installations will continue using `initramfs-tools` until [remaining hooks are ported](https://bugs.launchpad.net/ubuntu/+source/dracut/+bug/2125790).

For each of these changes (`coreutils`, `sudo-rs` and `dracut`) the previous implementations will remain supported for now, with well-documented instructions on the reversion of each change for those who run into unavoidable issues - though we expect this to be a very small number of cases.

## What's Next?

Well... more of the same! We intend to carry on with the increased cadence of written updates, so keep an eye out for those.

We have some exciting announcements to make over the coming weeks, including support for more modern micro-architectural variants (like `amd64v3`), better system-wide handling of revoked TLS certificates, updates on our Debcraft package for a more modern packaging experience and an effort to update many of our tools from "behind the scenes" using a combination of Rust and Go.

My final words are to thank all of those who have driven these efforts. I'll omit the long list of names, but there have been countless examples of people stepping up substantially to deliver these efforts - without whom we'd have made a lot less progress.

Well done, and let's make Resolute Raccoon an LTS to remember - for all the *right* reasons!
