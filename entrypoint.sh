#!/usr/bin/env sh
set -eu

export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"

if [ "${1:-}" = "dockerd" ]; then
  exec dockerd-entrypoint.sh "$@"
fi

dockerd-entrypoint.sh dockerd >/tmp/dockerd.log 2>&1 &
dockerd_pid="$!"

cleanup() {
  kill "$dockerd_pid" >/dev/null 2>&1 || true
  wait "$dockerd_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

i=0
until docker info >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "Docker daemon did not become ready. Last daemon logs:" >&2
    tail -n 100 /tmp/dockerd.log >&2 || true
    exit 1
  fi
  sleep 1
done

if [ "$#" -eq 0 ]; then
  exec bash
fi

exec "$@"
