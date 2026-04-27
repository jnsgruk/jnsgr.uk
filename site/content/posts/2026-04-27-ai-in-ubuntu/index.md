---
title: "The future of AI in Ubuntu"
summary: |
  AI tools are becoming ubiquitous. Adoption across the
  tech industry has been mixed, both in terms of which
  projects are embracing "AI" technologies, and in how companies
  are structuring their adoption

  This post details how AI will play a part in both Canonical
  and Ubuntu's future, my framework for classifying AI features
  in the OS, and how Canonical is currently approaching adoption
  internally.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
  - AI
  - Inference
  - LLMs
layout: post
cover: cover.jpg
coverAlt: |
  Abstract purple "starburst" graphic.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/the-future-of-ai-in-ubuntu/81130), and is reposted here. I welcome comments and further discussion in that thread.

### Introduction

As 2026 progresses, LLM-based tools are becoming more and more ubiquitous. Adoption across the tech industry has been mixed, both in terms of which projects are embracing "AI" technologies, and in how companies are structuring their adoption. As a result, I'm frequently asked about what Canonical and Ubuntu will do (or not) to incorporate AI.

In this post I'll detail how AI will play a part in both Canonical and Ubuntu's future, my framework for classifying AI features in the OS, and how Canonical is currently approaching adoption internally, because I think that will help paint a picture of our intent.

The bottom line is that Canonical is ramping up its use of AI tools in a focused and principled manner that favours open weight models with license terms that feel most compatible with our values, combined with open source harnesses. AI features will be landing in Ubuntu throughout the next year as we feel that they're of sufficient maturity and quality, with a bias toward local inference by default. 

AI features in Ubuntu features will come in two forms: first as a means of enhancing existing OS functionality with AI models in the background, and latterly in the form of "AI native" features and workflows for those who want them.

### AI Adoption at Canonical

This year Canonical has begun a more deliberate push toward education and developing competence with AI tools. We are not setting shallow metrics on token usage, or percentages of code written with AI, but rather incentivising engineers to experiment and understand where AI tools add value. Rather than force a single early-choice AI stack, we’re incentivising teams to each pick ‘something different’ and go deep, so we learn more as an org in the next six months.

There are certain tasks for which AI tools are a no-brainer. In these cases, AI tools can work autonomously and produce excellent results \- particularly where the work is of a mechanical nature and they're given the right context. In other cases, they struggle. My hope is that over the coming months, all of our engineers grow to feel competent and fluid while driving the full range of AI tools: using them where they’re effective, and avoiding them where they’re not.

I will not be measuring people at Canonical by how *much they use AI*, but rather continue to measure them on *how well they deliver*. AI is not going to take software engineering jobs at Canonical, but other software engineers who are highly competent with AI tools certainly could. Using AI for its own sake is not a constructive goal for anything but increasing exposure, and it rarely yields good results in production code. Used where it’s well-optimised, and in ways that can be controlled and reviewed, it can be highly effective. I've seen AI used to great effect as an educational aid, to accelerate development tasks, to create immersive prototypes as a design aid, and to help with tricky or monotonous troubleshooting.

### Treading carefully

Responsibility and transparency are at the core of our approach. Many of you will have read reports of "[slop](https://en.wikipedia.org/wiki/AI_slop)" pull requests and contributions that have been flung at open source projects with little care, consideration or thought. This has never been an acceptable way to contribute, and is absolutely not what is being encouraged at Canonical.

There is also growing concern that over-reliance on these tools could hinder people's ability to learn new concepts. This is possible, and perhaps even more so than when the same point was made about StackOverflow a few years ago, but I think it comes down to team culture and expectations. In my experience, I've found LLMs to be an excellent learning tool. We'll need to help our colleagues and open source contributors develop good instincts by training them to be skeptical and not blindly trust what comes out of the machine, and to help them understand where LLMs are both most powerful and most limited.

Organisations also now have an additional set of tools and vendors to audit. Depending on your industry and customer base, there may be limitations on which models and tools can be used (if any at this point) but that's where access to local, offline inference and bespoke tools for LLMs to call could be invaluable.

I also acknowledge that “open source” can be a loaded term in the context of LLMs. Access to model weights is meaningful, but it is not equivalent to the sort of transparency the open source community has become accustomed to. When we select models to make available in Ubuntu, we'll try to take a balanced view on the *terms* of the model license, not just whether the weights are open. From an Ubuntu perspective, our bias will be toward local inference, open source harnesses and models with licensing terms that are compatible with our values, with clearly defined interfaces to external services where people require them.

Given the rate of adoption, we are likely to continue seeing questionable use for some time. Part of our role as long-standing members of the open source community is to stay at the forefront of what can be achieved with AI tools, then lead by example. We should be demonstrating what can be achieved through responsible and thoughtful use, and guiding new contributors toward better practices that will see them using these tools to amazing effect, and contributing to the next wave of open source for years to come.

### Implicit vs. explicit AI features

Over the past few weeks I've begun to develop a framework to help think about different kinds of AI adoption within Ubuntu. At the centre of that is the idea of *explicit* and *implicit* AI features.

Implicit AI is about enhancing existing operating system features with the use of AI, without introducing new mental models for users. One exciting example of this is bringing first-class speech-to-text and text-to-speech to Ubuntu. I don't see these as "AI features", I see them as critical accessibility features that can be dramatically improved through the adoption of LLMs with minimal (if any) drawbacks. Much of this can be achieved with local inference using open source harnesses and open weight models, which are both accurate and efficient for this use case.

