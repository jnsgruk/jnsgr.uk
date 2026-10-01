---
title: "Write it yourself"
summary: |
  Gathering my thoughts on the use of LLMs for writing
  prose, and how I've changed my workflow following
  some feedback and reflection on my own writing.
tags:
  - Blog
  - Leadership
  - Process
  - LLMs
  - AI
  - Writing
layout: post
cover: cover.webp
coverAlt: |
  A low colour image of a vintage typewriter.
---

Recently, I've been thinking a lot about how I use LLMs, particularly for writing and reviewing prose.

I continue to be impressed with the range of tasks that both open-weight and frontier lab models can tackle. I still get excited when I figure out a new way to give a model a feedback loop for something in the real world. I was recently troubleshooting a small IoT device that needed some firmware modifications (more on that in a later post!). I was able to hook up serial console access and flashing to a machine running an agent, teach the agent how to toggle the device's power using a smart plug, then watch (grinning) while the agent iterated through firmware revisions and solved the problem.

The flip side of all this excitement is that I'm experiencing a noticeable increase in my own irritation when reading LLM-generated prose. I was fortunate enough to have dinner with [Bryan Cantrill](https://bcantrill.dtrace.org/about/) and a few others at RustConf 2026 where he described being able to "spot LLM writing from space" - something I increasingly identify with. Bryan recently wrote [the revolt of the reader](https://bcantrill.dtrace.org/2026/09/05/the-revolt-of-the-reader/), which accurately describes the feelings I experience when reading generated content.

## What I've tried

I've worked LLMs into my writing flow in a few different ways. I've had them draft blog posts and internal newsletters, I've had them review documents for me and I've used them to grok larger documents more quickly. They have become staggeringly good at comprehension and at correlating concepts across a huge range of topics and sources.

While I've never posted content that's come straight from an LLM, I have used LLMs to generate prose, spent time reviewing and then posted it. There are two such posts on this website, and looking back they're the posts I'm least proud of. I'm not going to remove them, because they serve as a (somewhat public!) reminder for me.

I find that an LLM's writing, even when heavily guided by reference material and edited, never sounds like me. LLMs don't structure sentences like I do, and they aren't able to accurately reproduce my tone. LLMs tend to be overly sycophantic and positive in most statements, whether those statements are an appraisal of a technology, a decision or a piece of work.

## A smoking gun

