#!/usr/bin/env bash

validate(){
    if ! jq -e --arg cname "$1" 'has($cname)' "$subsystemindex" >/dev/null; then
        echo "subsystem name \"${1}\" does not match any."
        exit 2
    fi
}

start(){


    imageid=$(jq -r --arg name "$1" '.[$name].imageid' "$subsystemindex")
    [ "$imageid" = null ] && { echo "no such subsystem: $1" >&2; exit 1; }

    lower="$registrypath/$imageid"
    export dir="$subsystempath/$1"

    # already running? do nothing
    if pgrep -f "fuse-overlayfs.*upperdir=$dir/upper" >/dev/null; then
        echo "already running: $1" >&2
        exit 0
    fi

    mkdir -p "$dir"/{upper,work,merged}
    # start the container with bin/sh so it keeps running in the bg
    # Copied from run.sh when run.sh took care of starting and running.
    # Orphan codes present
    setsid unshare --map-auto --map-root-user --mount sh -c '
      lower=$1; dir=$2; xrd=$3; host_home=$4; ps1=$5
      merged=$dir/merged

      setup() {
        fuse-overlayfs -o "lowerdir=$lower,upperdir=$dir/upper,workdir=$dir/work" "$merged" || return 1
        mount --rbind /dev  "$merged/dev"  || return 1
        mount --rbind /proc "$merged/proc" || return 1
        mount --rbind /sys  "$merged/sys"  || return 1
        mount --bind "$host_home" "$merged/root" || return 1
        chmod 1777 "$merged/tmp"

        # X11 socket
        [ -d /tmp/.X11-unix ] && { mount --bind /tmp/.X11-unix "$merged/tmp/.X11-unix" || return 1; }

        # only the runtime-dir entries we need (not the whole dir)
        for f in bus pulse "$WAYLAND_DISPLAY"; do
          [ -n "$f" ] && [ -e "$xrd/$f" ] || continue
          if [ -d "$xrd/$f" ]; then mkdir -p "$merged$xrd/$f"; else touch "$merged$xrd/$f"; fi
          mount --bind "$xrd/$f" "$merged$xrd/$f" || return 1
        done

        # ssh-agent socket outside the runtime dir
        case "$SSH_AUTH_SOCK" in
          ""|"$xrd"/*) ;;
          *) mkdir -p "$merged$(dirname "$SSH_AUTH_SOCK")" &&
             touch "$merged$SSH_AUTH_SOCK" &&
             mount --bind "$SSH_AUTH_SOCK" "$merged$SSH_AUTH_SOCK" || return 1 ;;
        esac

        rm -f "$merged/etc/resolv.conf"
        cp -L /etc/resolv.conf "$merged/etc/resolv.conf"
        [ -e "$merged/etc/machine-id" ] || cp /etc/machine-id "$merged/etc/machine-id"
      }

      # on failure, stop the overlay daemon so a later run does not join a half-built namespace
      setup || { fusermount3 -u "$merged" 2>/dev/null || fusermount -u "$merged" 2>/dev/null; exit 1; }

      exec chroot "$merged" /usr/bin/env sleep infinity
	' sh "$lower" "$dir" "$xrd" "$HOME" "$PS1" </dev/null >"$dir/start.log" 2>&1 &
}

validate "$@"
start "$1" && echo "Successfully started $1. You may run \"$ci run $1\" to get a shell that you can use" || echo "failed"
