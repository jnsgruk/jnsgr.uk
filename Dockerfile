FROM alpine:latest as build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# Specify version of Gosherve
ENV GOSHERVE_VERSION 0.2.3
ENV HUGO_VERSION 0.121.2
# Copy the source code into the build container
COPY . /home/gosherve/src
# Install dependencies and set permissions
RUN adduser -D gosherve && \
    apk add --no-cache ca-certificates go git && \
    chown -R gosherve: /home/gosherve
# Change user and directory
USER gosherve
WORKDIR /home/gosherve/src

# Fetch Hugo, compile the Hugo page and fetch gosherve
RUN wget -qO /tmp/hugo.tar.gz "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" && \
  tar -C /tmp -xvzf /tmp/hugo.tar.gz && \
  /tmp/hugo --minify && \
  # Fetch gosherve
  wget -qO /tmp/gosherve.tar.gz "https://github.com/jnsgruk/gosherve/releases/download/${GOSHERVE_VERSION}/gosherve_${GOSHERVE_VERSION}_linux_x86_64.tar.gz" && \
  # Untar the executable
  tar -C /tmp -xvzf /tmp/gosherve.tar.gz

FROM scratch
# Copy the passwd file so we run as a non-priv user
COPY --from=build /etc/passwd /etc/passwd
# Install SSL certificates so the server can fetch the redirect map
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# Copy in the website source
COPY --from=build /home/gosherve/src/public /public/
# Add the gosherve binary
COPY --from=build /tmp/gosherve /gosherve
# Switch user
USER gosherve
# Set entrypoint
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT [ "/gosherve" ]