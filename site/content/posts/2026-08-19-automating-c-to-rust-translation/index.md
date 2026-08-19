---
title: "Investing in automated C to Rust translation"
summary: |
  Canonical is funding a 3-year PhD at the University of Bristol to investigate whether large, mature C codebases can be translated into safe, correct and maintainable Rust.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Rust
  - University of Bristol
  - Memory Safety
  - LLMs
  - AI
layout: post
cover: cover.jpg
coverAlt: |
  An aerial photo of the Wills Tower and surrounding buildings
  in Bristol, UK.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/investing-in-automated-c-to-rust-translation/86369), and is reposted here. I welcome comments and further discussion in that thread.

I have written before about the role that Rust will play in Ubuntu's future. The case for Rust in 2026 is clear: it gives systems programmers more ergonomic control over performance and resource use while eliminating many classes of memory-safety defects, making it especially useful for software operating at important security boundaries.

The harder question is what to do about the enormous amount of mature C code that already exists? Rewrites have long been expensive and risky, and do not often materialise obvious improvements. Established codebases often contain years of bug fixes, compatibility decisions, operational knowledge and hard-won performance optimisations.

Our approach to modernisation in Ubuntu has been forward-looking, but pragmatic. The new technologies we've adopted have earned their place in Ubuntu. The [uutils coreutils](https://uutils.org/coreutils/) project and [sudo-rs](https://github.com/trifectatechfoundation/sudo-rs) are both established projects with mature test suites and committed maintainers and communities. If we want more systems software to benefit from memory safety, we need better ways to reduce the cost and risk of migration.

That is the problem behind a new research partnership between Canonical and the University of Bristol in the UK.

## Project Goals

Canonical is funding a 3-year PhD project, with matched support from [UK Research and Innovation](https://www.ukri.org/), to investigate increasing the rigour of automated C to Rust translations. The project will be led in Bristol by [Professor Meng Wang](https://www.bristol.ac.uk/people/person/Meng-Wang-c7e34d58-549c-4456-ad41-8392dab75a91/), with [Dr Cristina David](https://www.bristol.ac.uk/people/person/Cristina-David-d78c4612-1820-443c-b2cb-9db853867d90/) and myself as co-supervisors.

The goal is to build an end-to-end platform capable of translating repositories comprising hundreds of thousands of lines of C to safe, behaviourally correct and maintainable Rust.

Traditional source-to-source translators can process substantial amounts of code, but often preserve the structure of the C too literally. The result may compile as Rust, but still rely heavily on unsafe operations, retain awkward C idioms and require significant manual work before it resembles code a Rust maintainer would choose to own.

Large language models have almost the opposite characteristics. They can produce convincing, idiomatic Rust for small and well-defined examples, but they struggle with repository-scale context. More importantly, plausible-looking output is not evidence that the translated program behaves like its source.

## A neurosymbolic approach

The project will combine machine-learning techniques with conventional program analysis, testing and formal methods. The proposed architecture has four main parts.

**Scheduling** will divide a large repository into chunks that can be translated independently, without losing the context required to understand types, dependencies and behaviour. This is more involved than splitting a project by file or function. The order and boundaries of translation affect how much the system can infer and what it can subsequently validate.

**Translation** will use language models trained or fine-tuned against a library of known C-to-Rust translations. The aim is to produce Rust that expresses the intent of the original program using appropriate Rust abstractions, rather than mechanically reproducing C syntax.

**Validation** will check that the Rust implementation behaves like the C source. The project will explore fuzz testing alongside more formal approaches to equivalence checking.

**Debugging and repair** will analyse failed validations, locate likely translation faults and attempt targeted corrections using symbolic program-repair techniques.

Here the language model is only one component in the system. Generated code should be treated as untrusted until there is evidence that it preserves the desired behaviour. This is the same principle I apply to agentic software development more generally: generation is useful, but it needs to sit inside a system of constraints, feedback and verification.

## Applying the research to Ubuntu

Research into code translation can look successful when evaluated only against small programs or carefully selected benchmarks. Real repositories are less accommodating.

Long standing repositories often accumulate build-system complexity, platform-specific behaviour, unusual error paths and assumptions that may not be obvious from an individual function. Security-sensitive software also tends to contain exactly the low-level operations that are hardest to translate cleanly.

As part of the collaboration between Canonical and the University of Bristol, the project will target AppArmor and snap-confine as industrial case studies. Both are critical to Ubuntu’s security posture, and provide a substantially harder test than isolated translation examples. They will help us evaluate whether the techniques can cope with the structure and constraints of mature production software.

Note that this is not a commitment to replace AppArmor or snap-confine with what is generated, rather that we have a vested interest in the software and are keen to see the results.

## Why this belongs in a PhD

One could view automated code migration as a software engineering problem that could be solved by a traditional engineering team: connect an LLM to a compiler, add a test loop and keep iterating until the output builds, but it would be easy to miss nuance or accidentally encode project specificities by taking such an approach.

How should a repository be partitioned without losing semantic context? How can the system establish equivalence when the source contains undefined or implementation-dependent behaviour? How should it handle pointer-heavy APIs, concurrency, foreign interfaces and operating-system boundaries? When validation fails, how can it distinguish a translation defect from an ambiguity in the original program?

These problems span programming languages, formal methods, machine learning and software engineering. The University of Bristol has a strong [programming-languages research group](https://plrg-bristol.github.io/), and this collaboration facilitates access to practical case studies from Ubuntu. Canonical, in turn, benefits from research that is informed by the constraints of real systems software rather than an idealised model of it.

The selected student, Alex Wood, is well placed to work across those boundaries. His background includes compiler construction, functional programming, Rust, low-level security work and cryptographic protocol implementation.

## Summary

The most optimistic outcome would be a system capable of translating substantial C repositories into Rust with strong evidence of behavioural equivalence and relatively little manual intervention. The research could also produce better methods for decomposing repositories, stronger validation techniques, reusable translation datasets, improved program-repair tools and a more precise understanding of where automated migration stops being reliable.

Rust is not an objective in itself, but it continues to be a compelling and interesting language for systems programming, and its compiler infrastructure and borrow checker lends itself to verification.

Work is set to begin later this year, and I look forward to keeping you all up to date on what we find!  