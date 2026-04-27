# jnsgr.uk

This repository contains the code for my personal website https://jnsgr.uk.

The site is built with [Hugo](https://gohugo.io), and served with
[gosherve](https://github.com/jnsgruk/gosherve) — a small Go web server that serves static assets
and URL redirects from a GitHub Gist.

The site is hosted on [Fly.io](https://fly.io) and deployed automatically with GitHub Actions.

## Building

This project uses [mise](https://mise.jdx.dev/) for tool management and build tasks:

```shell
# Install tools
mise install

# Build the Go binary (includes Hugo site generation)
mise run build

# Serve the Hugo site during development
mise run dev
```

The OCI image is built with [Rockcraft](https://canonical-rockcraft.readthedocs-hosted.com/):

```shell
rockcraft pack
```
