---
title: Meta
layout: "simple"
---

This site is built using [Go], [Hugo] and [Nix].

the page content itself is a static site, rendered with [Hugo]. It uses the lovely
[congo] theme. The page is served with a custom webserver I wrote called [gosherve]. This was
initially a basic web server that would serve files from a directory, and a series of redirects
placed in a text file at a URL. To build this site, I [modified] gosherve such that it's server
component is exposed as a library, and [refactored] it to serve content from an embedded
filesystem.

This site is then a simple Go wrapper around gosherve which hardcodes the location of the redirects
file, and embeds the built Hugo site.

Finally, the site is packaged up and built using a Nix [Flake], which outputs both a package and an
OCI container, which is subsequently deployed to [Fly.io] with a [Github Action].

{{< gitinfo >}}

[congo]: https://jpanther.github.io/congo/
[Flake]: https://nixos.wiki/wiki/Flakes
[Fly.io]: https://fly.io
[Github Action]: https://github.com/jnsgruk/jnsgr.uk/blob/main/.github/workflows/publish.yaml
[Go]: https://go.dev/
[gosherve]: https://github.com/jnsgruk/gosherve
[Hugo]: https://gohugo.io
[modified]: https://github.com/jnsgruk/gosherve/commit/9d5e77c67031a944d5193ad37308d08ac82b13e4
[Nix]: https://nixos.org/
[refactored]: https://github.com/jnsgruk/gosherve/commit/3f81dd97cdd7c60bf4028443aa7fd743c451425f
