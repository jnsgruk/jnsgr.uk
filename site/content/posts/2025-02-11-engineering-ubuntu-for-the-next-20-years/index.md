---
title: "Engineering Ubuntu For The Next 20 Years"
summary: |
  In the last week of January 2025, I was appointed VP Engineering for Ubuntu at Canonical, meaning
  I'll oversee the Ubuntu Foundations, Server and Desktop teams going forward. This post outlines
  my vision for that role, and how I hope to evolve the distribution, the engineering practices
  behind it, and the community over the coming years.
tags:
  - Development
  - Ubuntu
  - Canonical
  - Community
  - Vision
  - Blog
layout: post
cover: cover.png
coverAlt: |
  The Ubuntu 24.10 (Oracular Oriole) wallpaper.
---

{{< alert "circle-info" >}}
This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/engineering-ubuntu-for-the-next-20-years/55000), and is reposted here. I welcome comments and further discussion in that thread.
{{< /alert >}}

## Introduction

I've been a VP Engineering at Canonical for 3 years now, building [Juju](https://juju.is) and our catalog of [charms](https://charmhub.io/). In the last week of January, I was appointed the VP Engineering for Ubuntu at Canonical, where I will now oversee the Ubuntu Foundations, Server and Desktop teams.

Over the past 20 years, Ubuntu has become synonymous with "Linux" to many people. I fondly remember receiving my first Ubuntu CD in the post, shortly after my own Linux journey began in 2003 with booting Knoppix on a school computer. Throughout my career, Linux and open source have been prominent features that I'm very proud of. In the past few years I've made contributions to Ubuntu, Arch Linux, and more recently NixOS.

Ubuntu's recent 20 year milestone is a timely reminder to pause and reflect on what made Ubuntu so exciting, so successful and so captivating to the Linux community. In 2004, the idea of releasing an operating system every six months was laughed off by many, but has now become the norm. Ubuntu builds upon Debian, aiming to bring the latest and very best open source had to offer to the masses. In the past 10 years, we've seen huge shifts in the way software is delivered \- the success of large-scale cloud based operations necessitated a shift towards more automated testing, releasing and monitoring, and as the open source community around these projects grew, we had to evolve our ways of thinking, designing and communicating about software.

## **Four Key Themes**

As I step into this new role, I've reflected on how we can steer the engineering efforts behind Ubuntu. I've anchored this vision around four themes: Communication, Automation, Process and Modernisation.

### **Communication**

Communication is a central component of a distributed workforce \- whether that workforce is employed by Canonical, members of our community or contributors from our partners. Ubuntu has relied for many years on mailing lists and IRC. These platforms enabled global teams to collaborate for years, and have been invaluable to the community. In 2025 we're fortunate to have a wealth of communications platforms at our disposal, but we must use these tools strategically to avoid fragmentation.

