---
title: Meta
layout: "simple"
outputs:
  - HTML
---

This site is built using [Go], [Hugo] and [Rockcraft].

The page content is a static site, rendered with [Hugo] using the lovely [congo] theme. The page
is served with a custom web server I wrote called [gosherve]. The site is packaged as an OCI
container using [Rockcraft], and deployed to [Fly.io] with a [Github Action].

There is also an [RSS feed](https://jnsgr.uk/index.xml) for this site.

I wrote more about building the site in my [first blog
post](https://jnsgr.uk/2024/01/building-a-blog-with-go-nix-hugo/)

{{< gitinfo >}}

[congo]: https://jpanther.github.io/congo/
[Fly.io]: https://fly.io
[Github Action]: https://github.com/jnsgruk/jnsgr.uk/blob/main/.github/workflows/publish.yaml
[Go]: https://go.dev/
[gosherve]: https://github.com/jnsgruk/gosherve
[Hugo]: https://gohugo.io
[Rockcraft]: https://canonical-rockcraft.readthedocs-hosted.com/