Explicit AI features are those which are more obviously AI-centric, and could include more "agentic" workflows. This could be for authoring new documents or applications, automating troubleshooting workflows or even personal automation tasks such as targeted daily news briefings. With this comes a big responsibility for us to ensure that the relevant security and confinement controls are in place to prevent unwanted side-effects.

Implicit AI features will improve what Ubuntu already does; explicit AI will be introduced as new features.

### Access to local inference

I've written about [inference snaps](https://jnsgr.uk/2026/01/developing-with-ai-on-ubuntu/#inference-snaps) in the past (and [presented](https://www.youtube.com/watch?v=0CYm-KCw7yY) more detail at a recent [AI Native Dev](https://ainativedev.io/) meetup), but the bottom line is that inference snaps provide simplified local access to inference with models that have been specifically optimised for your hardware. The combination of Ubuntu's widespread adoption and Canonical's partnership with silicon companies has enabled us to deliver a high performance foundational inference capability for the distribution with very little cognitive overhead for our users. It’s easier to `snap install nemotron-3-nano` than juggle Ollama, Huggingface and a sea of model quantisations, and the snap will give you the optimised bits for your particular silicon if that silicon company has contributed them.

Inference snaps are subjected to the same [confinement](https://snapcraft.io/docs/explanation/security/snap-confinement/) rules as other snaps, which should give users the confidence that the models do not have indiscriminate access to their machines or data.

Previously, to benefit from the full power of LLMs, you had to skew to higher parameter models. Recent developments in models like [Gemma 4](https://deepmind.google/models/gemma/gemma-4/) and [Qwen-3.6-35B-A3B](https://qwen.ai/blog?id=qwen3.6-35b-a3b) demonstrate advanced capabilities such as tool-calling which enable LLMs to search the web, interact with external APIs and file systems, troubleshoot live systems and fundamentally reason about topics that lie outside of their initial training data.

What comes next for inference snaps is scaling: we'll be ramping up our teams to make sure we keep up with the latest model releases, and increasing the number of optimised variants for as many silicon platforms as possible.

### Context-aware operating system

Beyond features like text-to-speech or enhanced screen reading, users are becoming increasingly accustomed to working with agents. I love the idea that all the power and capability that Linux has acquired over the past few years could become more accessible to more people.

We're making plans on how to integrate agentic workflows into Ubuntu for those who want it in a way that feels tasteful, aligned with our user base and respectful of our privacy and security values. What's clear even at this early stage is that the investments we've made into confined packaging with Snaps, and some of the consolidation we've done of core system functions into Ubuntu will really help us deliver on this goal safely.

The Linux desktop ecosystem is famously fragmented, and in some ways that fragmentation has contributed to its success. Over the years, many smart people have been motivated to scratch an itch, and built excellent software to do so, but integrating all those parts has always been the challenge and this can lead to a frustrating experience for some users. If we're careful about how we employ LLMs in a system context, they could demystify the capabilities of a modern Linux workstation and bring them to a much wider audience.

But why limit this to the desktop? If you're an [Site Reliability Engineer (SRE)](https://en.wikipedia.org/wiki/Site_reliability_engineering) administering a fleet of Ubuntu machines, there are countless ways in which an LLM might help, whether it's interpreting logs during an incident to speed up root cause analysis, or performing a series of scheduled maintenance tasks with strict guard rails. I'd like to build a capability that feels at home on *any* Ubuntu machine with the right interface for the type of machine.

Delegating elements of Site Reliability Engineering to an agent does not necessarily introduce an entirely new class of risk; it should inherit the constraints of existing production systems. Well-run production environments already rely on strict access controls, audit trails, and clear separation between observation and action. My aim is for Ubuntu to expose the primitives needed for agents to operate within existing boundaries, whether that be read-only analysis, tightly scoped permissions for any actions, and full auditability of decisions and outcomes. In that sense, the challenge is less about “trusting the agents”, and more about building trust in the same guardrails we already apply to any production system.

Imagine being able to ask your Linux machine to troubleshoot a Wi-Fi connection issue, or to stand up an open source software forge that's pre-configured, secured, and reachable over TLS. One could easily imagine using such a capability as a gateway for controlling your Linux machine from other devices through a variety of mediums \- be that a mobile app, text messaging, voice commands or otherwise.

### Efficiency and performance

Access to local inference is somewhat tied to access to capable hardware. We're doing our best to make it easy to consume open weight models on commodity hardware, but these smaller parameter models can't yet compete with the larger models for many tasks. I see this as a mostly temporary issue. There will always be bigger models and smaller models, and those with more compute will be able to get more done than those with less compute, but the gap will begin to close.

Silicon manufacturers around the world are heads-down building consumer-grade silicon with ever-improving inference capabilities, and what today seems like it's only possible with access to a frontier AI factory will become significantly more accessible in the coming months and years.

We must consider both performance and efficiency in the conversation. It's easy to compare tokens per second on a large model in the cloud with what you see on your local machine, but the advantage of native accelerators for these workloads is that the power draw will also fall dramatically \- which again lowers the bar to entry. We're not going to get there overnight, but I'd like Ubuntu to be ready when we *are* there, and our [silicon partnerships](https://canonical.com/partners/silicon) and enablement initiatives play an increasingly important role in making that a reality.

### Summary

Throughout 2026 we'll be working on enabling access to frontier AI for Ubuntu users in a way that is deliberate,  secure, and aligned with our open source values. By focusing on the combination of education for our engineers, our existing knowledge of building resilient systems and our strengthening silicon partnerships, we will deliver efficient local inference, powerful accessibility features, and a context-aware OS that makes Ubuntu meaningfully more capable for the people who rely on it

Ubuntu is not becoming an AI product, but it can become stronger with thoughtful AI integration.