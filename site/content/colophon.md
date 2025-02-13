---
title: Meta
layout: "simple"
---

This site is built using [Go], [Hugo] and [Nix].

The page content is a static site, rendered with [Hugo] using the lovely [congo] theme. The page
is served with a custom web server I wrote called [gosherve]. The site is packaged using a [Nix]
[Flake], which outputs both a package and an OCI container, which is deployed to [Fly.io] with a
[Github Action].

There is also an [RSS feed](https://jnsgr.uk/index.xml) for this site.

I wrote more about building the site in my [first blog
post](https://jnsgr.uk/2024/01/building-a-blog-with-go-nix-hugo/)

{{< gitinfo >}}

[congo]: https://jpanther.github.io/congo/
[Flake]: https://nixos.wiki/wiki/Flakes
[Fly.io]: https://fly.io
[Github Action]: https://github.com/jnsgruk/jnsgr.uk/blob/main/.github/workflows/publish.yaml
[Go]: https://go.dev/
[gosherve]: https://github.com/jnsgruk/gosherve
[Hugo]: https://gohugo.io
[Nix]: https://nixos.org/
