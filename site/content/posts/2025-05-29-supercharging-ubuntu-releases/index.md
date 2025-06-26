---
title: "Supercharging Ubuntu Releases: Monthly Snapshots & Automation"
summary: |
  We're building a new, automated release system for Ubuntu to make releases
  more reliable, observable, and testable. To better inform the design of that process,
  we're introducing monthly snapshot releases.
tags:
  - Development
  - Ubuntu
  - Canonical
  - Blog
  - Release Engineering
  - Snapshots
  - Releasing
  - Engineering
  - Process
  - Temporal
  - Durable Execution
layout: post
cover: cover.jpg
coverAlt: |
  Greyscale photography of a car engine
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/61876), and is reposted here. I welcome comments and further discussion in that thread.

## Introduction

Ubuntu has shipped on a predictable, six-month cadence for two decades. Twenty years ago, the idea of releasing an entire distribution every six months was considered forward looking, bold and even difficult. Things have changed since then: software engineering has evolved as a practice, and the advent of both rolling-release distributions like Arch Linux, and more recently image-based immutable distributions such as Universal Blue have meant that other projects with similar goals have adopted vastly different release models with some desirable properties.

My goal over the coming months is to build a release process that takes advantage of modern release engineering practices, while retaining the resilience and stability of our six-monthly releases. We'll introduce significantly more automated testing, and ensure that the release process is transparent, repeatable and executable in a much shorter and well-known timeframe with little to no human intervention.

This journey will also create space for better system-wide testing, earlier detection of regressions, and a more productive collaboration with our community.

## Monthly Snapshot Releases

Starting in May 2025, we're introducing monthly snapshot releases for Ubuntu.

Ubuntu is not "moving to monthly releases" or adopting a rolling release model; we're committed to our six-monthly releases with a Long Term Support (LTS) release every two years. That doesn't mean that our release process should be exempt from the same scrutiny that the rest of our engineering processes are subject to.

Today the Ubuntu Release process is the product of twenty years of evolution: it safeguards Ubuntu releases with a wealth of checks and balances, but is a largely manual process requiring significant human involvement.

The Ubuntu Release Team is a crowd of seasoned Ubuntu veterans who have been steadily releasing Ubuntu for many years. Many of this team are community members, some are or have been employed by Canonical in the past. More recently we have established the Canonical Ubuntu Release Management Team - a relatively new team at Canonical who'll be collaborating with the Ubuntu Release Team to develop the new process.

To aid the Canonical team in their understanding of the existing processes, and the immovable requirements that sit beneath it, we're introducing monthly snapshot releases for Ubuntu. These will not be fully-fledged releases of Ubuntu, but rather curated, testable milestones from our development stream. For the 25.10 (Questing Quokka) cycle, you can expect the following [release schedule](https://discourse.ubuntu.com/t/questing-quokka-release-schedule/36462):

- **May 29, 2025**: Questing Quokka - Snapshot 1
- **June 26, 2025**: Questing Quokka - Snapshot 2
- **July 31, 2025**: Questing Quokka - Snapshot 3
- **August 28, 2025**: Questing Quokka - Snapshot 4
- **September 18, 2025**: Questing Quokka - Beta
- **October 9, 2025**: Questing Quokka - Final Release

This doesn't mean you'll start seeing Ubuntu versions off the six-month cadence. There will be no Ubuntu 25.07 or 25.08, etc. The monthly snapshots are exactly that: a snapshot of the development of Ubuntu 25.10. Snapshots are not meant for production use, but will help the release team move away from deep institutional knowledge, and toward clean well-documented automated workflows that are transparent, repeatable and testable.

With our current model, failure modes are not detected until they're urgent and blocking an imminent release. The team conducts rigorous retrospectives on each release, but in my opinion it's hard to meaningfully evolve such a process when it's only exercised every six months. The monthly snapshots will create opportunities for us to test, understand and improve the process.

## Embracing Automation

One of the most valuable outcomes of this journey will be the opportunity to automate more of the process, freeing up time for the team to focus on more strategic tasks. Releasing a distribution is a complex process requiring coordination across architectures, images, mirrors, websites, testing infrastructure and even partner agreements. This also makes it hard to place a traditional CI tool at the heart of the process. As much as I like Github Actions, I think we'd quickly get lost trying to release Ubuntu with such a system, notwithstanding the fact that we'd lose control of the underlying infrastructure that releases Ubuntu.

