---
title: Building a blog with Go, Nix and Hugo
summary: |
  Documenting how I render, serve, build and deploy my personal website and blog using a
  combination of Go, Hugo, Nix and Fly.io.
tags:
  - Go
  - Hugo
  - Nix
  - Fly.io
  - Blog
layout: post
---

## Introduction

I've been procrastinating about blogging for about a decade. Long-form writing is a format I enjoy
consuming, and I've learned a huge amount from the various blogs I've subscribed to over the years.
Yet, there have always been a couple of nagging reasons preventing me from starting my own:

- Why would anyone want to read _my_ blog?
- How would I come up with ideas for content?
- Where would I find the time to write the blog?

Perhaps what's changed recently is a new found enjoyment in some side projects, and the realisation
that I might just write about things _for the love of it_, whether or not its directly useful to
anyone else. Of course I'd love people find the content useful, engage, etc., but that isn't my
primary motivation.

The second two points are closely linked, but I ultimately decided they didn't matter. So I present
this blog as a self-indulgence, and something that I'll update when I'm excited about writing, and
not feel bad about the rest of the time! 😉

Being a Software Engineer, I quickly established that it was important to spend time
over-engineering my blog before sitting down and writing any content, and this first post
illustrates that journey <span style="color: #999">\</sarcasm></span>.

## Rendering the blog

I've been fond of [Hugo] for years now (I even named my son Hugo 😉). I've used it in a few
projects, and I find it to be largely easy to understand and well maintained. My previous site was
built with Hugo, using a theme named [congo] which I'd been underutilising by only creating a
"business card" style page. I decided to stick with this setup, and just use more of the layouts
provided by the theme.

In many ways the Hugo site is the most "boring" part of the site. The source code is all available
in the [`site` directory] of the Github repo, but I won't talk much about the site itself in this
blog, as there isn't much more to say!

[Hugo]: https://gohugo.io
[congo]: https://jpanther.github.io/congo/
[`site` directory]: https://github.com/jnsgruk/jnsgr.uk/tree/main/site

## Serving the blog

4 years ago, I made the [first commit] to a project named `gosherve`. This was one of my first
adventures into Go, and I was left with a small, but functional web server that could serve files
from a directory, and serve redirects specified in a publicly accessible text file.

I chose to host the redirect definitions [in a Github Gist]. When I want to share a link
frequently, or place one somewhere visible like a slide, I update the Gist with a new alias, and
`jnsgr.uk/<alias>` comes online as a handy short link the first time someone requests it.

Last year I decided to use `gosherve` as a tool for learning more about [`slog`] and the Go
[Prometheus client]. I did some refactoring that tidied up the logging, and introduced basic
metrics for the number of times each redirect was accessed, how many redirects were defined and the
total number of redirects served.

For my new blog, I wanted to keep the short URLs I'd defined, and I wanted to embed the static site
into the binary to make deployment as simple as possible. I made two small changes to `gosherve` to
enable this:

- [refactor: move packages from internal -> pkg]
- [refactor: use fs.FS as webroot rather than path (string)]

The first change enables the `server` and `logging` components of `gosherve` to be imported as
libraries, and the second enables `gosherve` to serve files from a filesystem (and critically, an
embedded filesystem).

[first commit]: https://github.com/jnsgruk/gosherve/commit/1df0d8804c57a836b905b4ff2528be995d16631f
[in a Github Gist]: https://gist.github.com/jnsgruk/b590f114af1b041eeeab3e7f6e9851b7
[`slog`]: https://pkg.go.dev/golang.org/x/exp/slog
[refactor: move packages from internal -> pkg]: https://github.com/jnsgruk/gosherve/commit/9d5e77c67031a944d5193ad37308d08ac82b13e4
[refactor: use fs.FS as webroot rather than path (string)]: https://github.com/jnsgruk/gosherve/commit/3f81dd97cdd7c60bf4028443aa7fd743c451425f
[Prometheus client]: https://github.com/prometheus/client_golang

## Embedding the blog

One of the things I love about Go is how rich the standard library is, and how it can simplify the
creation of small, but powerful applications. The code for my website's server as I write this is
below:

```go
package main

//go:generate hugo --minify -s site -d ../public

import (
	"embed"
	// ...
	"github.com/jnsgruk/gosherve/pkg/logging"
	"github.com/jnsgruk/gosherve/pkg/server"
)

var (
	commit string = "dev"
	logLevel = flag.String("log-level", "info", "log level of the application")
	redirectsURL = "https://gist.githubusercontent.com/jnsgruk/b590f114af1b041eeeab3e7f6e9851b7/raw"

    //go:embed public
	publicFS embed.FS
)

func main() {
	flag.Parse()
	logging.SetupLogger(*logLevel)

	fsys, err := fs.Sub(publicFS, "public")
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}

	s := server.NewServer(&fsys, redirectsURL)

	err = s.RefreshRedirects()
	if err != nil {
		slog.Error("unable to fetch redirect map", "error", err.Error())
		os.Exit(1)
	}

	s.Start()
}
```

I've omitted some comments, imports and logging for brevity here, but the complete file (at 55
lines) can be found [on Github] for the curious.

There key elements here are:

- `//go:generate  hugo --minify -s site -d ../public`: this makes sure `go generate` invokes Hugo
  to build the site and place the output in the `public` directory.
- `//go:embed public`: embeds the `public` directory into the binary as an embedded filesystem.

## Building the blog

