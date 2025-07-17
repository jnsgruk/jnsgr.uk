---
title: "Crafting Your Software"
summary: |
  Packaging software is notoriously tricky. Every language, framework,
  and build system has its quirks, and the variety of artifact types —
  from Debian packages to OCI images and cloud images — only adds to
  the complexity.

  This blog is a deep-dive on Canonical's "craft" tools, how they
  evolved, and how to use them to simplify package maintenance.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Snapcraft
  - Rockcraft
  - Charmcraft
  - Debcraft
  - Starcraft
  - Open Source
layout: post
cover: cover.jpg
coverAlt: |
  A hand finding the "missing piece" in a puzzle.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/crafting-your-software/64809), and is reposted here. I welcome comments and further discussion in that thread.

Packaging software is notoriously tricky. Every language, framework, and build system has its quirks, and the variety of artifact types — from Debian packages to OCI images and cloud images — only adds to the complexity.

Over the past decade, Canonical has been refining a family of tools called “crafts” to tame this complexity and make building, testing, and releasing software across ecosystems much simpler.

The journey began on 23rd June 2015 when the first commit was made to [Snapcraft](https://github.com/canonical/snapcraft), the tool used to build Snap packages. For years, Snapcraft was *the only* craft in our portfolio, but in the last five years, we’ve generalized much of what we learned about building, testing, and releasing software into a number of "crafts" for building different artifact types.

Last month, I [outlined](https://jnsgr.uk/2025/06/introducing-debcrafters/) Canonical's plan to build `debcraft` as a next-generation way to build Debian packages. In this post I'll talk about what exactly *makes* a craft, and why you should bother learning to use them.

## Software build lifecycle

At the heart of all our crafts is [`craft-parts`](https://canonical-craft-parts.readthedocs-hosted.com/latest/), which according to the [documentation](https://canonical-craft-parts.readthedocs-hosted.com/latest/) "provides a mechanism to obtain data from different sources, process it in various ways, and prepare a filesystem sub-tree suitable for packaging".

Put simply, `craft-parts` gives developers consistent tools to fetch, build, and prepare software from any ecosystem for packaging into various formats.

### Lifecycle stages

Every part has a minimum of four lifecycle stages:
- `PULL`: source code or binary artifacts, along with dependencies are pulled from various sources
- `BUILD`: software is built automatically by a `plugin`, or a set of custom steps defined by the developer
- `STAGE`: select outputs from the `BUILD` phase are copied to a unified staging area for all parts
- `PRIME`: files from the staging area are copied to the priming area for use in the final artifact.

The `STAGE` and `PRIME` steps are similar, except that `PRIME` only happens after *all* parts of the build are staged. Additionally, `STAGE` provides the opportunity for parts to build/supply dependencies for other parts, but that might not be required in the final artifact.

### Lifecycle in the CLI

The lifecycle stages aren’t just in the build recipe, they’re also first-class citizens in each craft’s CLI, thanks to the [craft-cli](https://github.com/canonical/craft-cli) library. This ensures a consistent command-line experience across all craft tools.

Take the following examples:

```bash
# Run the full process including PULL, BUILD, STAGE, PRIME and then pack the final artifact
snapcraft pack
charmcraft pack
rockcraft pack

# Run the process up to the end of the STAGE step
rockcraft stage

# Run the process up to the PRIME step
charmcraft prime
```

This design feature supports a smoother iterative development and debugging workflow for building and testing software artifacts.

### Part definition

The `parts` of a build vary in complexity - some require two-three trivial lines, others require detailed specification of dependencies, build flags, environment variables and steps. The best way to understand the flexibility of this system is by looking at some examples.

First, consider this (annotated) example from my [icloudpd snap](https://github.com/jnsgruk/icloudpd-snap/blob/beb2c7d2539547dfff5d4fd99687573d75597633/snap/snapcraft.yaml):

```yaml
icloudpd:
    # Use the 'python' plugin to build the
    # software. This takes care of identifying
    #  Python package dependencies, building the wheel
    # and ensuring the project's dependencies are staged
    # appropriately.
    plugin: python
    # Fetch the project from Github, using the tag the matches
    # the version of the project.
    source: https://github.com/icloud-photos-downloader/icloud_photos_downloader
    source-tag: v$SNAPCRAFT_PROJECT_VERSION
    source-type: git
```

This spec is everything required to fetch, build and stage the important bits required to run the software - in this case a Python wheel and its dependencies.

Some projects might require more set up, perhaps an additional package is required or a specific version of a dependency is needed. Let's take a look at a slightly more complex example taken from my [zinc-k8s-operator](https://github.com/jnsgruk/zinc-k8s-operator/blob/5516be2c50e52b33742c674f266c8dfca55e6edf/rockcraft.yaml#L90C3-L100C20) project:

```yaml
kube-log-runner:
    # Use the 'go' plugin to build the software.
    plugin: go
    # Fetch the source code from Git at the 'v0.17.0' tag.
    source: https://github.com/kubernetes/release
    source-type: git
    source-tag: v0.17.8
    # Change to the specified sub-directory for the build.
    source-subdir: images/build/go-runner
    # Install the following snaps in the build environment.
    build-snaps:
      - go/1.20/stable
    # Set the following environment variables in the build
    # environment.
    build-environment:
      - CGO_ENABLED: 0
      - GOOS: linux
```

This instructs `rockcraft` to fetch a Git repository at a particular tag, change into the sub-directory `images/build/go-runner`, then build the software using the `go` plugin. It also specifies that the build required the `go` snap from the `1.20/stable` track, and sets some environment variables. That's a lot of result for not much YAML. The end result of this is a single binary that's "staged" and ready to be placed (in this case) into a [Rock](https://documentation.ubuntu.com/rockcraft/en/latest/explanation/rocks/) (Canonical's name for OCI images).

And the best part: this exact definition can be used in a `rockcraft.yaml` when building a Rock, a `snapcraft.yaml` when building a Snap, a `charmcraft.yaml` when building a Charm, etc.

The plugin system is extensive: at the time of writing there are [22 supported plugins](https://canonical-craft-parts.readthedocs-hosted.com/latest/reference/plugins/), including `go`, `maven`, `uv`, `meson` and more. If your build system of choice isn't supported you can specify manual steps, giving you as much flexibility as you need:

```yaml
wasi-sdk:
    # There is no appropriate plugin for this part, so set
    # it to 'nil' and we'll specify our own build process
    # using 'override-build'.
    plugin: nil
    # In this recipe, a previous part named 'clang' is
    # required to build before attempting to build this
    # part.
    after:
      - clang
    # Specify any `apt` packages required in the build
    # environment.
    build-packages:
      - wget
    # Set some environment variables for the build
    # environment.
    build-environment:
      - WASI_BRANCH: "15"
      - WASI_RELEASE: "15.0"
    # Define how to pull the software manually.
    override-pull: |
      ROOT=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$WASI_BRANCH
      wget $ROOT/wasi-sysroot-$WASI_RELEASE.tar.gz
      wget $ROOT/libclang_rt.builtins-wasm32-wasi-$WASI_RELEASE.tar.gz
    # Define how to 'build' the software manually
    override-build: |
      craftctl default
      tar -C $CRAFT_STAGE -xf wasi-sysroot-$WASI_RELEASE.tar.gz
      tar -C $CRAFT_STAGE/usr/lib/clang/* -xf libclang_rt.builtins-wasm32-wasi-$WASI_RELEASE.tar.gz
    # Don't prime anything for inclusion in the
    # final artifact; this part is only used for
    # another part's build process.
    override-prime: ''
```

Here, multiple stages of the lifecycle are overridden using `override-build`, `override-pull` and `override-stage`, and we see `craftctl default` for the first time, which instructs snapcraft to do whatever it would have done prior being overridden, but allows the developer to provide additional steps either before or after the default actions.

## Isolated build environments

Even once a recipe for building software is defined, preparing machines to build software can be painful. Different major versions of the same OS might have varying package availability, your team might run completely different operating systems, and you might have limited image availability in your CI environment.

The crafts solve this with build "backends". Currently the crafts can use [LXD](https://canonical.com/lxd) or [Multipass](https://canonical.com/multipass) to create isolated build environments, which makes it work nicely on Linux, macOS and Windows. This functionality is handled automatically by the crafts through the [`craft-providers`](https://canonical-craft-providers.readthedocs-hosted.com/en/latest/) library. The `craft-providers` library provides uniform interfaces for creating build environments, configuring base images and executing builds.

This means if you can run `snapcraft pack` on your machine, your teammates can also run the same command without worrying about installing the right dependencies or polluting their machines with software and temporary files that might result from the build.

One of my favourite features of this setup is the ability to drop into a shell inside the build environment automatically on a few different conditions:

```bash
# Drop into a shell if any part of the build fails.
snapcraft pack --debug
# Drop into a shell after the build stage.
rockcraft build --shell-after
# Drop to a shell in lieu of the prime stage.
snapcraft prime --shell
```

This makes troubleshooting a failing build much simpler, while allowing the developer to maintain a clean separation between the build environment and their local machine. Should the build environment ever become polluted, or otherwise difficult to work with, you can always start from a clean slate with `snapcraft|rockcraft|charmcraft clean`. Each build machine is constructed using a cached `build-base`, which contains all the baseline packages required by the craft - so recreating the build environment for a specific package only requires that base to be cloned and augmented with project specific concerns - making the process faster.

## Saving space

When packaging any kind of software, a common concern is the size of the artifact. This might be because you're building an OCI-image that is pulled thousands of times a day as part of a major SaaS deployment, or maybe it's a Snap for an embedded device running [Ubuntu Core](https://ubuntu.com/core) with a limited flash. In the container world, "[distroless](https://github.com/GoogleContainerTools/distroless)" became a popular way to solve this problem - essentially popularising the practice of shipping the barest minimum in a container image, eschewing much of the traditional Unix FHS.

The parts mechanism has provided a way of "filtering" what is staged or primed into a final artifact from the start, which already gave developers autonomy to choose exactly what went into their builds.

In addition to this, Canonical built "[chisel](https://documentation.ubuntu.com/chisel/en/latest/tutorial/getting-started/)", which extends the distroless concept beyond containers to any kind of artifact. With `chisel`, developers can slice out just the binaries, libraries, and configuration files they need from the Ubuntu Archive, enabling ultra-small packages without losing the robustness of Ubuntu’s ecosystem.

We later launched [Chiseled JRE](https://ubuntu.com/blog/chiseled-ubuntu-containers-openjre) containers, and there are numerous other Rocks that utilise `chisel` to provide a balance between shipping *tiny* container images, while benefiting from the huge selection and quality of software in the Ubuntu Archive.

Because the crafts are all built on a common platform, they now all have the ability to use "slices" from [chisel-releases](https://github.com/canonical/chisel-releases), which enables a greater range of use-cases where artifact size is a primary concern. Slices are community maintained, and specified in simple to understand YAML files. You can see the list of available slices for the most recent Ubuntu release (25.04 Plucky Puffin) [on GitHub](https://github.com/canonical/chisel-releases/tree/ubuntu-25.04/slices), and further documentation on slices and how they're used in the [Chisel docs](https://documentation.ubuntu.com/chisel/en/latest/explanation/mode-of-operation/).

## Multi-architecture builds

Ubuntu supports six major architectures at the time of writing (`amd64`, `arm64`, `armhf`, `ppc64le`, `s390x`, `riscv64`), and all of our crafts have first-class support for each of them. This functionality is provided primarily by the [craft-platforms](https://github.com/canonical/craft-platforms) library, and supported by the [craft-grammar](https://github.com/canonical/craft-grammar) library, which enables more complex definitions where builds may have different steps or requirements for different architectures.

At a high-level, each artifact defines which architectures or platforms it is built *for*, and which it is built *on*. These are often, but not always, the same. For example:

```yaml
platforms:
  amd64:
```

This is shorthand for "build the project on `amd64` for `amd64`", but in a different example taken from a `charmcraft.yaml`

```yaml
platforms:
  all:
    build-on: [amd64]
    build-for: [all]
```

In this case the software is built on `amd64`, but can run on any of the supported architectures - this can happen with all-Python wheels, `bash` scripts and other interpreted languages which don't link platform-specific libraries.

In some build processes, the process or dependencies might differ per-architecture, which is where `craft-grammar` comes in, enabling expressions such as (taken from [GitHub](https://github.com/canonical/mesa-core22/blob/86060bf66e70d0f5d421fe818d61cdc0f18f9b31/snap/snapcraft.yaml#L265C3-L280C46)):

```yaml
fit-image:
  # ...
  build-packages:
  # ...
  - wget
  - libjson-c-dev:${CRAFT_ARCH_BUILD_FOR}
  - libcryptsetup-dev:${CRAFT_ARCH_BUILD_FOR}
  # Only use the following build packages when building for armhf
  - to armhf:
    - binutils-arm-linux-gnueabi
    - gcc-arm-linux-gnueabihf
    - pkgconf:armhf
  # When building for arm64, use a different set
  - to arm64:
    # Dependencies for building *for* arm64 *on* amd64!
    - on amd64:
      - gcc-aarch64-linux-gnu
      - pkgconf:arm64
    - on arm64:
      - gcc

```

Being able to define how to build on different architectures is only half of the battle, though. It's one thing to define *how* to build software on an `s390x` machine but few developers have mainframes handy to actually *run* the build! This is where the crafts' `remote-build` capability comes in. The `remote-build` command sends builds to Canonical's build farm, which has native support for all of Ubuntu's supported architectures. This is built into all of our crafts, and is triggered with `snapcraft remote-build`, `rockcraft remote-build`, etc.

Remote builds are a lifeline for publishers and communities who need to reach a larger audience, but can't necessarily get their own build farm together. One example of this is [Snapcrafters](https://snapcrafters.org/), a community-driven organisation that packages popular software as Snaps, who use `remote-build` to drive multi-architecture builds from [GitHub Actions](https://github.com/snapcrafters/ci) as part of their publishing workflow (as seen [here](https://github.com/snapcrafters/helm/actions/runs/16166314558) and [here](https://github.com/snapcrafters/terraform/actions/runs/15607983328) for example).

## Unified testing framework

Testing is often the missing piece in build tools: developers are forced to rely on separate CI systems or ad-hoc scripts to verify their artifacts. To close this gap, we’re introducing a unified `test` sub-command in the crafts.

We recently added the `test` sub-command to our crafts as an experimental (for now!) feature. Under the hood, `craft test` will introduce a new lifecycle stage (`TEST`). The enables packagers of any artifact type to specify how that artifact should be tested using a common framework across artifact types.

Craft's testing capability is powered by [spread](https://github.com/canonical/spread), a convenient full-system task distribution system. Spread was built to simplify the massive number of integration tests run for the [snapd](https://github.com/canonical/snapd) project. It enables developers to specify tests in a simple language, and distribute them concurrently to any infrastructure they have available.

This enables a developer to define tests and test infrastructure, and make it trivial to run the same tests locally, or remotely on cloud infrastructure. This can really speed up the development process - preventing developers from needing to wait on CI runners to spin up and test their code while iterating, they can run the very same integration tests locally using `craft test`.

There are lots of fine details to `spread`, and the team is working on artifact-specific abstractions for the crafts that will make testing *delightful*. Imagine maintaining the Snap for a GUI application, and being able to enact the following workflow:

```bash
# Pull the repository
git clone https://github.com/some-gui-app/snap && cd snap
# Make some changes, perhaps fix a bug
vim snap/snapcraft.yaml
# Build the snap, and run the integration tests.
# These tests might include spinning up a headless
# graphical VM, which actually installs and runs
# the snap, and interacts with it
snapcraft test
```

By integrating a common testing tool into the build tooling, the Starcraft team will be able to curate unique testing experiences for each kind of artifact. A snap might need a headless graphical VM, where an OCI-image simply requires a container runtime, but the `spread` underpinnings allow a common test-definition language for each.

There are a couple of examples of this in the wild already:

```bash
# Install charmcraft
sudo snap install --classic charmcraft
# Clone the repo
git clone https://github.com/jnsgruk/zinc-k8s-operator
cd zinc-k8s-operator
# List the available tests
charmcraft test --list lxd:
# Run the integration testing suite, spinning up
# a small VM, inside which is a full Kubernetes
# instance, with a Juju controller bootstrapped.
# From here the charm will be deployed and tested to
# ensure it's integrations with the observability
# stack and ingress charms are functioning correctly.
charmcraft test -v lxd:ubuntu-24.04:tests/spread/observability-relations:juju_3_6
```

The test above is powered by this [spread.yaml](https://github.com/jnsgruk/zinc-k8s-operator/blob/main/spread.yaml), and this [test definition](https://github.com/jnsgruk/zinc-k8s-operator/blob/5516be2c50e52b33742c674f266c8dfca55e6edf/tests/spread/observability-relations/task.yaml). With a little bit of [work](https://github.com/jnsgruk/zinc-k8s-operator/blob/5516be2c50e52b33742c674f266c8dfca55e6edf/.github/workflows/build-and-test.yaml#L80-L129), it's also possible to integrate `spread` with GitHub matrix actions, giving you one GitHub job per `spread` test - as seen [here](https://github.com/jnsgruk/zinc-k8s-operator/actions/runs/15638336939).

You can see a similar example in our [PostgreSQL Snap test suite](https://github.com/canonical/postgresql-snap/tree/7e6ee6d3148c20309cc7067dc40520e208f862e5/spread/tests), and we'll be adding more and more of this kind of test across our Rock, Snap, Charm, Image and Deb portfolio.

There is work to do, but I'm really excited about bringing a common testing framework to the crafts which should make the testing of all kinds of artifacts more consistent and easier to integrate across teams and systems.

## Crafting the crafts

As the portfolio expanded from `snapcraft`, to `charmcraft`, to `rockcraft` and is now expanding further to `debcraft` and `imagecraft` it was clear that we'd need a way to make it easy to build crafts for different artifacts, while being rigorous about consistency across the tools. A couple of years ago, the team built the [craft-application](https://github.com/canonical/craft-application) base library, which now forms the foundation of all our crafts.

The `craft-application` library combines many of the existing libraries that were in use across the crafts (listed below), providing a consistent base upon which artifact-specific logic can be built. The allows craft developers to spend less time implementing CLI details, `parts` lifecycles and store interactions, and more time on curating a great experience for the maintainers of their artifact type.

For the curious, `craft-application` builds upon the following libraries:

- [craft-archives](https://github.com/canonical/craft-archives): manages interactions with `apt` package repositories
- [craft-cli](https://github.com/canonical/craft-cli): CLI client builder that follows the Canonical's CLI guidelines
- [craft-parts](https://github.com/canonical/craft-parts): obtain, process, and organize data sources into deployment-ready filesystems.
- [craft-grammar](https://github.com/canonical/craft-grammar): advanced description grammar for parts
- [craft-providers](https://github.com/canonical/craft-providers): interface for instantiating and executing builds for a variety of target environments
- [craft-platforms](https://github.com/canonical/craft-platforms): manage target platforms and architectures for craft applications
- [craft-store](https://github.com/canonical/craft-store): manage interactions with Canonical's software stores
- [craft-artifacts](https://github.com/canonical/craft-artifacts): pack artifacts for craft applications

## Examples and docs

Before I leave you, I wanted to reference a few `*craft.yaml` examples, and link to the documentation for each of the crafts, where you'll find the canonical (little c!) truth on each tool.

You can find documentation for the crafts below:
- [Snapcraft docs](https://documentation.ubuntu.com/snapcraft/stable/)
- [Charmcraft docs](https://canonical-charmcraft.readthedocs-hosted.com/stable/)
- [Rockcraft docs](https://documentation.ubuntu.com/rockcraft/en/stable/)
- [Robotics / Snapcraft tutorial](https://canonical-robotics.readthedocs-hosted.com/en/latest/tutorials/)

And some example recipes:
- Snap: `icloudpd` - [snapcraft.yaml](https://github.com/jnsgruk/icloudpd-snap/blob/main/snap/snapcraft.yaml)
- Snap: `parca-agent` - [snapcraft.yaml](https://github.com/parca-dev/parca-agent/blob/main/snap/snapcraft.yaml)
- Snap: `signal-desktop` - [snapcraft.yaml](https://github.com/snapcrafters/signal-desktop/blob/candidate/snap/snapcraft.yaml)
- Charm: `ubuntu-manpages-operator` - [charmcraft.yaml](https://github.com/canonical/ubuntu-manpages-operator/blob/main/charmcraft.yaml)
- Rock: `grafana` - [rockcraft.yaml](https://github.com/canonical/grafana-rock/blob/main/11.4.0/rockcraft.yaml)
- Rock: `temporal-server` - [rockcraft.yaml](https://github.com/canonical/temporal-rocks/blob/main/temporal-server/1.23.1/rockcraft.yaml)

## Summary

The craft ecosystem provides developers with a rigorous, consistent and pleasant experience for building many kinds of artifacts. At the moment, we support Snaps, Rocks and Charms but we're actively developing crafts for Debian packages, cloud images and more.The basic build process, `parts` ecosystem and foundations of the crafts are "battle tested" at this point, and I'm excited to see how the experimental `craft test` commands shape up across the crafts.

One of the killer features for the crafts is the ability to reuse part definitions across different artifacts - which makes the pay off for learning the `parts` language very high - it's a skill you'll be able to use to build Snaps, Rocks, Charms, VM Images and soon Debs!

If I look at ecosystems like Debian, where tooling like `autopkgtest` is the standard, I think `debcraft test` will offer an intuitive entrypoint and encourage more testing, and the same is true of Snaps, both graphical and command-line.

That's all for now!
