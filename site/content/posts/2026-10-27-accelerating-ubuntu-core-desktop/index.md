---
title: "Accelerating Ubuntu Core Desktop"
summary: |
  Canonical is resuming work on their modern, immutable,
  secure desktop: Ubuntu Core Desktop.
  
  Work based on a previous demo has already been rebased 
  on `core26`, with three clearly defined initial use cases
  over the coming months. The project aims to become the 
  default for a future release of Ubuntu.
tags:
  - Blog
  - Leadership
  - Ubuntu
  - Ubuntu Core
  - Canonical
  - Desktop
  - Linux
layout: post
cover: cover.webp
coverAlt: |
  A night time, time lapse scene of a busy, fast road.
---

Ubuntu Core Desktop is Canonical's (currently unreleased) immutable and attestable Linux desktop. It represents the most fundamental shift in Ubuntu's desktop architecture to date, and will mature into the default experience for Ubuntu Desktop over time.

Ubuntu Core is Canonical's "immutable Linux" distribution, and has been deployed in numerous commercial IoT, embedded and robotics platforms for almost ten years. Canonical [announced](https://www.youtube.com/watch?v=ahWrhnjjYDk) a developer preview of Core Desktop in 2023, but the project has since been dormant. I'm thrilled to announce that the development of Ubuntu Core Desktop has restarted with a dedicated, cross-functional team working toward three well-defined initial use cases.

I've [written previously](https://jnsgr.uk/2025/09/immutable-linux-paradox/) about "immutable" Linux distributions, what they're trying to achieve and where the promises are often broken. Ubuntu Core moves to *everything as a snap* - including the bootloader, the kernel, the desktop environment, userspace daemons and all of your apps. For users, this means a desktop that's harder to break, easier to recover and more adaptable to different devices and workflows. It also gives users greater control over the data their applications can access.

Our 2023 preview fell short of this vision. While it helped us better understand the problems we'd face, it bundled much of the desktop into a single alternative base snap. Separating those components is one of our top priorities as we restart the project.

With this transition comes the promise of greater resilience, better security, more composability, but also more engineering complexity. In this post I'll outline the vision, roadmap, and some of the complexities we hope to tackle.

## Three initial target use cases

People around the world use Ubuntu in many different ways, but over the coming cycle we're going to focus on three key use cases for Ubuntu Core Desktop. These are by no means exhaustive, but will stretch our implementation in different ways, helping us to validate assumptions and implementation work.

### The browser-centric machine

Many personal and professional workflows today are satisfied almost entirely by the presence of a modern, competent browser. The rapid rise of web applications (and toolkits like Electron) was the catalyst that enabled many Linux enthusiasts to use Linux full-time in their professional lives.