For the last 18 months, I've been enjoying [Nix] and [NixOS] for my personal machines, so I wanted
to use my newly acquired knowledge to package and build my website using Nix.

There is lots of ongoing discussion in the Nix community about [Flakes], which are an experimental
technology aimed at simplifying usability and improving reproducibility of Nix installations. There
are lots of other facets to the discussion which I'll likely touch upon in future posts, but for
now I'll just say that I like Flakes, and they were the obvious choice for packaging this site.

Packaging a Go application for Nix is relatively simple thanks to helpers like `buildGoModule`. I
had to make some minor modifications to accommodate the `go generate` step to build the Hugo site,
and patch out some elements of the Hugo site that relied upon access to the local Git tree, but the
resulting derivation remains relatively easy to digest (see [flake.nix]):

```nix
buildGoModule {
  inherit version;
  pname = "jnsgruk";
  src = lib.cleanSource ./.;

  vendorHash = "sha256-4f04IS76JtH+I4Xpu6gF8JQSO3TM7p56mCs8BwyPo8U=";
  buildInputs = [ cacert ];
  nativeBuildInputs = [ hugo ];

  # Nix doesn't play well with Hugo's "GitInfo" module, so disable it and inject
  # the revision from the flake.
  postPatch = ''
    substituteInPlace ./site/layouts/shortcodes/gitinfo.html \
      --replace "{{ .Page.GitInfo.Hash }}" "${rev}"

    substituteInPlace ./site/config/_default/config.yaml \
      --replace "enableGitInfo: true" "enableGitInfo: false"
  '';

  # Generate the Hugo site before building the Go application which embeds the
  # built site.
  preBuild = ''
    go generate ./...
  '';

  ldflags = [ "-X main.commit=${rev}" ];

  # Rename the main executable in the output directory
  postInstall = ''
    mv $out/bin/jnsgr.uk $out/bin/jnsgruk
  '';

  meta.mainProgram = "jnsgruk";
};
```

This defines a Nix package named `jnsgruk`, containing a single binary at `bin/jnsgruk`. This
binary can be run anywhere to get a working version of this site. You can even try at home with:

```shell
nix run github:jnsgruk/jnsgr.uk
```

[Flakes]: https://nixos.wiki/wiki/Flakes
[NixOS]: https://nixos.org
[Nix]: https://github.com/NixOS/nix
[flake.nix]: https://github.com/jnsgruk/jnsgr.uk/blob/6112321824f7b36e7ecb0414b3d7a6c04f13dc4b/flake.nix
[on Github]: https://github.com/jnsgruk/jnsgr.uk/blob/6112321824f7b36e7ecb0414b3d7a6c04f13dc4b/main.go

## Deploying the blog

I've been hosting my site on [Fly.io] without issue for a couple of years. They have a nice feature
that allows you to [Deploy via Dockerfile], where their command-line utility `flyctl` will send off
a local `Dockerfile` to be built on their infrastructure and then launched, and that had been
working great in [previous versions of my site].

I wanted to be able to build and run the exact same bits on my own machines as were hosted by Fly,
so I opted to build an OCI image with Nix, then upload that to [Fly.io]'s registry as part of the
deployment. Adding a container image to the flake as an additional output was simple:

```nix
dockerTools.buildImage {
  name = "jnsgruk/jnsgr.uk";
  tag = version;
  created = "now";
  copyToRoot = buildEnv {
    name = "image-root";
    paths = [ self.packages.${system}.jnsgruk cacert ];
    pathsToLink = [ "/bin" "/etc/ssl/certs" ];
  };
  config = {
    Entrypoint = [ "${lib.getExe self.packages.${system}.jnsgruk}" ];
    Expose = [ 8080 8801 ];
    User = "10000:10000";
  };
};
```

All that remained was to wire up Github Actions to build and deploy the site each time I make a new
commit. Because the build tooling setup is all handled by Nix, the resulting [Github workflow] is
quite brief:

```yaml
name: Fly Deploy
on:
  push:
    branches:
      - main

permissions:
  packages: write

jobs:
  deploy:
    name: Deploy app
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install nix
        uses: DeterminateSystems/nix-installer-action@v9

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build container
        run: nix build -L .#jnsgruk-container

      - name: Upload container to ghcr.io
        run: |
          docker load < result
          docker tag "jnsgruk/jnsgr.uk:$(git rev-parse --short HEAD)" "ghcr.io/jnsgruk/jnsgr.uk:$(git rev-parse --short HEAD)"
          docker push "ghcr.io/jnsgruk/jnsgr.uk:$(git rev-parse --short HEAD)"

      - name: Deploy site
        run: |
          nix run nixpkgs#flyctl -- deploy -i "ghcr.io/jnsgruk/jnsgr.uk:$(git rev-parse --short HEAD)"
        env:
          FLY_ACCESS_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

And that's the end! You're reading this article as a result of the above workflow succeeding.

[Deploy via Dockerfile]: https://fly.io/docs/languages-and-frameworks/dockerfile/
[Github workflow]: https://github.com/jnsgruk/jnsgr.uk/blob/6112321824f7b36e7ecb0414b3d7a6c04f13dc4b/.github/workflows/publish.yaml
[Fly.io]: https://fly.io
[previous versions of my site]: https://github.com/jnsgruk/jnsgr.uk/tree/98eed123f5bc111eff481c9a485c158783310478

## Summary

I've never had a blog before, but I'm looking forward to documenting some of my adventures in
Linux, Software Engineering, Technical Leadership and more over the coming year. Thanks for
reading!
