---
title: "If it hurts, do it more!"
summary: |
  The phrase "if it hurts, do it more often" has bee applied variously to software
  teams and processes in the last fifteen years, and is a means to improve team
  processes and efficiency, but must be wielded carefully!

  This post covers my application of, and experience with this idea during my time
  leading Ubuntu Engineering and Charm Engineering at Canonical.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Leadership
  - Management
  - Process
layout: post
cover: cover.webp
coverAlt: |
  An abstract photograph of a maze nestled within some rolling, green
  hills.
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/if-it-hurts-do-it-more/88163), and is reposted here. I welcome comments and further discussion in that thread.

I'm often asked about my leadership style. A recent interview for Canonical’s leadership development programme prompted me to reflect on the patterns I've used across Charm and Ubuntu Engineering at Canonical over the past 5 years.

I've [worked on two](https://jnsgr.uk/cv) large, but ultimately very different engineering organisations in my time at Canonical, and in both cases, many of the changes I made were guided by first identifying what was most difficult, or most awkward for my teams, then making them do it more!

This post walks through some of the reasoning, and examples of where this pattern can be effectively applied. It runs the risk of making me sound like a masochist, but I have found the approach to be effective in tackling all kinds of organisational issues.

## Background

The phrase "if it hurts, do it more often" is not new, and not my idea. It was previously popular in discussions around continuous delivery and agile/XP methodologies, and expanded upon by the likes of [Kent Beck](https://kentbeck.com/), [Martin Fowler](https://martinfowler.com/) and [Jez Humble](https://www.linkedin.com/in/jez-humble/).

The core idea is simple: if something is worth doing, but your team finds it difficult, ask them to do it more often. The aim is to build confidence and muscle memory in your team, and to improve the processes and automation that support their work.

There is a key question you must answer before applying this technique: is the *painful thing* worth doing?

This approach can be a fast path to burnout and resignations if you're unable to articulate why the *painful thing* is necessary in the first place. If painful tasks or processes can instead be eliminated with a bit of lateral thinking, do that! You must also make space for change. Your team likely hasn't fallen behind on *painful things* on purpose: they may need training, better tools or simply fewer competing priorities to progress.

It's important to show data that highlights the issue you're trying to solve. I’ll use the rest of the article to walk through some specific examples.

## Releasing Software

Software teams that don't release software are broken software teams. One of the first things I changed in Ubuntu Engineering was asking the team to commit to [monthly snapshot releases](https://jnsgr.uk/2025/05/supercharging-ubuntu-releases/).

This was not the first time I'd used release cadence as a means to improve team processes. Back in 2021, I asked the Juju team to commit to fortnightly releases following a period of no releases for months, despite significant feature work on their Kubernetes operator mechanics.

On both occasions, the suggestion caused some anxiety. So why is it so important for teams to release frequently?

Infrequent releases allow both change and uncertainty to accumulate between releases, increasing the chance that an upgrade will cause issues for your users. Longer gaps between releases also make new releases harder to qualify and harder to troubleshoot due to the volume of changes.

When there are no releases, the line between "merged" and "done" starts to blur. Without getting drawn into a discussion about Definition of Done: should you call an item done if it's not released and being used by real users? Personally, I don't think so.

But perhaps most obviously, when you don't release often, your team gets worse at releasing. Knowledge typically ends up centralised on a couple of people, laborious manual processes tend to stay laborious and manual (and therefore error-prone), and flaky tests tend to wreak havoc because no one knows whether or not to take test failures seriously (and when tests are flaky, people usually don't).

A regular release cadence exposes laborious manual steps, missing documentation and unreliable tests that add friction to the team's processes. Releasing also gets your software into users' hands sooner, creating a tighter feedback loop for your team. While this can sometimes be painful, it's also the best signal you'll get on whether you're doing good work, or at least work that is relevant to your users.

## Hiring

When I took over Ubuntu Engineering, the team was shrinking: we were hiring fewer people than we were losing. Today, it is the fastest-growing department in Canonical. There are a few reasons for that, but our success is largely down to the focus and repetition we've brought to the process.