At work I write a monthly newsletter on our internal Discourse which comprises a short foreword by me, a welcome to any new starters that month, some recognition for people who have done unusually excellent things and a digest of product releases and relevant happenings across the organisation. My process for authoring these newsletters is to collect links to releases, projects and interesting articles in a dedicated [Todoist](https://www.todoist.com/) list throughout the month, then write a few sentences about each at the end of the month, and publish the newsletter.

A few months ago, I built [newsagent](https://github.com/jnsgruk/newsagent) as a piece of automation to help with this. The process uses `newsagent` in combination with my [Hermes](https://hermes-agent.org/) agent, and looks like this:

- Render a basic template for the newsletter with regular items/headings
- Read the items from my Todoist lists
- Draft the description of the item in my preferred format
- Compare the generated prose with that of my previous editions
- Insert names of people who recently joined my organisation

My hope was that feeding my existing content in as a sort of "style guide" would keep the tone and feel of the newsletter on track, but it hasn't. I've made multiple changes to the prompt to try and hone this, but with limited success. 

My last 3-4 newsletters have been drafted this way, but again I'm not proud of them. One of my colleagues noted in a recent round of 360 appraisals that he'd spotted this, and was enjoying them less, observing that they convey less of my voice and opinion than they did. I'm simultaneously very grateful for the feedback, and a bit embarrassed. I put quite a lot of effort into editing these posts, yet still I had missed the fact that the writing was "off".

## How I'm changing my approach

LLMs *are* excellent editors and reviewers of prose, and I still plan to use them heavily for this. They're good at spotting opaque references, poor sentence structure, repetition, and accidental tone variation. I tend to run most of my writing through a couple of different models (usually using good old copy and paste into a browser), then pick and choose the feedback I'd like to actually apply.

I think LLMs are helpful when formulating an article or a spec, but the workflow I'm increasingly using is to have different models generate whatever it is I'm going to write wholesale, read the output, then immediately discard it. LLMs have a nice habit of finding an angle I hadn't considered, or linking what I'm doing to a previous piece of my own work, or a trend they've observed elsewhere, and I think that's valuable. What isn't valuable is the actual prose it generates, so I'll read it, understand it, then chuck it away and write it myself (without referring to the generated prose!). This way, I'm using the LLM as an aid to challenge or guide my thinking, but not to supply the words or structure of what I'm writing.

This is similar to how I prototype software with (and without) LLMs. If I'm at a crossroads on how to progress, perhaps considering 2-3 different options, I'll have an agent create three different prototypes with absolutely no care and attention paid to the code or structure. I'll play with the prototypes, gather my thoughts, then `rm -rf` the lot and articulate what I actually want for my project, and subject the output to much stronger review.

In my most recent internal newsletters, I used `newsagent` in a different way. I [adjusted its prompt](https://github.com/jnsgruk/newsagent/commit/1f39dc462e198516c216daf5d04beedbe6a01524) to draft the headings, and rather than generate prose, insert a couple of short bullets for each item. It takes care of writing the Markdown links, grabs some key points from the links I've gathered, but still requires me to click through, verify the summaries and then write the prose. The wider automation with my Hermes agent still helps me by grabbing the names of people who have recently started at Canonical, which is otherwise manual click-ops work, but now it just inserts their names, levels and teams, leaving me to actually write something about them.

## Why I think this is so important

In my most recent blog, [If it hurts, do it more](https://jnsgr.uk/2026/09/if-it-hurts-do-it-more/), I wrote about the importance of writing. It was while authoring this post (without AI assistance, I might add) that I started to crystallise the arguments I'm making in this post. 

Even if you're *100% all-in on AI*, it's hard not to concede that the biggest successes with these tools often result from detailed and well-specified designs. In an age where the (human time) cost of programming is going down fast, it is more important than ever to stop and think about what you want to build and why, who you're building it for and how. 

I hear people joking that "all software engineers are managers" now, referring to the increasing trend in the industry of engineers spending all day managing a team of agents, and they're not wrong! But the key to success in managing that team of agents is still going to be the ability to communicate clearly and concisely what needs to be done. Our human engineers still have managers too, and your engineers won't thank you for having your agent respond to their emails and Slack messages with replies full of clichés and staccato sentences. That's not management — it's careless delegation (see what I did there ;-)).

I find writing a design document (or explaining an idea in prose) one of the most effective ways to improve my own understanding. I appreciate this doesn't work for everyone, and perhaps you prefer diagrams, or talking through your ideas verbally, but the principle still stands - an agent can't help you if you can't articulate what you want, and why.

## Summary

I've thought at some length about whether my aversion to reading LLM-generated content comes from a heightened use of agents compared with the average person. Like many of us in software, I spend a *lot* of time each day reading the (often tedious) output tokens that have been ~crafted~ spewed out in response to one of my requests - so perhaps I'm overly sensitive. That won't last long, though. I'm sure you've been subjected to the same endless stream of AI-generated LinkedIn posts and so-called news articles that I have, so it won't be long before those further from the tech start to feel the pain too.

As LLMs continue to evolve, perhaps their ability to write less predictable and tedious prose will improve, but even if it does I think I'll abstain. The more I think about how work will evolve in the coming years, and how we might partner with this new fleet of automated colleagues, the more I think the ability to form, write or speak a well-articulated opinion will be critical, and the fastest way to lose that skill is to stop doing it.

For me, I think this means not using LLMs to draft content at all. The problem isn't limited to words or phrasing, but extends to the structure and approach of the writing, and I've found that those harder to catch in review, as evidenced by the feedback I've received.

I think the most fitting summary here is that if you have something you think is worth saying, then do yourself and your friends and colleagues a favour by saying it yourself.