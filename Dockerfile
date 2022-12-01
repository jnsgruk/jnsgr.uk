FROM alpine:latest as build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# Specify version of Gosherve
ENV GOSHERVE_VERSION 0.1.1
# Copy the source code into the build container
COPY . /home/gosherve/src
# Install hugo and set permissions on directory properly
RUN adduser -D gosherve && \
    apk add --no-cache hugo ca-certificates go git && \
    chown -R gosherve: /home/gosherve
# Change user and directory
USER gosherve
WORKDIR /home/gosherve/src
# Compile the Hugo page and fetch gosherve
RUN hugo --minify && \
  # Fetch gosherve
  wget -qO /tmp/gosherve "https://github.com/jnsgruk/gosherve/releases/download/${GOSHERVE_VERSION}/gosherve-${GOSHERVE_VERSION}-linux-amd64" && \
  # Make the binary executable
  chmod 755 /tmp/gosherve

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
ENTRYPOINT [ "/gosherve" ]