I expect this use case to be the easiest and quickest to deliver. Much of this work was already complete in the last developer preview back in 2023 through the inclusion of [Mozilla Firefox](https://snapcraft.io/firefox), and the availability of the [Chromium](http://snapcraft.io/chromium) snap.

Since then, work has been done on permissions prompting (more on that later…) to enable controlled access to the user's camera and microphone, and we've been shipping Firefox and Chromium as snaps by default in Ubuntu for a number of years - these snaps are feature-rich, stable and reliable.

### The developer workstation

This might seem like one of the more complex cases to solve, since Ubuntu Core eschews many of the filesystem and permission norms that developers have become accustomed to. However, LXD (our next-generation system container and virtual machine manager) works just fine on Ubuntu Core, and [Canonical Workshop](https://ubuntu.com/workshop) builds on that.

Canonical Workshop provides the means for tailored, sandboxed development environments. Combine Canonical Workshop with its companion [Visual Studio Code Extension](https://marketplace.visualstudio.com/items?itemName=Canonical.workshop) and most developers have all they need to work on projects in any language with any toolchain.

This is how I've personally driven my development workflows for some years. Over time I've used Docker containers, Multipass VMs, LXD containers and more recently Canonical Workshops to keep my development environments isolated from my machine and shareable with others. This way of working comes with very little overhead and promises less divergence between developer machines, less toil on your workstation and a safe place to experiment.

There are many parallels here with how developers are finding ways to sandbox the various coding agents they are using. As coding agents gain popularity and more capability, isolating them from your host system becomes increasingly important to protect your credentials, sensitive files and personal information. Canonical already [provides SDKs](https://github.com/canonical/reference-sdks) for many popular coding agents, and pushing developers toward development sandboxes with Workshops encourages them to detach their agents from their machines.

Today Canonical Workshop is distributed as a classic snap, but we have work underway and promising early results to move to strict confinement in the coming weeks, opening the door for this workflow. Visual Studio Code is also distributed as a classic snap - my hope is to make running it from within a workshop seamless, while we invest in a strictly confined option.

### The gaming machine

Gaming handheld machines like the [Steam Deck](https://store.steampowered.com/steamdeck) and the [Lenovo Legion Go](https://www.lenovo.com/gb/en/p/handheld/legion-go-series/legion-go/len106g0001) have become increasingly popular, while the monumental amount of work that [Valve](https://www.valvesoftware.com/en/) has put into [Proton](https://github.com/valvesoftware/proton) has transformed game compatibility on Linux.

At Canonical, we've been maintaining the [Steam snap](https://snapcraft.io/steam) for some time. Being [strictly confined](https://snapcraft.io/docs/explanation/security/snap-confinement/), it satisfies the confinement requirements for Ubuntu Core.

Game compatibility with Proton is dictated by a range of factors, and can sometimes mean users need to run different versions of Proton itself, experimental or tweaked versions of [Mesa](https://mesa3d.org/) and varying hardware device drivers depending on the game and hardware in question. On a traditional Linux system this can be fraught with danger - a wrong move here could render a device unbootable, or have negative consequences for other applications on the device.

I want Ubuntu Core Desktop's modular architecture to enable a more resilient and independently updatable gaming stack, including graphics components. Making that work reliably across games and hardware without destabilising the underlying system will be a complex task. The ability to compose snaps together, utilising ideas such as "[content](https://snapcraft.io/docs/reference/interfaces/content-interface/) snaps" and snap [components](https://snapcraft.io/docs/explanation/how-snaps-work/snap-components/), enable us to be more agile in the distribution and integration of drivers across varying hardware and architectures than in other image-based approaches.

The Steam snap and its surrounding infrastructure haven't had as much attention as I'd have liked over the past two years, mostly due to the same resource constraints that were preventing the Ubuntu Core Desktop project itself from progressing, but we're now in a position to address that.

Developing Ubuntu Core Desktop for gaming devices gives us a chance to consider the general UX of the machine. In the case of a dedicated gaming device, booting directly into a traditional desktop environment might not be the best choice. This is a compelling reason to explore different modes of operation beyond the traditional workstation experience.

## Key challenges

### Application availability

There will be many challenges along the way! Most of these stem from the fact that Ubuntu Core requires that all applications/services be packaged as strictly confined snaps. This immediately presents two challenges: making applications compatible with strict confinement, and ensuring sufficient availability of applications on the platform.

As I write this, there are over 11,000 snaps published in the [Snap Store](https://snapcraft.io), the majority of which are compatible with Ubuntu Core. Others, particularly those using `classic` confinement, will need additional work to integrate into Core Desktop.

I do intend to build an ergonomic experience for those who want to use [`classic` snaps](https://snapcraft.io/docs/explanation/security/classic-confinement/) on Ubuntu Core Desktop. Some popular applications, including [Visual Studio Code](https://snapcraft.io/code), are packaged as `classic` snaps and cannot run directly on Ubuntu Core. There are a few approaches we could take here, but my current preferred idea is to make it easy to run graphical applications inside a Workshop, while presenting their windows on the host desktop - similar to the approach taken with [WSLg](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps).

The same is true for users who wish to use applications from alternative package managers such as `apt`, `nix`, `flatpak` and others - the advice will be to lean into our native primitives for virtualisation and containerisation, and the integrations we'll build to make this ergonomic for desktop applications.

### Modularising the desktop

The biggest shortcoming of the 2023 developer preview was its architecture. The system used a modified [base snap](https://ubuntu.com/docs/snapcraft/latest/reference/bases/) - swapping `core22` for an alternative base snap that contained much of the desktop environment.

This alternate core snap was monolithic: it contained GDM, the GNOME desktop and even Firefox itself in early versions. This approach breaks many of the promises and goals of Ubuntu Core Desktop. It did enable the team to release what looked like a working PoC quickly, and this is what we've been working on for the past few weeks.

We want to build a modular desktop architecture that defines clear interfaces between components. Components such as the display manager, desktop environment, multimedia servers, networking and other core capabilities should adhere to well-defined interfaces and remain implementation agnostic.

The result will be a desktop whose constituent parts can evolve independently, without forcing the rebuild of the entire operating system image every time something changes - one of the key differentiators from other immutable operating system [implementations](https://jnsgr.uk/2025/09/immutable-linux-paradox/#approaches-to-immutability).

### Permissions prompting

Another key issue is troubleshooting and managing security confinement for apps that already are strictly confined. Application confinement is a moving target, and often packagers either aren't able, or shouldn't be able to make decisions on an end-user's behalf about what an application gets access to on their machine. 

This is why we built [permissions prompting](https://discourse.ubuntu.com/t/permissions-prompting-a-deep-dive/81785), one of the most technical and cross-team initiatives for Ubuntu in Canonical's recent past. Prompting differs from any previous effort (like [portals](https://flatpak.github.io/xdg-desktop-portal/docs/), for example) because it doesn't require applications to be modified to benefit from the framework. Permissions prompting orchestrates a complex conversation between the kernel, AppArmor and snapd, operating at the syscall level. As a result, the framework is generic and can be applied to many different application behaviours. At the time of writing, we've wired up a nice user experience for camera, microphone and home directory access, but the scope will be much broader.

I firmly believe that a resilient and understandable prompting system is the key to Ubuntu Core's success. Most users will be somewhat conditioned to this workflow from their Android or iOS phones.

Prompting enables packagers to express the intent of their applications, while giving users more control over what those applications can access on their machines. Not all users have the same threat model or circumstances, and we must be mindful of that.

## Partnering with enioka Haute Couture

During the initial work on our own Core Desktop, we worked with the [KDE Neon Core](https://community.kde.org/Neon/Core) team and [enioka Haute Couture](https://haute-couture.enioka.com/en/) to bring a variant of KDE Neon based on Ubuntu Core. To their credit, the team has been pushing us ever since we wrapped up the project to get started again, and I'm very pleased that we are once again partnering with them.

The KDE team has a long and well-earned track record for delivering [high-quality snaps](https://snapcraft.io/publisher/kde) for KDE applications, the Qt toolkit and more. Partnering with them will keep us honest on the modularity promises of Ubuntu Core Desktop, and I aim to have them as integrated with our team as we can mutually achieve.

Ubuntu Core Desktop should not be limited to the GNOME ecosystem - it should be a platform for desktop environments and experiences of all shapes and sizes. The [Ubuntu flavours](https://ubuntu.com/desktop/flavors) have a huge following because they offer users choice, and I don't want a move toward Ubuntu Core Desktop to limit that choice.

## Next steps

Our recently assembled team has been hard at work reviving the old preview. This involved getting pipelines re-established, rebuilding images and better understanding the current state. The team have also made a big dent in rebasing that original concept on `core26` and are collaborating with enioka Haute Couture to extend that progress to the KDE Neon Core builds.

Over the coming release cycle, our roadmap includes work to progressively break the desktop down into well-defined modules, define the (snap) interfaces needed to support all necessary desktop environment behaviours and usage, and use the three initial target use-cases to validate our new architecture.

Over the coming weeks, we'll have the infrastructure ready for continuous testing and daily image builds for Ubuntu Core Desktop.

## Summary

Ubuntu Desktop in its present form is not going away. However, this might be the most exciting thing I've been able to announce since taking the lead of Ubuntu. I've believed that Ubuntu Core is the future of Ubuntu for some time, but we've not been in a position to execute on the Desktop part of that. 

We have a long road ahead of us, and a lot of technical challenges to overcome, but the result will be a safer, more resilient, more trustworthy and future-proof Ubuntu that I think you'll have a blast using.

My long-term mission is to make Ubuntu Core the de facto target for Linux applications and workflows, and the default Ubuntu experience on the desktop, in the data centre and at the edge, and pushing the desktop agenda will further all of these use cases.

*We're also hiring. If you've got experience working on low-level systems programming problems, the Linux desktop,the boot process, on Linux security primitives, documentation or user experience and design, then take a look at our [careers page](https://canonical.com/careers), or reach out to me if you're not sure.*