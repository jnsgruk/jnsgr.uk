---
title: "The Immutable Linux Paradox"
summary: |
  Immutable Linux distributions are gaining popularity
  due to their resilience and security, with mainstream
  operating systems adopting similar principles.

  This post explores how different Linux distributions
  achieve immutability, the trade-offs, and why you should
  give it a try!
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
  - Immutable
  - Ubuntu Core
  - NixOS
  - bootc
  - ostree
layout: post
cover: cover.jpg
coverAlt: |
  An abstract illustration of an atom, with an
  orange-based colour palette.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/the-immutable-linux-paradox/66456), and is reposted here. I welcome comments and further discussion in that thread.

Immutable Linux distributions have been around since the early 2000s, but adoption has significantly accelerated in the last five years. Mainstream operating systems (OSes) such as [macOS](https://www.apple.com/macos), [Android](https://www.android.com/intl/en_uk/), [ChromeOS](https://chromeos.google/intl/en_uk/) and [iOS](https://www.apple.com/ios) have all embraced similar principles, reflecting a growing trend toward resilience, longevity, and maintainability as core ideals of OS development.

[Ubuntu Core](https://ubuntu.com/core) has been at the forefront of this movement for IoT, appliances and edge deployments, with work ongoing to release a "Core Desktop" experience. Other projects such as [NixOS](https://nixos.org/), [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) and [Red Hat image mode](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/introducing-image-mode-for-rhel_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems) are gaining adoption, alongside more specialised immutable distributions such as [SteamOS](https://store.steampowered.com/steamos) and [Talos](https://www.talos.dev/).

This post explores how different Linux distributions achieve immutability, the trade-offs, and why you should give it a try!

## What is an immutable Linux distribution?

The key principle of an immutable OS is that the core system is unchangeable at runtime.

Every OS installation has at least one filesystem that stores system software, user software, and user data. Immutable OSes must cleanly separate "system" and "user" software and data, such that regular user interactions cannot compromise the integrity of the OS.

Immutable deployments are often separated into three layers:

- **Base OS** - immutable core, updated only through controlled mechanisms
- **Applications** - user applications, often delivered in containerised formats such as [Snap](https://snapcraft.io/docs), [Flatpak](https://flatpak.org/), [AppImage](https://appimage.org/), [cpak](https://github.com/Containerpak/cpak)
- **User data** - writable and persistent, independent of OS updates or rollbacks

Immutable systems use atomic, transactional updates meaning updates are applied as unitary, indivisible operations that either wholly succeed, or fail completely and trigger an automated roll-back to a previous known-good state.

## Why immutability?

The major benefit of an immutable OS is *resilience*.

Immutable OSes make it easier to reproduce systems with a given configuration, which is particularly useful in scale-out use-cases such as cloud or IoT.

Traditional package managers often maintain a database of installed packages, consisting of those included in the base OS, and those explicitly installed by the user, and their dependencies. The package manager *doesn't* have a clear notion of which packages make up the "core system", and which are "optional".

This can cause "configuration drift", which occurs over time - a package could be explicitly installed by a user, used for a while and then removed, but without removing its dependencies. This leaves the system in a different, and somewhat undefined, state than it was in prior to the package being installed.

Often the traditional notion of OS security is improved with immutable OS concepts too. In most implementations, the core OS files are mounted read-only such that users *cannot* make changes - which also raises the bar for malicious modifications. When combined with technologies such as secure boot and confinement, immutable OSes can dramatically reduce the attack surface of a machine.

Finally, convenience! Immutable OSes often include recovery or rollback features, which enable users to "undo" a bad system change, reverting to a previous known-good revision.

## The immutability paradox

In reality, no general-purpose operating system is fully immutable.

There is always persistent, user-writable storage - because without this there would be a huge limitation on usefulness! Similarly, how can a system be truly immutable, yet still support software updates?

The terms "immutable" and "stateless" are often conflated - when in reality neither are excellent terms for describing what has become widely known as "immutable OSes". This was explored in some depth in [this blog post](https://blog.verbum.org/2020/08/22/immutable-%E2%86%92-reprovisionable-anti-hysteresis/) which proposes terms such as "image based" and "fully managed".

By definition, changes to configuration, the installation of applications and the use of temporary runtime storage are all violations of immutability, and thus immutability concepts must be applied in some sort of layering system.

Striking the balance between 'true' immutability and user experience is one of the hardest challenges in immutable OS design. A system that is too rigid can be difficult to manage and use, appearing inflexible to end users.

A common pattern is to run an immutable desktop OS and use virtualisation or containerisation technologies (e.g. [LXD](https://canonical.com/lxd), [Podman](https://podman.io/), [`toolbx`](https://containertoolbx.org/) [Distrobox](https://distrobox.it/)) to create mutable environments in which to work on projects. This results in a very stable workstation that benefits from immutability, with the flexibility of a traditional mutable OS where it's needed.

## Approaches to immutability

Different distributions solve the immutability challenge in different ways. In this section we'll explore the four different approaches of `ostree` based distributions, `bootc` based distributions, NixOS and Ubuntu Core.
### Fedora Silverblue / CoreOS / EndlessOS (`ostree`)

[Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/) and [Fedora CoreOS](https://fedoraproject.org/coreos/) are also popular choices for those exploring immutable OSes. The two share a lot of underlying technology with Silverblue targeting desktop use cases, and CoreOS targeting server deployments.

Both are based on [`ostree`](https://ostreedev.github.io/ostree/), which provides:

> tools that combine a 'git-like' model for committing and downloading bootable filesystem trees, along with a layer for deploying them and managing the bootloader configuration.

Silverblue and CoreOS actually rely on [`rpm-ostree`](https://coreos.github.io/rpm-ostree/) , a "hybrid image/package manager" which combines RPM packaging technology with `ostree` to manage deployments.

The update mechanism involves switching the filesystem to track a different remote "ref", which is analogous to a git [ref](https://git-scm.com/book/ms/v2/Git-Internals-Git-References).

[EndlessOS](https://www.endlessos.org/) is based on [Debian](https://www.debian.org/), but uses `ostree` to achieve immutability. EndlessOS is a desktop experience designed more for the "average user" and focuses on providing a reliable system that works well in low-bandwidth or offline situations.

Users often use Flatpak to install graphical user applications atop the immutable base, or a user-space package manager such as [brew](https://brew.sh/) for other utilities.

`ostree` based distributions also support "[package layering](https://docs.fedoraproject.org/en-US/fedora-silverblue/getting-started/#package-layering)" which enables adding packages to the base system without fetching a whole new filesystem ref, but does require the system to be rebooted before the package is persistently available. The documentation notes that this approach is to be used "sparingly", and that users should prefer using Flatpak or [`toolbx`](https://containertoolbx.org/) to access additional packages.

### RHEL "Image Mode" (`bootc`)

`bootc` based distributions use an alternate approach, packaging the base system into OCI containers (commonly referred to as Docker containers). Atomicity and transactionality are achieved by using container images to deliver the entire core system, and rebooting into a new revision.

[RHEL Image Mode](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/introducing-image-mode-for-rhel_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems) uses  [`bootc`](https://bootc-dev.github.io/bootc/intro.html). This technology capitalises on the success of OCI containers as a transport and delivery mechanism for software by packing an entire OS base image into a single container, including the kernel image.

The `bootc` project builds on [`ostree`](https://ostreedev.github.io/ostree/) , but where `ostree` never delivered an opinionated "install mechanism", `bootc` does. The contents of a `bootc` image is an `ostree` filesystem.

Installing new system packages generally means building a new base image, downloading that image and rebooting into it with a command such as `bootc switch <image reference>`.

Users often use Flatpak to install graphical user applications atop the immutable base, or a user-space package manager such as [brew](https://brew.sh/) for other utilities.

### NixOS

The Nix project first appeared in 2003. [NixOS](https://nixos.org/) is built on top of the Nix package manager, using it to manage both packages *and* system configuration.

NixOS defines the entire system through a declarative configuration, with changes applied via “generations” that can be rolled back. Changes to the system are applied by "rebuilding" the system configuration, which produces a new "generation".

Nix packages, and therefore NixOS, eschews the traditional [Unix FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) in favour of the Nix "store" and a collection of symlinks and wrappers managed by Nix. Only the Nix package manager can write to the store.

The Nix store also (mostly) enables the building and switching of generations without a reboot. Updates are atomic: new generations must build completely before they can be activated. The [`home-manager`](https://github.com/nix-community/home-manager) project extends these concepts to the user environment and dotfile management.

The [`impermanace`](https://github.com/nix-community/impermanence) project requires that every persistent directory is explicitly labelled, or else it's deleted on every reboot, forcing the base OS to be rebuilt from the Nix store and system configuration - essentially "enforcing" core system immutability between reboots. This was inspired by blog posts "[Erase Your Darlings](https://grahamc.com/blog/erase-your-darlings/)" and "[NixOS tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)", which are worth a read, too!

### Ubuntu Core

Ubuntu Core achieves immutability by packaging every component (kernel, base system, applications) as Snaps.

Snap [confinement](https://snapcraft.io/docs/snap-confinement) enforces isolation, and `snapd` manages transactional updates and rollbacks. The system is designed for reliability, fleet management, and modular upgrades, making it well-suited for IoT and soon, desktop use.

The key [components](https://documentation.ubuntu.com/core/explanation/core-elements/inside-ubuntu-core/) of an Ubuntu Core deployment are:

- **Gadget snap**: provides boot assets, including board specific binaries and data (bootloader, device tree, etc.)
- **Kernel snap**: kernel image and associated modules, along with initial ramdisk for system initialisation
- **Base snap**: execution environment in which applications run - includes "base" Ubuntu LTS packages
- **System snaps**: packages critical to system function such as [Network-Manager](https://documentation.ubuntu.com/core/explanation/system-snaps/network-manager/), [bluez](https://documentation.ubuntu.com/core/explanation/system-snaps/bluetooth/), pulseaudio, etc.
- **Application snaps**: define the functionality of the system, [confined to a sandbox](https://snapcraft.io/docs/snap-confinement)
- **Snapd**: manages updates, rollbacks and snapshotting/restoring of user data

In a Core Desktop installation, the desktop environment (GNOME, Plasma, etc.), display manager, login manager would all be delivered as "system snaps".

Snap [confinement](https://snapcraft.io/docs/snap-confinement) ensures packages cannot incorrectly interact with the underlying system or user data without explicit approval. In an Ubuntu Core deployment, this notion is extended to every component of the OS, offering a straightforward yet powerful way to manage risk for each system component.

## Summary

Immutable Linux distributions approach the immutability paradox differently. We explored four different approaches here, and you can learn more about other approaches taken by the likes of [SUSE MicroOS](https://microos.opensuse.org/) (filesystem based immutability) and [Vanilla OS](https://vanillaos.org/) (uses [ABRoot](https://github.com/Vanilla-OS/ABRoot)) in this [excellent blog post](https://dataswamp.org/~solene/2023-07-12-intro-to-immutable-os.html).

Ubuntu Core focuses on transactional packaging and a clean separation of system & user data. `bootc`-based systems take a full image-based approach, while NixOS offers extreme flexibility through declarative configuration, but at the cost of complexity.

If you've yet to try an immutable Linux distribution I'd recommend giving it a go. Whether you prioritise simplicity, security or declarative control there's almost certainly an immutable Linux distribution that fits your needs.
