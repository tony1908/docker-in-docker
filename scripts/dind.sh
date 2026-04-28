#!/usr/bin/env sh
set -eu

DIND_IMAGE="${DIND_IMAGE:-docker-compose-in-docker:local}"
DIND_CONTAINER="${DIND_CONTAINER:-course-dind}"
DIND_VOLUME="${DIND_VOLUME:-course-dind-var-lib-docker}"
WORKSPACE="${WORKSPACE:-$(pwd)}"

usage() {
  cat <<EOF
Usage: $0 COMMAND [ARGS]

Commands:
  start                 Start the persistent DinD container
  copy-image IMAGE      Pipe a host Docker image into the DinD container
  shell                 Open a shell in the DinD container
  rm                    Stop and remove the DinD container

Environment:
  DIND_IMAGE            Image used for the DinD container (default: $DIND_IMAGE)
  DIND_CONTAINER        Container name (default: $DIND_CONTAINER)
  DIND_VOLUME           Volume for /var/lib/docker (default: $DIND_VOLUME)
  WORKSPACE             Host directory mounted at /workspace (default: $WORKSPACE)
EOF
}

container_exists() {
  docker container inspect "$DIND_CONTAINER" >/dev/null 2>&1
}

container_running() {
  [ "$(docker container inspect -f '{{.State.Running}}' "$DIND_CONTAINER" 2>/dev/null || true)" = "true" ]
}

wait_for_docker() {
  i=0
  until docker exec "$DIND_CONTAINER" docker info >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
      echo "Docker daemon inside $DIND_CONTAINER did not become ready. Container logs:" >&2
      docker logs "$DIND_CONTAINER" >&2 || true
      exit 1
    fi
    sleep 1
  done
}

start_container() {
  if container_running; then
    wait_for_docker
    echo "$DIND_CONTAINER is already running."
    return
  fi

  if container_exists; then
    docker start "$DIND_CONTAINER" >/dev/null
  else
    docker volume create "$DIND_VOLUME" >/dev/null
    docker run -d \
      --privileged \
      --name "$DIND_CONTAINER" \
      -v "$DIND_VOLUME:/var/lib/docker" \
      -v "$WORKSPACE:/workspace" \
      "$DIND_IMAGE" \
      sh -c 'trap "exit 0" TERM INT; while :; do sleep 86400 & wait "$!"; done' >/dev/null
  fi

  wait_for_docker
  echo "$DIND_CONTAINER is running."
}

copy_image() {
  image="${1:-}"
  if [ -z "$image" ]; then
    echo "Missing image name." >&2
    echo "Example: $0 copy-image alpine:latest" >&2
    exit 2
  fi

  start_container
  docker save "$image" | docker exec -i "$DIND_CONTAINER" docker load
}

open_shell() {
  start_container
  if [ -t 0 ]; then
    docker exec -it "$DIND_CONTAINER" bash
  else
    docker exec -i "$DIND_CONTAINER" bash
  fi
}

remove_container() {
  if container_exists; then
    docker rm -f "$DIND_CONTAINER" >/dev/null
    echo "$DIND_CONTAINER removed. Volume $DIND_VOLUME was kept."
  else
    echo "$DIND_CONTAINER does not exist."
  fi
}

command="${1:-}"
case "$command" in
  start)
    start_container
    ;;
  copy-image)
    shift
    copy_image "${1:-}"
    ;;
  shell)
    open_shell
    ;;
  rm|remove|stop-remove)
    remove_container
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 2
    ;;
esac
