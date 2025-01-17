---
title: Secure Boot & TPM-backed Full Disk Encryption on NixOS
summary: |
  An explanation of how to enable secure boot on NixOS, using a
  community project named 'Lanzaboote', and further how to
  automatically unlock a LUKS-encrypted disk using a TPM with
  systemd-cryptenroll.
tags:
  - NixOS
  - Secure Boot
  - Lanzaboote
  - SystemD
  - TPM
  - Security
  - Linux
  - Blog
layout: post
---

> **Update**: Since I wrote this post, I have been made aware of a particular situation where, at the time I write this (2025-01-17), the steps described in this article will result in a setup that is still (in many cases) vulnerable to an attack where the attacker has physical access to the machine. This may be acceptable in your threat model, but I'd encourage you to read the [excellent article](https://oddlama.org/blog/bypassing-disk-encryption-with-tpm2-unlock/) to gain a full understanding of the issue.

## Introduction

For the last decade (whoa...) or so, I've defaulted to using LUKS-encrypted drives for my machines. In general, I configure an unencrypted boot/EFI partition, then place either an ext4 or btrfs filesystem inside a LUKS container which is used for the root partition.

Some of my machines also have extra disks: my desktop has a 1TB NVMe drive for root, and a 2TB NVMe "data" drive mounted in my home directory under `/home/jon/data`. I don't like having to type two different encryption passphrases at boot, so I usually have the extra disk automatically unlocked by putting the key in a file on the root drive, and placing an entry in [`/etc/crypttab`](https://www.man7.org/linux/man-pages/man5/crypttab.5.html).

This setup works fine for desktop machines, but it's cumbersome on headless machines because unattended reboots require the disk passphrase to be entered at boot. Even then, all of my computers are exclusively used by me, and this setup means I have to enter two passwords on every boot to get to a working desktop environment (one for the disk, and one for the login manager).

I solved this recently with a combination of Secure Boot and a Trusted Platform Module (TPM), so let's look at those first with a brief and high-level overview of each.

## What's a TPM?

