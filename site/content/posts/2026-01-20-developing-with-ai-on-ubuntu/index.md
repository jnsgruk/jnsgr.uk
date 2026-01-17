---
title: "Developing with AI on Ubuntu"
summary: |
  AI-assisted tooling is becoming more and more common in the workflows of engineers
  at all experience levels. As I see it, our challenge is one of consideration,
  enablement and constraint. 

  We must enable those who opt-in to safely and responsibly harness the power of
  these tools, while respecting those who do not wish to have their platform defined
  or overwhelmed by this class of software.
tags:
  - Ubuntu
  - Blog
  - Canonical
  - Linux
  - Security
  - AI
  - LLM
  - Agents
layout: post
cover: cover.jpg
coverAlt: |
  An abstract image of brain and neural connections
---

> This article was originally posted [on the Ubuntu Discourse](https://discourse.ubuntu.com/t/developing-with-ai-on-ubuntu/75299), and is reposted here. I welcome comments and further discussion in that thread.

AI-assisted tooling is becoming more and more common in the workflows of engineers at all experience levels. As I see it, our challenge is one of consideration, enablement and constraint. We must enable those who opt-in to safely and responsibly harness the power of these tools, while respecting those who do not wish to have their platform defined or overwhelmed by this class of software.

The use of AI is a divisive topic among the tech community. I find myself a little in both camps, somewhere between sceptic and advocate. While I'm quick to acknowledge the negative impacts that the use of LLMs _can have_ on open source projects, I'm also surrounded by examples where it has been used responsibly to great effect.

Examples of this include [Filippo](https://filippo.io)'s article [debugging low-level cryptography with Claude Code](https://words.filippo.io/claude-debugging/), [Mitchell](https://mitchellh.com)'s article on [Vibing a Non-Trivial Ghostty Feature](https://mitchellh.com/writing/non-trivial-vibing), and [David](https://github.com/crawshaw)'s article [How I Program with Agents](https://crawshaw.io/blog/programming-with-agents). These articles come from engineers with proven expertise in careful, precise software engineering, yet they share an important sentiment: AI-assisted tools can be a remarkable force-multiplier when used _in conjunction_ with their lived experience, but care must still be taken to avoid poor outcomes.

The aim of this post is not to convince you to use AI in your work, but rather to introduce the elements of Ubuntu that make it a first-class platform for safe, efficient experimentation and development. My goals for AI and Ubuntu are currently focused on enabling those who want to develop responsibly with AI tools, without negatively impacting the experience of those who'd prefer not to opt-in.

### Hardware & Drivers

AI-specific silicon is moving just as fast as AI software tooling, and without constant work to integrate drivers and userspace tools into Ubuntu, it would be impossible to efficiently utilise this specialised hardware.

Last year we announced that we will ship both [NVIDIA's CUDA](https://canonical.com/blog/canonical-announces-it-will-support-and-distribute-nvidia-cuda-in-ubuntu) and [AMD's ROCm](https://canonical.com/blog/canonical-amd-rocm-ai-ml-hpc-libraries) in the Ubuntu archive for Ubuntu 26.04 LTS, in addition to our previous work on [OpenVINO](https://snapcraft.io/publisher/openvino). This will make installing the latest drivers and toolkits easier and more secure, with no third-party software repositories. Distributing this software as part of Ubuntu enables us to be proactive in the delivery of security updates and the demonstration of provenance.

Our work is not limited to AMD and NVIDIA; we recently [announced](https://canonical.com/blog/ubuntu-ga-for-qualcomm-dragonwing) support for Qualcomm's [Dragonwing](https://www.qualcomm.com/dragonwing) platforms and others. You can read more about our silicon partner projects [on our website](https://canonical.com/partners/silicon).

### Inference Snaps

At the [Ubuntu Summit 25.10](https://ubuntu.com/summit), we [released](https://canonical.com/blog/canonical-releases-inference-snaps) "Inference Snaps" into the wild, which provide a hassle-free mechanism for obtaining the “famous model” you want to work with, but automatically receive a version of that model which is optimised for the silicon in your machine. This removes the need to spend hours on [HuggingFace](https://huggingface.co/) identifying the correct model to download that matches with your hardware, and obviates the need for in-depth understanding of model quantisation and tuning when getting started.

Each of our inference snaps provide a consistent experience: you need only learn the basics once, but can apply those skills to different models as they emerge, whether you're on a laptop or a server.

At the time of writing, we've published `beta` quality snaps for [qwen-vl](https://snapcraft.io/qwen-vl), [deepseek-r1](https://snapcraft.io/deepseek-r1) and [gemma3](https://snapcraft.io/gemma3). You can find a current list of snaps [in the documentation](https://documentation.ubuntu.com/inference-snaps/reference/snaps/), along with the silicon-optimised variants.

### Sandboxing Agents

While many start their journey in a web browser chatting to [ChatGPT](https://chat.com), [Claude](https://claude.ai), [Gemini](https://gemini.google.com/app), [Perplexity](https://perplexity.ai) or one of the myriad of alternatives, many developers will find "agentic" tools such as [Copilot](https://github.com/features/copilot), [Codex](https://openai.com/codex/), [Claude Code](https://claude.com/product/claude-code) or [Amp](https://ampcode.com/) quite attractive. In my experience, agents are a clear level-up in an LLM's capability for developers, but they can still make poor decisions and are generally safer to run in sandboxed environment at the time of writing.

Where a traditional chat-based AI tool responds reactively to user prompts within a single conversation, an agent operates (semi-)autonomously to pursue goals. It perceives its environment, plans, makes decisions and can call out to external tools and services to achieve those goals. If you grant permission, an agent can read and understand your code, implement features, troubleshoot bugs, optimise performance and many other tasks. The catch is that they often need _access to your system_ - whether that be to modify files or run commands.

Issues such as accidental file deletion, or the inclusion of a spurious (and potentially compromised) dependency are an inevitable failure mode of the current generation of agents due to how they're trained (see the [Reddit post](https://www.reddit.com/r/ClaudeAI/comments/1pgxckk/claude_cli_deleted_my_entire_home_directory_wiped/) about Claude Code deleting a user's home directory).

#### My agent sandboxes itself!

Some of you will be reading this wondering why additional sandboxing is required, since many of the popular agents [advertise their own sandboxing](https://code.claude.com/docs/en/sandboxing). The fact that some agents include some measures to protect the user's machine is of course a good thing. The touted benefits include filesystem isolation by restricting the agent to a specific directory, or prompting for approval before modifying files. Some agents also include network sandboxing to restrict network access to a list of approved domains, or by using a custom proxy to impose rules on outbound traffic.

On Linux, these agent-imposed sandboxes are often implemented with [bubblewrap](https://github.com/containers/bubblewrap), which is "a tool for constructing sandbox environments", but note that the upstream project's README includes [a section](https://github.com/containers/bubblewrap#sandbox-security) which states that it is _not_ a "ready-made sandbox with a specific security policy". `bubblewrap` is a relatively low-level tool that must be given its configuration, which in this case is provided _by the agent_.

The limitation upon these tools is the shared kernel - a severe kernel exploit could enable an agent to escape from its sandbox. Of course, such vulnerabilities are rare, but note that even if the sandboxing technologies do their job, agents often run in the context of the user's session, meaning they inherit environment variables which could contain sensitive information. They're also agent specific: Claude Code's sandboxing won't help you if you're using [Cursor](https://cursor.com/) or [Antigravity](https://antigravity.google/).

Depending on your threat model and the project you're working on, you may deem the built-in sandboxing of coding agents to be sufficient, but there are other options available to Ubuntu users that provide either different, or additional protection...

#### Sandbox with LXD containers

Canonical's [LXD](https://canonical.com/lxd) works out-of-the-box on Ubuntu, and is a great way to sandbox an agent into a disposable environment where the blast radius is limited should the agent make a mistake. My personal workflow is to create an Ubuntu container (or VM) with my project directory mounted. This way, I can edit my code directly on my filesystem with my preferred (already configured) editor, but have the agent run inside the container.

For example:

```bash
# Initialise the container
lxc init ubuntu:noble dev
# Mount my project directory into the container
lxc config device add -q dev datadir disk source="$HOME/my-project" path=/home/ubuntu/project
# Start the container
lxc start dev
# Get a shell inside the container as the 'ubuntu' user
lxc exec dev -- sudo -u ubuntu -i bash
# Run a command in the container
lxc exec dev -- sudo -u ubuntu -i bash -c "cd project; claude"
```

You can learn more about LXD in the official [documentation](https://documentation.ubuntu.com/lxd/stable-5.21/) and [tutorial](https://documentation.ubuntu.com/lxd/stable-5.21/tutorial/first_steps/#first-steps), as well as specific instructions on [enabling GPU data processing in containers/VMs](https://ubuntu.com/tutorials/gpu-data-processing-inside-lxd#1-overview). I've written [previously](https://jnsgr.uk/2024/06/desktop-vms-lxd-multipass/) about my use of LXD in development.

With LXD, you can choose between running your sandbox as a container or a VM, depending on your project's needs. If I'm working on a project that requires Kubernetes or similar, I use a VM, but for lighter projects I use system containers, preferring their lower overhead.

#### Sandbox with LXD VMs

LXD is best known for its ability to run "system containers", which are somewhat analogous to Docker/OCI containers, but rather than being focused on a single application (and dependencies), a system container essentially runs an entire Ubuntu user-space (including `systemd`, etc.). Like OCI containers, however, system containers share the kernel with the host.

In some situations, you may seek more isolation from your host machine by running tools inside a virtual machine with their own kernel. LXD makes this simple - you can follow the same commands as above, but add `--vm` to the `init` command:

```bash
# Initialise the virtual machine
lxc init --vm ubuntu:noble dev
```

You can also configure the virtual machine's CPU, memory and disk requirements. A simple example is below:

```bash
lxc init --vm ubuntu:noble dev \
  -c limits.cpu=8 \
  -c limits.memory=8GiB \
  -d root,size=100GiB
```

You can find more details on instance configuration in the [LXD documentation](https://documentation.ubuntu.com/lxd/stable-5.21/howto/instances_configure/).

#### Sandbox with Multipass

[Multipass](https://multipass.run/) provides on-demand access to Ubuntu VMs from any workstation - whether that workstation is running Linux, macOS or Windows. It is designed to replicate, in a lightweight way, the experience of provisioning a simple Ubuntu VM on a cloud.

Multipass' scope is more limited than LXD, but for many users it provides a simple on-ramp for development with Ubuntu. Where it lacks advanced features like GPU passthrough, it boasts a simplified CLI and a first-class [GUI client](https://documentation.ubuntu.com/multipass/latest/reference/gui-client/).

To get started similarly to the LXD example above, try the following:

```bash
# Install Multipass
sudo snap install multipass
# Launch an instance
multipass launch noble -n dev
# Mount your project directory
multipass mount ~/my-project dev:/home/ubuntu/project
# Get a shell in the instance
multipass shell dev
# Run a command in the instance
multipass exec dev -- claude
```

You can find more details on how to configure and manage instances [in the docs](https://documentation.ubuntu.com/multipass/latest/).

#### Sandbox with WSL

If you're on Windows, [development with WSL](https://documentation.ubuntu.com/wsl/stable/tutorials/develop-with-ubuntu-wsl/) includes first-class [support for GPU acceleration](https://documentation.ubuntu.com/wsl/stable/howto/gpu-cuda/), and is even supported for use with the [NVIDIA AI Workbench](https://ubuntu.com/blog/accelerate-ai-development-with-ubuntu-and-nvidia-ai-workbench), [NVIDIA NIM](https://docs.nvidia.com/nim/wsl2/latest/getting-started.html) and [CUDA](https://learn.microsoft.com/en-us/windows/ai/directml/gpu-cuda-in-wsl).

Ubuntu is the default Linux distribution for WSL, and you can find more information about how to set up and use Ubuntu on WSL in [our documentation](https://documentation.ubuntu.com/wsl/stable/). WSL benefits from all the same technologies as a "regular" Ubuntu install, including the ability to use Snaps, Docker and LXD.

For the enterprise developer, we recently announced [Ubuntu Pro for WSL](https://canonical.com/blog/canonical-announces-ubuntu-pro-for-wsl), as well as the ability to manage WSL instances [using Landscape](https://documentation.ubuntu.com/landscape/how-to-guides/wsl-integration/manage-wsl-instances/), making it easier to get access to first-class developer tooling with Ubuntu on your corporate machine.

### Summary

While opinion remains divided on the value and impact of current AI tooling, its presence in modern development workflows and its demands on underlying compute infrastructure are difficult to ignore.

Developers who wish to experiment need reliable access to modern hardware, predictable tooling, and strong isolation boundaries. Ubuntu’s role is not to dictate how these tools are used, but to provide a stable and dependable platform on which they can be explored and deployed safely, without compromising security, provenance, or the day-to-day experience of those who choose to opt out.

In addition to powering development workflows, Ubuntu makes for a dependable production operating system for your workloads. We're building [Canonical Kubernetes](https://documentation.ubuntu.com/canonical-kubernetes/latest/) with first-class GPU support, [Kubeflow](https://canonical.com/mlops/kubeflow) and [MLFlow](https://canonical.com/mlops/mlflow) for model training and serving and a suite of applications like [PostgreSQL](https://canonical.com/data/postgresql), [MySQL](https://canonical.com/data/mysql), [Opensearch](https://canonical.com/data/opensearch), as well as other data-centric tools such as [Kafka](https://canonical.com/data/kafka) and [Spark](https://canonical.com/data/spark) that can be deployed with full [Ubuntu Pro](https://ubuntu.com/pro) support. Let me know if you'd find value in a follow-up post on those topics!
