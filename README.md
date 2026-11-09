# jnsgr.uk

This repository contains the code for my personal website https://jnsgr.uk.

The site is built with [Hugo](https://gohugo.io), and served with
[gosherve](https://github.com/jnsgruk/gosherve) — a small Go web server that serves static assets
and URL redirects from a GitHub Gist.

The site is hosted on [Fly.io](https://fly.io) and deployed automatically with GitHub Actions.

## Building

This project uses [Canonical Workshop](https://github.com/canonical/workshop) for tool
management and development actions. Install Workshop and configure LXD using the
[setup guide](https://documentation.ubuntu.com/canonical-workshop/stable/tutorial/part-1-get-started/),
then run:

```shell
# Create the development environment
workshop launch

# Build the Go binary (checks images and generates the Hugo site)
workshop run -- build

# Serve the Hugo site during development
workshop run -- dev

# Generate the site without building the binary
workshop run -- generate
```

The Store Go SDK supplies Go 1.27 and gopls.
Small project SDKs in `.workshop/` install gofumpt, Hugo extended,
ImageMagick, and flyctl, each with its own setup
hook. Hugo uses the upstream extended binary so it can access Workshop’s `/project` mount. Run `workshop refresh` on the host after changing SDK definitions or hooks.
Use `workshop shell` for an interactive environment with these tools available.
The Hugo tunnel exposes the dev server at `http://localhost:1313` on the host.
Actions that accept arguments pass them through, for example `workshop run -- dev --disableFastRender`.

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
workshop run -- images-optimize path/to/image.png

# An explicit output path can be supplied when needed
workshop run -- images-optimize path/to/image.png path/to/cover.webp
```

Review the generated image, update the Markdown or `cover` front matter to reference it, then remove
the original. `workshop run -- images-check` validates dimensions and file sizes, and is also run
automatically by `workshop run -- build` and the GitHub workflows before Rockcraft packaging.
