# jnsgr.uk

This repository contains the code for my personal website https://jnsgr.uk.

The site is a simple business-card style site built with [Hugo](https://gohugo.io), and served
with [gosherve](https://github.com/jnsgruk/gosherve), which is a tiny little Go webserver that I
wrote for serving this page, as well as some static URL redirects from a Github gist.

The site is hosted on a free instance at [Fly.io](https://fly.io), and deployed automatically with
Github Actions.

## Building

This project is packaged with Nix, both as a standard Nix package and an OCI container:

```shell
# Build the Nix package for the site
nix build .#jnsgruk

# Build the OCI image
nix build .#jnsgruk-container

# Load the container into Docker, and run
docker load < result
# The image tag will the commit short hash
docker run --rm -p 8080:8080 -p 8081:8081 "jnsgruk/jnsgr.uk:$(git rev-parse --short HEAD)"
```

To build and serve just the Hugo site during development:

```shell
# Optional: enter a shell with all the dependencies present.
nix develop

cd site
hugo serve
```