Most machines that have been manufactured in the last decade, and certainly in the last 5 years, contain a cryptographic coprocessor conforming to the Trusted Platform Module (TPM) [spec](https://trustedcomputinggroup.org/resource/tpm-library-specification/). The TPM is a dedicated microcontroller primarily used for verifying the integrity of a machine.

TPMs can be used for storing cryptographic key material and performing basic cryptographic operations. The general premise is that keys can be loaded into the TPM, which enables the TPM to perform cryptographic operations using that key (signing, encrypting, etc.), but the key cannot be recovered or read from the TPM unless certain conditions are met. TPMs also provide other facilities such as secure random number generation, which in turn enables them to securely generate cryptographic keys.

Verifying system integrity essentially boils down to being able to ensure the machine hasn't been tampered with between boots, and that the boot process itself hasn't been compromised. A given firmware or operating system can take hardware "measurements" and store those measurements in dedicated slots called Platform Configuration Registers (PCRs). The measurements pertain to the underlying hardware and configuration of the machine. The TPM itself never performs the actual verification of the PCRs, and in fact has no knowledge of whether a measurement is inherently "good" or "bad", but it can provide signed attestations of their values, which are then judged by the application requesting the attestation according to some policy.

Each PCR contains a hash representing a particular hardware measurement, which can be read at any time, but cannot be overwritten. Rather than allowing a traditional write operation, PCRs are updated through an "extend" operation which depends on the previous hash value, creating a chain of trust not dissimilar from how a blockchain is formed. This means that a given measurement can never be fully removed from the TPM.

Once the measurements are stored in the PCRs, there are various times and purposes for which the firmware or an operating system might read them - one example is for [remote attestation](https://www.gradient.tech/faq-items/what-are-platform-configuration-registers-pcrs/) during login to a system. In this scenario the attestation can be used to verify that the machine hasn't been tampered with (perhaps in an [Evil Maid](https://en.wikipedia.org/wiki/Evil_maid_attack) attack). One could also store a Certificate Authority signing key in a TPM, and have the Certificate Authority software interface with the TPM to sign certificates using the [PKCS#11 standard](https://en.wikipedia.org/wiki/PKCS_11).

My use-case is to enabling the TPM to provide the passphrase to unlock a LUKS-encrypted disk, which is what I'll focus on in this post.

## Secure Boot

Secure Boot is the mechanism by which the code executed by a machine's [Unified Extensible Firmware Interface (UEFI)](https://en.wikipedia.org/wiki/UEFI) can be verified as trusted. In the vast majority of cases, the first thing executed by the UEFI is a bootloader.

When Secure Boot is enabled, each binary executed by the UEFI must contain a checksum and a signature - which the UEFI verifies before launching the code. In the case that either the checksum or signature do not match, the UEFI will refuse the execute the code, and the boot process will halt.

Many OEM machines ship with Microsoft Windows installed, and thus ship with the necessary keys to validate signatures created with Microsoft's certificate authority. Linux systems are able to utilise these keys through [`shim`](https://github.com/rhboot/shim) - a small and easily verifiable piece of software which is signed by Microsoft. `shim` sits between the UEFI and the bootloader in the boot process, obviating the need for every Linux bootloader to be signed by Microsoft on every release. The shim is designed to _extend trust_ from the keys trusted by the computer's firmware to a new set of keys controlled by the operating system.

But what does Secure Boot get us in reality? By signing the kernel, and in some cases a single UEFI PE binary known as a [Unified Kernel Image (UKI)](https://wiki.archlinux.org/title/Unified_kernel_image) (which contains the bootloader, the kernel, the command-line used to boot the kernel, and [other resources](https://uapi-group.org/specifications/specs/unified_kernel_image/#uki-components)), one can be reasonably sure that the boot process hasn't been tampered with.

This process thwarts a number of common physical attack vectors, such as [manipulating the kernel command line to bypass the machine's login](https://linuxconfig.org/recover-reset-forgotten-linux-root-password) and drop straight to a root shell - and combined with disk encryption can prevent offline data transfer from the machine. It also defends against malware which compromises the operating system's boot process such that it can start before the OS and obfuscate it's presence.

## Threat Modelling

As with any security measure, Secure Boot is not a silver bullet. You should always consider your own personal threat model, and the sorts of attacks you're looking to defend against.

For example, Secure Boot can help prevent the sort of malware infections described in the previous section, but if an attacker gets physical access to your machine, and the UEFI isn't adequately protected, they could simply disable secure boot and carry on unhindered.

I mitigate this by password protecting the UEFI. This isn't perfect, but is likely sufficient protection for my threat model which is more about protecting chancers and petty thieves from gaining access to my information, than from determined attackers who gain physical access to my property.

Storing keys in a TPM is _theoretically_ safe, in that each TPM has a unique seed which cannot be retrieved, and enables the TPM to deterministically generate keys between reboots. It's _very difficult_ to retrieve the seed, and thus _very difficult_ to duplicate a TPM, but not impossible. Even then, the Linux kernel's communication with the TPM on-the-wire is unencrypted, and the same can be said for many other subsystems which use the TPM. A [recent example](https://hackaday.com/2024/02/06/beating-bitlocker-in-43-seconds/) of this vulnerability was demonstrated by sniffing a Bitlocker key off the [LPC bus](https://en.wikipedia.org/wiki/Low_Pin_Count) in a Lenovo X1 Carbon laptop (using a Raspberry Pi Pico, no less). In many modern machines this is mitigated by the TPM being on-CPU, but the point still stands.

I choose to enroll Microsoft's platform keys, which in theory degrades the security of my device in the case that Microsoft's signing key is compromised, though all of my machines are compatible with `fwupd` and can receive updates to the database through that mechanism if required (and in fact have done in the [past 18 months](https://uefi.org/revocationlistfile/archive)). This could be further mitigated by using custom keys and certificates for the full chain, but this is more overhead for daily operations and updates. It's also worth considering whether you have the resources to fully secure your own chain - especially by comparison to Microsoft who spend tens of millions of dollars per year on security. If an attacker wants your information, and are able to compromise Microsoft's CA, your own CA may not be such a hurdle.

Security measures are always a trade-off between Confidentiality, Availability and Integrity (CIA). In general, the more rigidly secure boot is implemented and configured, the more you're protecting confidentiality and integrity. The choices I've made are slightly more in favour of availability, but nonetheless raise the bar for any attacker significantly.

## Enabling Secure Boot on NixOS

Now for the fun part! The process for enabling Secure Boot on NixOS has simplified in recent months owing to the creation of [`lanzaboote`](https://github.com/nix-community/lanzaboote) - a project which takes of preparing and signing Unified Kernel Images containing a custom stub, the bootloader, the Linux kernel, the kernel's `initrd` and the kernel command line. `lanzaboote` also takes care of installing the UKI on the [ESP partition](https://en.wikipedia.org/wiki/EFI_system_partition) so the UEFI can execute it at boot.

The `lanzaboote` stub differs slightly from [`systemd-stub`](https://www.freedesktop.org/software/systemd/man/latest/systemd-stub.html), in that it doesn't require the kernel and initrd to be part of the UKI. This is important for a generation-based operating system like NixOS because bundling the kernel and initrd into a new UKI for every generation would consume a lot of disk space, and quickly exhaust the ESP on most machines. In `lanzaboote`'s implementation, the kernel and initrd are stored separately on the ESP, and the chain of trust is preserved by validating the signature of the kernel, and embedding a cryptographic hash of the initrd into the signed UKI.

The project takes advantage of systems that have [bootspec](https://github.com/NixOS/rfcs/blob/master/rfcs/0125-bootspec.md) enabled, which is a relatively recent NixOS RFC that ensures configured machines maintain a file containing a set of memoised facts about a system's closure. Bootspec aims to "provide more uniform feature support" to bootloaders in the NixOS ecosystem and "enable NixOS users to implement custom bootloader tools and policy" - of which `lanzaboote` is one.

### Generating Secure Boot Keys

The first step is to generate some keys for the secure boot process. This can be achieved using the [`sbctl` package](https://search.nixos.org/packages?channel=unstable&show=sbctl&from=0&size=50&sort=relevance&type=packages&query=sbctl):

```bash
❯ sudo nix run nixpkgs#sbctl create-keys
Created Owner UUID 6ac34cc3-a23d-9745-ef33-a03f523d20a3
Creating secure boot keys...✓
Secure boot keys created!
```

This should only take a few seconds at maximum, and will result in a set of keys being populated in `/etc/secureboot`:

```bash
❯ tree /etc/secureboot
/etc/secureboot
├── files.db
├── GUID
└── keys
   ├── db
   │  ├── db.key
   │  └── db.pem
   ├── dbx
   │  ├── dbx.key
   │  └── dbx.pem
   ├── KEK
   │  ├── KEK.key
   │  └── KEK.pem
   └── PK
      ├── PK.key
      └── PK.pem
```

### Enable Bootspec

Ensure that `bootspec` is enabled in your Nix configuration. You can see this in my flake for my desktop machine [on Github](https://github.com/jnsgruk/nixos-config/blob/e436e046f19c76fcea0ac2570e7a747153c02ad5/host/kara/boot.nix#L5):

```nix
{
  boot.bootspec.enabled = true;
}
```

### Enable `lanzaboote`

I use a [flake](https://nixos.wiki/wiki/Flakes) to configure all of my machines, so I'm able to get access to `lanzaboote` by adding the upstream flake as [an input](https://github.com/jnsgruk/nixos-config/blob/e436e046f19c76fcea0ac2570e7a747153c02ad5/flake.nix#L25-L26) to my own [nixos-config flake](https://github.com/jnsgruk/nixos-config):

```nix
# ...
inputs = {
  lanzaboote.url = "github:nix-community/lanzaboote";
};
# ...
```

Once you've added `lanzaboote` as a dependency, you'll need to import the `lanzaboote` module:

```nix
# ...
imports = [ lanzaboote.nixosModules.lanzaboote ];
# ...
```

In my flake, I use a custom [helper function](https://github.com/jnsgruk/nixos-config/blob/e436e046f19c76fcea0ac2570e7a747153c02ad5/lib/helpers.nix#L39) to build NixOS configurations, so the module is [passed directly](https://github.com/jnsgruk/nixos-config/blob/e436e046f19c76fcea0ac2570e7a747153c02ad5/lib/helpers.nix#L59) to `lib.nixosSystem` through the `modules` attribute.

The `lanzaboote` module replaces the `systemd-boot` module, and as such you must explicitly _disable_ `systemd-boot` when enabling `lanzaboote`. Additionally, if you wish to use the TPM for disk unlock (described in the next section), you must use the systemd initrd hooks (or something like [`clevis`](https://github.com/latchset/clevis/)):

```nix
boot = {
  initrd.systemd.enable = true;

  loader.systemd-boot.enable = lib.mkForce false;

  lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
};
```

This is represented in my config [here](https://github.com/jnsgruk/nixos-config/blob/e436e046f19c76fcea0ac2570e7a747153c02ad5/host/kara/boot.nix#L6-L10).

Once enabled, rebuild your system (in my case with `sudo nixos-rebuild switch --flake /home/jon/nixos-config`) and verify that your machine is ready for Secure Boot. Don't panic about the kernel images being reported as not signed, this is expected:

```shell
❯ sudo nix run unstable#sbctl verify
Verifying file database and EFI images in /boot...
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-414-376jna572gsb23snqs67t7s4bwxzb3epblmdnzweghuepopml2va.efi is signed
✓ /boot/EFI/Linux/nixos-generation-415-iqulgohymbdppgtxzho6ou3fcuxjbxhumpzm4vojmipwy3sbmuna.efi is signed
✓ /boot/EFI/Linux/nixos-generation-416-kxnzioafnduwwck3oypo7rqwtoat745czp2bpehoufp4yqiawypa.efi is signed
✗ /boot/EFI/nixos/kernel-6.8.2-242idodyvf36cpl6s5dskjy6mo4tjhszuwa3hye7qcjyuo5vnehq.efi is not signed
✗ /boot/EFI/nixos/kernel-6.8.5-zqulrwsucm6okcyns6v2jhh6fregk3bvsdth3yloqfymfbgnh64a.efi is not signed
✗ /boot/EFI/nixos/kernel-6.8.7-6mmixkr6ewywm5swgbi5ethbpgnyia4borzmkevcjx7n7t3mtida.efi is not signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
```

### Prepare the UEFI

Reboot your machine and enter the UEFI interface. This part of the process will vary from machine to machine depending on the UEFI implementation, but you're looking to enable Secure Boot, and clear the preloaded Secure Boot keys. This may be referred to as "Setup Mode", or erasing the "Platform Keys".

While you're here, I'd also advise setting a UEFI password before rebooting back into NixOS.

### Enroll Secure Boot Keys

The final stage in the process is to enroll your newly generated Secure Boot keys from step 1 into the UEFI. This is again achieved with `sbctl`:

```shell
❯ sudo nix run nixpkgs#sbctl enroll-keys -- --microsoft
Enrolling keys to EFI variables...
With vendor keys from microsoft...✓
Enrolled keys to the EFI variables!
```

I chose to use the `--microsoft` option to also enroll the UEFI vendor certificates from Microsoft. Some systems contain firmware that is signed and validated when Secure Boot is enabled, and omitting the Microsoft keys could prevent your device from booting - omit this option with caution!

### Verify Secure Boot

Once you've enrolled the keys, reboot the machine back into NixOS and use `bootctl` to confirm that Secure Boot is in fact enabled:

```shell
❯ bootctl status
System:
      Firmware: UEFI 2.80 (American Megatrends 5.26)
 Firmware Arch: x64
   Secure Boot: enabled (user)
  TPM2 Support: yes
  Boot into FW: supported
```

## TPM Unlock of Root Partition

Now that we're (reasonably) confident that no one can tamper with the boot process, we can progress to allowing the machine to auto-unlock the encrypted disk using a key stored in the TPM.

This is actually more common than you might think - Windows has enabled this behaviour by default for some time with Bitlocker disk encryption, and Canonical is also [working on](https://ubuntu.com/blog/tpm-backed-full-disk-encryption-is-coming-to-ubuntu) bringing TPM-backed full disk encryption to Ubuntu.

This is probably the easiest step of them all! A simple invocation of `systemd-cryptenroll` is all that's required. The arguments below instruct the machine that PCRs 0, 2, 7 and 12 should be measured and verified before the TPM is allowed to unlock the disk.

According to the [Linux TPM PCR Regsitry](https://uapi-group.org/specifications/specs/linux_tpm_pcr_registry/), this means the following are measured before the LUKS key is presented:

- PCR 0: Core system firmware executable code
- PCR 2: Extended or pluggable executable code
- PCR 7: SecureBoot state
- PCR 12: Kernel command line, system credentials and system configuration images

```shell
❯ sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/nvme0n1p2
```

And that's it! The next time you reboot, your disk should be automatically unlocked by the TPM, and your machine should boot straight to your display manager, or the TTY login if no display manager is configured.

## Useful Resources

None of the knowledge in this post is novel, but rather the culmination of some knowledge acquired over the past few years, and some more targeted reading more recently. In the process, I learned a bunch from the following:

- [Lanzaboote on Github](https://github.com/nix-community/lanzaboote)
- [ArchWiki on UEFI Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
- [NixOS Discourse Post on TPM Unlock](https://discourse.nixos.org/t/full-disk-encryption-tpm2/29454)
- [Bootspec RFC](https://github.com/NixOS/rfcs/blob/master/rfcs/0125-bootspec.md)
- [Lennart Poettering's UKI Talk at FOSDEM 2024](https://fosdem.org/2024/schedule/event/fosdem-2024-1985-ukis-tpms-immutable-initrds-and-full-disk-encryption-what-distributions-should-keep-in-mind-when-hopping-onto-the-system-integrity-train/)
- [James Bottomley's TPM Talk at FOSDEM 2024](https://fosdem.org/2024/schedule/event/fosdem-2024-3141-linux-kernel-tpm-security-and-trusted-key-updates/)
  [The Trusted Platform Module Key Hierarchy](https://ericchiang.github.io/post/tpm-keys/)

## Summary

About 5 years ago, I was sporting a fully secure-boot enabled Dell XPS 13 running Arch Linux. Back then, the process was complicated, manual, and required a lot of maintenance between upgrades. For me, it was more pain than gain, but an interesting learning experience nonetheless.

When I sat down earlier this year to enable Secure Boot on NixOS, I'd set aside a few hours. I was astounded that 10 minutes later I was finished. I wrote this post as a memo to my future self, but also to illustrate how simple it can be to enable Secure Boot and TPM disk unlock in 2024.

I don't claim to be an expert on the inner workings of TPMs, nor Secure Boot. The things I can say for certain are that TPMs are complex, that there are improvements that could be made to Linux's interactions with the TPM, and that a determined and well-resourced attacker is likely going to succeed one way or another.

If you spot an inaccuracy in this post, reach out and let me know on Mastodon, on Telegram, by email, or however you prefer!

Until next time!

> Update 2024/04/29: Thanks to [@pimeys](https://github.com/pimeys/) for pointing out that one must enable the systemd initrd hooks `systemd-cryptenroll` to function correctly, and also that PCR 12 must be measured to prevent the LUKS key from being released if the kernel command line has been modified.
