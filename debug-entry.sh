#!/bin/ash
export REDIRECT_MAP_URL="https://gist.githubusercontent.com/jnsgruk/b590f114af1b041eeeab3e7f6e9851b7/raw/cacd49f5245fce3ad418e76ce469b7ebf91a688a/routes"
export WEBROOT="/srv"

/usr/bin/gosherve > /tmp/output.log 2>&1