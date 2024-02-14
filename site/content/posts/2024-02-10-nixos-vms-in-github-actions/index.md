---
title: Integration testing with NixOS in Github Actions
summary: |
  A write up of how I boot KVM accelerated NixOS VMs on Github Actions
  runners in order to run end-to-end tests for my packages.
tags:
  - Nix
  - Github Actions
  - Testing
  - Snaps
  - Rocks
  - Charms
  - Blog
layout: post
---

## Introduction

While in my own time I've tended toward NixOS over the past 18 months, in my day-to-day work for [Canonical](https://canonical.com) I'm required to interact with a fair few of our products - and particularly build tools.

I frequently need to use some combination of [Snaps](https://snapcraft.io/docs), [Charms](https://juju.is/docs/juju/charmed-operator) and [Rocks](https://ubuntu.com/server/docs/rock-images/introduction). Each of these have their own "craft" build tools ([`snapcraft`](https://github.com/snapcore/snapcraft), [`charmcraft`](https://github.com/canonical/charmcraft) and [`rockcraft`](https://github.com/canonical/rockcraft)), which are distributed exclusively as Snap packages and thus a little tricky to consume from NixOS.

## The Problem

Packaging the tools for Nix was a little repetitive, but not particularly difficult. They're all built with Python, and share a common set of libraries. Testing that the packages were working correctly (i.e. could actually build software) _on NixOS_ using the _NixOS version of LXD_ in Github Actions proved more difficult.

Github Actions defaults to Ubuntu as the operating system for its runners - an entirely sensible choice, but not one that was going to help me test packages could work together on NixOS.

I could have hosted my own Github Actions runners to solve the problem, but I didn't want to maintain such a deployment.

For a while I relied on just testing each of the crafts locally before pushing, and the CI simply installed the Nix package manager on the runners (using the _excellent_ [Nix installer from Determinate Systems](https://github.com/DeterminateSystems/nix-installer)) and ensured that the build could succeed, but this left a lot to be desired - particularly when I accidentally (and somewhat inevitably) broke one of the packages.

## KVM for Github Actions

Some time later I came across [this post](https://github.blog/changelog/2023-02-23-hardware-accelerated-android-virtualization-on-actions-windows-and-linux-larger-hosted-runners/) on the Github Blog, stating the following:

> Starting on February 23, 2023, Actions users [...] will be able to make use of hardware acceleration [...].

What follows is an example of a relatively simple addition to a Github Workflow to enable KVM on Github Actions runners:

```yaml
- name: Enable KVM group perms
  run: |
    echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger --name-match=kvm
```

Given the ability to relatively easily create NixOS VMs from a machine configuration, this should enable me to run a NixOS VM inside my Github Actions runners, and use that VM to run end to end tests of my craft packages.

After some quick tests, I confirmed that the above snippet worked just fine on the freely available runners that are assigned to public projects. After [tooting excitedly](https://hachyderm.io/@jnsgruk/111449289662026017) about this, it was also picked up by the folks at Determinate Systems who [promptly added support](https://octodon.social/@grahamc/111450168028125913) for this in their Nix install Github Action - enabling the feature by default.

## Building VMs with Nix

A really nice feature of NixOS that I discovered relatively late, is that given a NixOS machine configuration [it's trivial to build a virtual machine](https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf) image for that configuration. This has the nice property that one can actually boot a VM-equivalent of any previously defined machines. You could, for example, boot a VM-equivalent of my laptop with the following command:

```bash
nix run github:jnsgruk/nixos-config#nixosConfigurations.freyja.config.system.build.vm
```

In order to test my craft tools, I needed a relatively simple NixOS VM that had LXD enabled, and my craft tools installed. My test VM [configuration](https://github.com/jnsgruk/crafts-flake/blob/f63f315ee2832a112e0777b8af575297c8c9e62d/test/vm.nix) looks like this:

```nix
{ modulesPath, flake, pkgs, ... }: {
  # A nice helper that handles creating the VM launch script, which in turn
  # ensures the disk image is created as required, and QEMU is launched
  # with sensible parameters.
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  # Define the version of NixOS and the architecture.
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  # This overlay is provided by the crafts-flake, and ensures that
  # 'pkgs.snapcraft', 'pkgs.charmcraft', 'pkgs.rockcraft' all resolve to
  # the packages in the flake.
  nixpkgs.overlays = [ flake.outputs.overlay ];

  # These values are tuned such that the VM performs on Github Actions runners.
  virtualisation = {
    forwardPorts = [{ from = "host"; host.port = 2222; guest.port = 22; }];
    cores = 2;
    memorySize = 5120;
    diskSize = 10240;
  };

  # Configure the root user without password and enable SSH.
  # This VM will only ever be used in short-lived testing environments with
  # no inbound networking permitted, so there is minimal (if any) risk.
  # If you put this VM on the internet, you can keep the pieces! :)
  networking.firewall.enable = false;
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.extraUsers.root.password = "password";

  # Ensure that LXD is installed, and started on boot.
  virtualisation.lxd.enable = true;

  # Include the `craft-test` script, ensuring the craft apps are installed
  # and included in its PATH.
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "craft-test";
      runtimeInputs = with pkgs; [ unixtools.xxd git snapcraft charmcraft rockcraft ];
      text = builtins.readFile ./craft-test;
    })
  ];
}
```

Anybody can build and launch this VM trivially:

```bash
nix run github:jnsgruk/crafts-flake#testVM
```

## Writing a Github workflow

All the building blocks are in place! I wanted to keep the actual workflow definition for the tests as clean and understandable as possible, so I put together the [`craft-test`](https://github.com/jnsgruk/crafts-flake/blob/f63f315ee2832a112e0777b8af575297c8c9e62d/test/craft-test) script as a small helper which automates the building of real artefacts. An example invocation might be:

```bash
bash craft-test snapcraft
```

On each invocation, the script creates temporary directory, clones some representative build files for the selected craft tool, and launches the craft. The repos it uses for the representative packages are hard-coded for each craft for now.

I wrote one more [small helper script](https://github.com/jnsgruk/crafts-flake/blob/f63f315ee2832a112e0777b8af575297c8c9e62d/test/vm-exec) to simplify connecting to the VM with the required parameters. It's a wrapper around `ssh` and `sshpass` that's hard-coded with the credentials of the test VM (don't @ me!), and executes commands over SSH in the test VM. Using this script, one can `bash vm-exec -- craft-test snapcraft` and the `craft-test` script will be executed over SSH in the VM.

With all that said and done, the resulting [workflow](https://github.com/jnsgruk/crafts-flake/blob/f63f315ee2832a112e0777b8af575297c8c9e62d/.github/workflows/test.yaml) is pleasingly simple:

```yaml
# ...
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ["charmcraft", "rockcraft", "snapcraft"]
    steps:
      - name: Checkout flake
        uses: actions/checkout@v4

      - name: Install nix
        uses: DeterminateSystems/nix-installer-action@v9

      - name: Build and run the test VM
        run: |
          nix run .#testVm -- -daemonize -display none

      - name: Test ${{ matrix.package }}
        run: |
          nix run .#testVmExec -- craft-test ${{ matrix.package }}
```

A separate job is run for each of the crafts, and a real artefact is built in each, giving reasonable confidence that the consumers of my flake will be successful when building snaps, rocks and charms natively on NixOS. A successful run can be seen [here](https://github.com/jnsgruk/crafts-flake/actions/runs/7772604925).

## Summary

In this article we've covered:

- Enabling KVM on Github Runners
- Building NixOS VMs using Flakes
- Booting NixOS VMs in Github Actions

If you'd like to build snaps, rocks or charms and you're running NixOS, you can run the tools individually from my flake:

```bash
# Run charmcraft
nix run github:jnsgruk/crafts-flake#charmcraft

# Run rockcraft
nix run github:jnsgruk/crafts-flake#rockcraft

# Run snapcraft
nix run github:jnsgruk/crafts-flake#snapcraft
```

Or you can check out the [README](https://github.com/jnsgruk/crafts-flake) for instructions on how to integrate into your Nix config using overlays!

That's all for now! 🤓