On Jan 29 2025, the Ubuntu developer mailing list [announced](https://lists.ubuntu.com/archives/ubuntu-devel-announce/2025-January/001365.html) that the primary means of communication for Ubuntu developers will be the Ubuntu Community Matrix server. Matrix provides a rich, modern communications medium that is familiar to the next generation of engineers and tinkerers, who will be central to the continued progression of Ubuntu and open source. We're in good company on Matrix, with many other Linux distributions and projects maintaining a presence on the platform. The recent [migration](https://fridge.ubuntu.com/2024/12/08/ubuntu-forums-migration/) of Ubuntu Forums to the Ubuntu Discourse, further consolidates the range of platforms we use to connect with one another.

To effect much of the change I'm describing in this post, we will need community support. I'll be encouraging the leads of our internal teams in Ubuntu Foundations, Server and Desktop to be more forthcoming and regular with public updates that will serve two purposes: to share our intentions, progress and dreams for Ubuntu, but also to collaborate on refining our vision, ensuring we deliver a platform that is not just exciting, but _relevant_ for many years to come.

Documentation is a critical form of communication. Our documentation enables our current users, but also illuminates the path for new contributors. Such documentation does exist, but much of it is fragmented across different platforms, duplicated and/or contradictory or simply difficult to find. As a company, and as a community, we must focus on ensuring both existing and potential contributors have access to the information they need on conventions, tools and processes. A good example of where this has already happened is the [SRU documentation](https://documentation.ubuntu.com/sru) which was recently rebuilt in line with our documentation [practices](https://canonical.com/documentation).

### **Automation**

Delivering a Linux distribution is a monumental task. With tens of thousands of packages across multiple architectures, the workload can be overwhelming \- leaving little room for innovation until the foundational work is done. We're fortunate to benefit from the diligent work done by the Debian community, yet there is a huge amount of work that goes into each Ubuntu release. One of our primary tasks as a distribution is package maintenance. While some may see this as menial or repetitive, it remains critical to the future of Ubuntu, and is a valuable specialist skill in its own right.

Software packaging is a complex and constantly evolving topic. Ubuntu relies heavily on a blend of Debian packages, and our own Snap packaging format. Debian packaging was revolutionary \- responsible for huge advancements in the way we thought about delivering software, but as things have moved on some of those tools and practices are beginning to show their age.

I'd like to focus on enriching our build process with modern ideals and processes for automating the version bumps, testing, performance benchmarking and releasing of packages in the archive. High complexity tasks are error-prone and, without sufficient automation, risk becoming overly dependent on a few skilled individuals. We have the same challenge with Snaps, but they benefit from significantly more modern tooling as a consequence of the observations made about Debian packaging over many years.

The goal of this theme is not just to automate as much as possible (thereby increasing our collective capacity), but also to simplify processes where we can. Much of Ubuntu's build process \*is\* automated, but those systems are disparate and often opaque to all but our most experienced contributors.

I've been inspired by how the NixOS community manages packaging. Every single package for the distro is represented as text files, in a [single Git repository](https://github.com/NixOS/nixpkgs), with a universally observable continuous integration and integration testing pipeline ([Hydra](https://wiki.nixos.org/wiki/Hydra)) that performs version bumps and simple maintenance tasks semi-autonomously. While this model carries its own challenges, there is something alluring about the transparency and accessibility of the systems that assemble, test and deliver software to their users.

[Universal Blue](https://universal-blue.org/), and by extension [Project Bluefin](https://projectbluefin.io/), are recent additions to the Linux ecosystem that benefited from thinking hard about the tooling they use to build their distribution. They've centered their process around tools with which their cloud-native audience are already familiar.

My suggestion is not to imitate these projects, rather that the open source community is at its strongest when we collaborate and learn from one another. I think we can take inspiration from those surrounding us, and use that to inform our plans for Ubuntu's future.

### **Process**

Process is closely tied to automation, but is frequently viewed negatively in software engineering, carrying connotations of bureaucracy and slowdowns. In my experience, a well-designed process empowers people to enact changes with confidence.

Ubuntu is built by all of us, in many countries and across all timezones. Concise, well-defined, lightweight processes promote autonomy and reduce uncertainty \- enabling people to unblock themselves. Ubuntu is no stranger to process: the [Main Inclusion Review (MIR)](https://canonical-ubuntu-packaging-guide.readthedocs-hosted.com/en/latest/explanation/main-inclusion-review/), the aforementioned [Stable Release Updates (SRU)](https://canonical-sru-docs.readthedocs-hosted.com/en/latest/) process, the [process](https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455) for Snap store requests and many more have contributed to the success of Ubuntu, setting clear guardrails for contributors and ensuring we work to common standards.

My goal over the coming months is to work with you, the people behind Ubuntu, to identify which of these processes still serve us, and which need revising to simplify our work while maintaining our dedication to stability. I'll consolidate the definitions of these processes, make them searchable, peer-reviewable, and more discoverable. Examples of where this has worked well are the [Go proposal](https://github.com/golang/proposal) process, and the [Ethereum Improvement Proposal](https://eips.ethereum.org/) process \- both of which make it trivial to create, track and discuss proposals across the breadth of their respective projects.

If you submit an MIR, or work on an SRU, it should be trivial to understand the status of that request, and to communicate with the team executing that process where needed. If you're interested in joining our community, it should be simple to get a sense of what is changing across the project, and where you might be able to help.

I'd like to tackle these problems and make these processes as transparent as possible.

### **Modernisation**

The world of computing has evolved dramatically in the last 20 years, and I’m proud that Ubuntu has continually adapted and thrived. In Linux alone there have been huge changes to what is considered "normal" for a Linux machine. Whether it be the introduction of \`systemd\`, the advent of languages with a focus on memory safety, the huge growth in virtualisation and containerisation technology, or even the introduction of Rust into the Linux kernel itself \- the foundations of our distribution must be constantly assessed against the needs of our users.

I was proud to see the [announcement](https://discourse.ubuntu.com/t/kernel-version-selection-for-ubuntu-releases/47007?u=d0od) last year that the Ubuntu Kernel team committed to shipping the very latest kernels in new versions of Ubuntu, wherever they possibly can. Even if that means shipping a kernel that's in the release candidate phase, the team will stand by that kernel and continue to support it through the Ubuntu release's life. While this could appear cavalier at a glance, what it represents is a willingness to rise to the challenge of shipping the very best of open source to our users. I'd like to see more of this. Ubuntu is a flagship Linux distribution and a starting point for many; we must ensure that our users are presented with the very best our community has to offer \- even if that means a bit more hustle in the early days of a given release. This is of particular importance for our Long Term Support releases, which are relied upon by governments, financial institutions, educational establishments, nonprofits and many others for years after the initial release date.

We should look deeply at the tools we ship with Ubuntu by default \- selecting for tools that have resilience, performance and maintainability at their core. There are countless examples in the open source community of tools being re-engineered, and re-imagined using tools and practices that have only relatively recently become available. Some of my personal favourites include command-line utilities such as [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat), and [helix](https://helix-editor.com/), the new [ghostty](https://ghostty.org/) terminal emulator, and more foundational projects such as the [uutils](https://uutils.github.io/) rewrite of [coreutils in Rust](https://github.com/uutils/coreutils). Each of these projects are at varying levels of maturity, but have demonstrated a vision for a more modern Unix-like experience that emphasises resilience, performance and usability.

Another example of this is our work on [TPM-backed full disk encryption](https://ubuntu.com/blog/tpm-backed-full-disk-encryption-is-coming-to-ubuntu), a project which promises encryption of our users' data with no degradation to their user experience. This feature relies upon cryptographic hardware and techniques that have only recently become available to us, but enable us to deliver the potent combination of security _and_ usability to our users.

## **Delivering Features**

What I've shared so far is a high-level overview, and many of the points under the four themes will take time to implement, with most appearing as a series of gradual improvements. You might be wondering whether we'll focus on the latest trends and features, or prioritise that bug you reported.

While focusing on the latest trends or a single breakthrough feature can yield short-term progress, embracing these principles will create the space for sustained, impactful innovation.

That said, I’ve also been working on a list of incremental features and improvements that we can deliver in the coming months to enhance the Ubuntu experience. You’ll hear more from me and the team leads regularly as we share updates and progress.

## **Summary**

I’m incredibly excited to embark on this journey, and consider it a privilege to serve in this role. Together with the Ubuntu community, Canonical engineers, and our partners, we will build an open-source platform that enables the next 20 years of innovation in computing.

If you have ideas for the future of Ubuntu, or something in this post has resonated with you and you want to be involved either as a community member, or perhaps a future employee of Canonical, I'd love to hear from you.
