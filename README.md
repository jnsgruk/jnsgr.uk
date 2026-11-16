# jnsgr.uk

My personal website, rendered with [Hugo](https://gohugo.io) and the
[Congo theme](https://jpanther.github.io/congo/), and hosted on
[Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/).
Pages, assets and shortlinks are published together from this repository.

## Development

This project uses [Canonical Workshop](https://github.com/canonical/workshop).
After installing Workshop and configuring LXD, run:

```shell
workshop launch
# For an existing environment after pulling these changes:
workshop refresh

# Install dependencies, check images, build Hugo, and validate with Wrangler:
workshop run -- check

# Hugo development server, exposed on localhost:1313:
workshop run -- dev

# Preview the built site with Cloudflare's local runtime:
workshop run -- preview
```

Workshop supplies Node.js and npm through the official
[Node SDK](https://github.com/canonical/node-sdk) on `22/stable`, plus Hugo extended
and ImageMagick. CI launches the same Workshop and runs its `check` and `deploy`
actions. Run `workshop refresh` on the host after changing SDK definitions.

The theme is vendored in `site/_vendor`. `build`, `generate`, `images-check` and
`images-optimize` are also available as Workshop actions.

With those tools already installed, the equivalent commands are:

```shell
npm ci
npm run check
npm run preview
```

`npm run build` renders production assets into `public/`, with the canonical URL
`https://jnsgr.uk`. It regenerates image resources to avoid stale fingerprinted
output and uses the Git commit timestamp as Hugo's build clock.
`npm run check` checks the image policy, builds the site, and performs a Wrangler
deployment dry run. Wrangler 4.162.0 and its dependencies are locked in npm.

## Publishing

[GitHub Actions](.github/workflows/publish.yaml) publishes `main` to the `website`
Worker. Set the repository variable `CLOUDFLARE_ACCOUNT_ID` and secret
`CLOUDFLARE_API_TOKEN`. DNS and domain bindings are managed in
[jnsgruk/infra](https://github.com/jnsgruk/infra).

To publish locally with both variables exported:

```shell
workshop run -- check
workshop run --env CLOUDFLARE_API_TOKEN --env CLOUDFLARE_ACCOUNT_ID -- deploy
```

## Redirects

Edit [site/static/_redirects](site/static/_redirects) to maintain shortlinks.
Hugo copies it into `public/`, where Cloudflare interprets it on deployment.
Use explicit status codes and include both slash variants when needed. Redirect
rules take precedence over assets, so avoid sources already used by pages or files.
The final wildcard rules preserve file URLs with an extra trailing slash.

Incoming query parameters may be carried through to destinations without their
own query string. Destinations with a query retain the configured query.
Changes are reviewed in Git and published with the site; there is no Gist lookup,
Bulk Redirect list, or separate redirect service.

## Images

Post images are stored as page resources alongside each post's `index.md`.
Hugo generates responsive variants up to 1320 pixels wide. Source images should
be no larger than 2640 pixels on either axis, and raster files must not exceed
1.5 MiB. WebP at quality 90 is the default; use PNG when transparency or lossless
detail is required, and SVG for vector artwork.

```shell
# Writes image.webp alongside image.png, capped at 2640px with metadata removed:
workshop run -- images-optimize path/to/image.png
# An explicit output path is also supported:
workshop run -- images-optimize path/to/image.png path/to/cover.webp
workshop run -- images-check
```

Review the image, update the post or cover reference, then remove the original.
Image checks run as part of Workshop builds and GitHub validation.
