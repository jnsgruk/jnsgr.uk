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

## Images

Post images are stored as [page resources](https://gohugo.io/content-management/page-resources/)
alongside the post's `index.md`. Hugo generates responsive variants up to 1320 pixels wide, so
source images should be no larger than 2640 pixels on either axis. This preserves enough resolution
for high-density displays without embedding unnecessarily large originals in the server binary.

WebP at quality 90 is the default format for raster images. It provides a good balance between
photographic and screenshot quality while keeping source and direct-link downloads small. PNG is
reserved for images that require transparency or genuinely lossless detail, and SVG remains
appropriate for vector artwork. Raster assets must be no larger than 1.5 MiB.

Use the image task before adding a new raster image to a post:

```shell
# Writes image.webp alongside image.png, capped at 2640px and with metadata removed
mise run images:optimize -- path/to/image.png

# An explicit output path can be supplied when needed
mise run images:optimize -- path/to/image.png path/to/cover.webp
```

Review the generated image, update the Markdown or `cover` front matter to reference it, then remove
the original. `mise run images:check` validates dimensions and file sizes, and is also run
automatically by `mise run build` and the GitHub workflows before Rockcraft packaging.