Hiring is hard. We get a *lot* of applications, and [we look at every single one of them](https://canonical.com/careers/hiring-process). We were getting plenty of applications for our Ubuntu Engineering team, but rejecting candidates because their skills didn't precisely match our own - and therein lay the problem!

The improvement in hiring is down to two key factors: the first was an insistence that everyone plays their part. Review more CVs, do more interviews and have more discussions - build muscle memory!

The second was education and training. We were rejecting too many candidates, and for a while I asked that no candidate was rejected from the process outright until we had discussed the candidate among the hiring team, which created a lot of extra work to begin with, but helped to create a shared view on how to analyse applications and identify the right signals.

Despite the temporarily high workload, this ultimately enabled the team to hire *many* more people over the coming months.

Not many engineers I've met *love* doing interviews, but what I've observed over the past two years suggests that with some training and repetition, it's a skill that can be learned just like anything else. Making a call about a potential candidate's suitability is much harder if you do one interview a quarter than if you do two interviews a week…

## Performance Management

Another famously popular topic! As a leader, performance conversations should be part of your everyday work, both to celebrate successes and to clarify where your expectations were not met.

None of this is easy, and to compound the issue very few leaders in the software industry are given any formal training or guidance on the topic. Often these conversations only happen when a senior leader pushes someone to have them.

Performance management is often associated with something going wrong, but it *should* be a continuous process, conducted in regular one-to-one meetings where short-, medium- and long-term goals are set and assessed, feedback is given (both ways!) and issues are addressed proactively.

More often than not, lots of this is omitted, and people are often surprised to find themselves on a performance improvement plan (PIP), which is painful for all parties involved, and can frequently be avoided with a more proactive approach.

For that proactive approach to work, leaders must discuss performance and expectations regularly with their teams, and address issues head-on as they arise. Doing so empathetically can build a very healthy feedback culture, despite initially feeling uncomfortable for many.

## Communication

Communication is a bit harder to measure (in delivery terms) than the previous topics, but I'd argue that it is a foundational skill which underpins your ability to effect change in releasing, hiring, performance management or anything else.

### Build exposure through writing

One of the [four pillars](https://jnsgr.uk/2025/02/engineering-ubuntu-for-the-next-20-years/) I set out to improve when I took on Ubuntu was Communication, and specifically our written communication about the work we're doing and the plans we're making.

I started by mandating that a post was published on Discourse every week from Ubuntu Engineering. This is still in place today, and rotates between me, the Desktop, Foundations, Server and Debcrafters teams. For many people, writing for a large audience can be intimidating - the combination of impostor syndrome and the internet's growing hostility is likely to blame here.

I've been a regular consumer of tech blogs since my high school days, yet it took me until 2023 to start my own. The first post was hard, but I committed in the first year to one post per month, and found they got easier and easier to write. It wasn't that I was working on anything more interesting or more "worthy", rather that I built muscle memory around writing, and found my tone and style as I went along.

I've found the process very rewarding. I now post about every six weeks, but I've had really interesting online conversations, and even in-person meetings off the back of blog posts, and I've noticed that people in Ubuntu Engineering and Charm Engineering are starting to post their own work more (in addition to the schedule I imposed). This feels like a great achievement, and I really hope others follow suit.

The practice of articulating your work publicly can lead to realisations (both good and bad) about the work you may not yet have had. Software Engineers often refer to the practice of [Rubber Duck Debugging](https://rubberduckdebugging.com/), and writing can yield a similar effect. Writing can build trust and understanding with your users, whether they're an open source community or otherwise. It gives people the inside track on your thinking and helps them understand the evolution of the products and projects they love.

### Speak for your audience

All of this applies to speaking, too. I'm always delighted to hear that someone is giving their first lightning talk or conference talk. If writing for the public is scary, speaking in public can be terrifying - but it can be learned, and even enjoyed!

Team leads can assist with this by making short, informal demos from every team member a non-negotiable part of every sprint. These do *not* need to be polished slideware with glossy video demos, and should emphasise a more ad-hoc explanation or guided walkthrough of the individual's (and therefore the team's) work.

You should feel safe and comfortable enough to talk through what you're working on with a colleague without undue preparation - knowing that it won’t be perfect. It doesn't matter if you're working on a design doc, improving some unit tests, refactoring some code, polishing technical documentation or brainstorming a new idea: presenting your thinking can help you to solidify the ideas in your own mind and open the door for feedback.

In more personal, one-to-one style interactions, it's equally important to build confidence in your ability to clearly articulate your point of view. This is important for technical conversations, where clarity and precision can help illuminate a complex design or technical topic, but it's critically important in conversations surrounding people's behaviour or performance. Waffling or imprecision in these situations can confuse people, and leave them without a sense of how to improve, or even where they went wrong.

Both situations require a careful balance between sincerity and empathy, but in different measures. I found [Radical Candor](https://www.radicalcandor.com/) to be an interesting way to frame difficult communications, particularly in the one-to-one context.

## Summary

The mantra "If it hurts, do it more" can ring a little like "the beatings will continue until morale improves", but that's not it!

The aim is to bring important work back into focus and make it routine. Increasing the frequency of this work can help, provided the team also gets time to learn and the support they need along the way. It's normal to experience some failure early on.