I've been exploring the world of Durable Execution, which according to [restate.dev](https://restate.dev/what-is-durable-execution/) is:

> the practice of making code execution persistent, so that services recover automatically from crashes and restore the results of already completed operations and code blocks without re-executing them.

At Canonical, we've adopted [Temporal](https://temporal.io/) in a few of our products and in many of our business processes. Temporal is a durable execution product that enables developers to solve complex distributed problems, but without being deep distributed systems experts. It's a framework for composing tasks into workflows, with first-class primitives for dealing with failures, retries, exponential back-off and other concepts that enable the build of long-running complex workflows.

Having spent some time with Temporal myself, and watched other teams adopt it, I think it's a great fit for engineering our next-generation release process. I want our engineers to focus on the logic of the release process, not the infrastructure behind it, and Temporal should enable them to do just that. The Temporal [homepage](https://temporal.io/) sums it up nicely:

> Write code as if failure doesn’t exist

Temporal [workflows](https://docs.temporal.io/evaluate/understanding-temporal#workflow) and [activities](https://docs.temporal.io/evaluate/understanding-temporal#activities) can be written in many languages - and particularly in Python and Go. My expectation is that Go will prove to be an excellent fit for our process: it's a fast and productive language that specialises in concurrency and asynchronous network operations, and has a powerful standard library containing much of the functionality we'll need to build our new release process.

To take an overly simplistic view of how I expect this to go: we'll take our existing release checklist, write a Go function for each step with some [tests](https://docs.temporal.io/develop/go/testing-suite), and compose them together into one or more Temporal workflows that represent the full release process. This will take time, but this approach will enable us to incrementally demonstrate progress toward a fully-automated process over the coming cycles.

By making this move, not only will we make the process quicker, but also more [observable](https://docs.temporal.io/develop/go/observability), [testable](https://docs.temporal.io/develop/go/testing-suite), reliable and easier to understand for everyone, not just the release team.

## Improving Test Coverage

One area I'd like to improve as a side-effect of this work is more full-system integration testing. Packages in the Ubuntu archive generally enjoy good coverage through a suite of [autopkgtest](https://autopkgtest.ubuntu.com/) tests, and there are numerous other places where integration tests are run on Ubuntu. With our traditional six-monthly cadence, full end-to-end testing of ISOs and the installer typically ramps up close to release time when changes are fewer (and riskier) and time is short.

With the introduction of monthly snapshots, we can integrate installer testing, full-disk encryption testing, graphical application testing and more as a regular, automated part of the release pipeline - not just as part of the development pipeline of each individual package. This means we should catch regressions earlier and surface more edge cases to be resolved before release.

One of the most important parts of increasing our testing culture is to make it clear where and how to contribute tests to Ubuntu. The easier we make it to write and contribute tests, the more tests we're likely to add to the suite. We're doing some work on this in parallel which will likely turn into a blog post of its own in the coming months.

In our current process, we have a heroic group of volunteers who kindly spend hours on our behalf testing the various flavours - exercising all the possible install paths and validating that what is about to be published is fit for purpose. I'd like to ensure that our volunteers' time is spent as productively and rewardingly as possible, and I think we can automate much of this testing and allow them to focus on the more complex and nuanced aspects of each release, and raise the quality of Ubuntu across all the flavours.

## What's Next?

We’re starting by modeling the current release process as it is. Once we've validated our assumptions about the current process, we’ll layer in improvements by reducing manual gates, parallelising independent steps, introducing more testing, and exercising the process each month to test (and measure) any improvements we've made.

My ultimate goal is a release system that’s incredibly "boring": transparent, predictable, observable, and easy to reason about (even when things go wrong).

The new, fully-automated process will likely take several months to complete. When we think we're done, we'll do a release that runs both processes in parallel to ensure we get the outcome we expect before finally sunsetting the old process.

We’ll be building this work in the open (and [hiring](https://canonical.com/careers)!) so if you’ve used Temporal in similar contexts, or are curious about contributing to this effort, we’d love to hear from you.

Until next time!
