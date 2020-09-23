FROM alpine:3.12 as build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

COPY . /home/ci/src
# Install hugo and set permissions on directory properly
RUN adduser -D ci && apk add --no-cache hugo && chown -R ci: /home/ci
# Switch to unprivileged user
USER ci
WORKDIR /home/ci/src
# Compile the Hugo page
RUN hugo -t hermit --minify
# Generate the nginx container and copy the build artifacts across
FROM nginx:mainline-alpine
COPY --from=build /home/ci/src/public /usr/share/nginx/html/
