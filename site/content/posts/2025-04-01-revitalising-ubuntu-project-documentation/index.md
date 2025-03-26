---
title: "Revitalising Ubuntu Project Documentation"
summary: |
  TODO
tags:
  - Development
  - Ubuntu
  - Canonical
  - Blog
  - Documentation
  - Governance
layout: post
cover: cover.jpg
coverAlt: |
  TODO
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/), and is reposted here. I welcome comments and further discussion in that thread.

## Introduction

Back in February I [wrote](https://jnsgr.uk/2025/02/engineering-ubuntu-for-the-next-20-years/) briefly about my thoughts on documentation and its role within the community and in Ubuntu's future. As I wrote then, I believe documentation is a critical form of communication.

Documentation isn't just about technical how-to guides and tutorials, nor is it just about troubleshooting. Documentation can set the tone for a project, state an intent from a community and guide our current and future contributors in their daily work.

Ubuntu has a lot of documentation, but it's not always easy to find or understand. Our documentation should illuminate and inspire a path to contribution. It should provide direction and clarity on complex decisions, but also reference. Where there has been lots of focus in the last two years on the technical aspects of our documentation, I'd like to focus more on what I'm calling the "Ubuntu Project Documentation" over the coming months.

The project documentation should detail what makes Ubuntu happen. How are decisions made? What are the teams contributing to Ubuntu? How are those teams appointed? What are their responsibilities? If you're on the Main Inclusion Review team and you're assigned a package to review, what steps should you take? How does package sponsorship work, and who should you contact if you're stuck? How are the ACLs updated for package sets, and who can make those changes?

If a potential contributor identifies a bug in a package, there should be one authoritative source of information on where the package source is located, how it can be pulled, how it can be built and tested, and how they can work with a sponsor to land their changes. Such a process is satisfying for contributors, making it more likely they'll stay engaged, and also beneficial for the distribution.

These are all examples of questions that we, as the collective conscious of Ubuntu, know the answers to. Despite that, they are often difficult to find for people, or they require input from some of our busiest and most knowledgeable contributors.

## The Challenge

Much of the required content already exists. The venerable [Ubuntu Wiki](https://wiki.ubuntu.com/) was the go-to destination for such documentation, but has become outdated - both technologically and in the content it serves. My sense is that this degradation gained pace as we diversified the number of destinations that documentation could live: the wiki, Discourse, Github, Launchpad, etc.

The Ubuntu Community team have made significant efforts over the past months to centralise some of the documentation surrounding [membership](https://ubuntu.com/community/membership), [code of conduct](https://ubuntu.com/community/ethos/code-of-conduct) and project [governance](https://ubuntu.com/community/governance). I also called out the renewed [Stable Release Update (SRU) Team](https://documentation.ubuntu.com/sru/en/latest/) documentation in my first post.

All of this shows that we have all the skills we need to write *excellent* documentation, and I intend to put some focus on this over the coming months, consolidating much of this content and making it as searchable and accessible as possible.

In doing this work, I hope to:
- Create clear journeys for new contributors
- Create resilience in the project - reduce the "[bus factor](https://en.wikipedia.org/wiki/Bus_factor)"
- Increase the accessibility and ergonomics of our documentation
- Enable more efficient, asynchronous collaboration on a wide range of tasks

## End Goal

To quote the [Canonical.com](https://canonical.com/documentation) page on Documentation Practice:

> we have embarked on a comprehensive, long-term project to transform documentation. Our aim is to create and maintain documentation product and practice that will represent a standard of excellence. We want documentation to be the best it possibly can be.

At the heart of our documentation is [Diátaxis](https://diataxis.fr/): a way of thinking about documentation. Diátaxis "prescribes approaches to content, architecture and form that emerge from a systematic approach to understanding the needs of documentation users".

You'll have seen Diátaxis in use across many of our product documentation pages: the [Juju docs](https://documentation.ubuntu.com/juju/3.6/), the [MAAS docs](https://maas.io/docs), the [Pebble docs](https://documentation.ubuntu.com/pebble/), the [Rockcraft docs](https://documentation.ubuntu.com/rockcraft/en/latest/) and many more.

Most of those existing sites are quite specific - they document a particular product or ecosystem which neatly scopes the documentation structure, but the Diátaxis framework can still be used to bring structure, precision and clarity to the documentation of the Ubuntu project as a whole.

Earlier this month I surveyed the various documentation sites in use by Canonical and the Ubuntu Community, and settled on three common themes around which we can structure our documentation:

- **Governance**: in which membership, code of conduct, team structures, communication practices, delegation, mission, software licensing and 3rd-party software guidelines might be documented.
- **Develop Ubuntu**: documentation for current and aspiring Ubuntu developers, including how to package software for Ubuntu, how to merge packages from Debian, how to sponsor packages, use `git-ubuntu` and conduct "[+1 Maintenance](https://wiki.ubuntu.com/PlusOneMaintenanceTeam)".
- **Archive Administration**: the nuts and bolts of managing Ubuntu's prolific software repositories: how to manage seeds, configure phased updates, conduct a Main Inclusion Review, run an SRU process, etc.

These categories were not necessarily immediately obvious, and they're not necessarily mutually exclusive, but they fell out quite naturally when trying to logically organise our existing content.

During the process, I came up with this (very!) rough sketch:

[![an outline of how our Ubuntu Project documentation might be structured](01.png)](01.png)

On the left, you see how content from across multiple categories might come together in a single landing page. The three boxes to the right illustrate an example of how existing content might be broken down into Explanation, How-to and Reference material, and then again by category.

This may not be the final structure, but it's indicative of how we can use Diátaxis to break down large documentation premises into smaller, more digestible and more ergonomic pieces.

## The Plan

During the Ubuntu 25.10 cycle, we'll be dedicating two of our Technical Authors to making this happen. One of these authors has been largely responsible for the huge overhaul in the [Ubuntu Server docs](https://documentation.ubuntu.com/server/), but both are very familiar with Diátaxis and the tooling we're using to deliver Documentation.

Throughout this process, I've no doubt that we'll come across out of date, poorly reviewed or incorrect documentation, but as we work through the process of consolidating, we can note where this has happened and get it on our backlog to fix.

Perhaps we'll find items which fit the [Canonical Open Documentation Academy](https://canonical.com/documentation/open-documentation-academy), or perhaps we'll need to reach out to some of our less active community members for clarification, but once the structure is in place, we'll have a place to collaborate.

Once the transition is complete, there will be an authoritative source for documentation, one that is easy to navigate, easy to contribute to and with a well-defined review process that encourages progress over gatekeeping.

## Summary

Documentation is the backbone of a thriving open-source community, guiding contributors, setting expectations, and ensuring long-term sustainability.

While Ubuntu has extensive documentation, much of it is scattered, outdated, or difficult to navigate. By leveraging the Diátaxis framework, we aim to bring structure, clarity, and accessibility to Ubuntu Project Documentation. Our focus will be on governance, development, and archive administration, ensuring that key processes and responsibilities are well-documented and easy to follow.

With dedicated technical authors and community collaboration, the Ubuntu 25.10 cycle will mark a significant step toward making our documentation searchable, structured, and sustainable.

I hope this effort will empower contributors, reduce reliance on institutional knowledge, and create a more resilient project for the next generation of Ubuntu developers and users.
