#!/usr/bin/env bash
set -euo pipefail

# This script holds registry data storing (in json)
# storage
#    ├── subsystem 	 --> Holds all cubex subsystems
#    ├── subsystem.json --> Index of cubex subsystems with its corresponding image (rootfs) in use
#    ├── registry	 --> Holds the image rootfs as each under its imageID
#    └── registry.json 	 --> Index of registry/


work() {
    repotag="$(podman inspect --format '{{index .RepoTags 0}}' "$imageid")" || exit 1

    subsystemid="$(podman create "sha256:${imageid}")" || exit 1
    trap 'podman rm -f "$subsystemid" >/dev/null 2>&1' EXIT

    mkdir -p "$rootfspath" || exit 1

    # if exporting subsystem or extracting to rootfs fails
    if ! podman export "$subsystemid" | tar -x -C "$rootfspath"; then
        rm -rf "$rootfspath"
        exit 1
    fi

    export rsize=$(du -sh "$rootfspath" | cut -f1)

    tmpri="$(mktemp "${registryindex}.tmp.XXXXXX")" || exit 1

    if jq --arg imageid "$imageid" \
          --arg repotag "$repotag" \
          --arg rsize "$rsize" \
          '.[$imageid] = {
              id: $imageid,
              repotag: $repotag,
              size: $rsize
          }' "$registryindex" > "$tmpri"
    then
        mv -f "$tmpri" "$registryindex"
    else
        rm -f "$tmpri"
        rm -rf "$rootfspath"
        echo "ERROR: Something went wrong"
        exit 1
    fi
}
work
