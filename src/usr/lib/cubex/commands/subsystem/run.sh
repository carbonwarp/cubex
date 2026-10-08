#!/usr/bin/env bash

validate(){
    if [[ "$#" != 1 ]]; then
        echo "Command structure: $ci run <subsystem name>"
        echo "Please note that, a subsystem can't be run without creating"
        echo "For more info, please refer \"$ci --help\""
        exit 2
    elif ! jq -e --arg cname "$1" 'has($cname)' "$subsystemindex" >/dev/null; then
        echo "subsystem name \"${1}\" does not match any."
        echo "subsystems can only be run if it is created already"
        exit 2
    fi
}

init(){

    imageid=$(jq -r --arg name "$1" '.[$name].imageid' "$subsystemindex")
    [ "$imageid" = null ] && { echo "no such subsystem: $1" >&2; exit 1; }

    lower="$registrypath/$imageid"
    dir="$subsystempath/$1"
    xrd="$XDG_RUNTIME_DIR"
    mkdir -p "$dir"/{upper,work,merged}

    # allow X clients from this uid
    if [ -n "$DISPLAY" ] && command -v xhost >/dev/null 2>&1; then
        xhost +si:localuser:"$(id -un)" >/dev/null 2>&1
    fi
    
    # Check if bash present in the subsystem.
    # if so use it. if not use standard shell.  
    # use bash if the subsystem has it, else sh
    if [[ -x ${lower}/bin/bash || -x ${lower}/usr/bin/bash ||
          -x ${dir}/upper/bin/bash || -x ${dir}/upper/usr/bin/bash ]]; then
        export DEFAULT_SH="/bin/bash"
    else
        export DEFAULT_SH="/bin/sh"
    fi
    

    # join if the namespace is already running
    # nsenter removes the args unless specified
    pid=$(pgrep -o -f "fuse-overlayfs.*upperdir=$dir/upper" || true)
    if [ -n "$pid" ]; then
        exec nsenter -t "$pid" -U -m -- chroot "$dir/merged" /usr/bin/env \
            XDG_RUNTIME_DIR="$xrd" \
            WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
            DISPLAY="$DISPLAY" \
            PULSE_SERVER="unix:$xrd/pulse/native" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$xrd/bus" \
            ${SSH_AUTH_SOCK:+SSH_AUTH_SOCK="$SSH_AUTH_SOCK"} \
            ${XAUTHORITY:+XAUTHORITY="$XAUTHORITY"} \
            "$DEFAULT_SH"
    fi

    # mount points created in the upper layer before mounting
    mkdir -p "$dir/upper"/{dev,proc,sys,root,tmp/.X11-unix} "$dir/upper$xrd"

    # mount and enter if not running
    unshare --user --map-auto --map-root-user --mount --pid --fork --mount-proc --uts --ipc sh -c '
      lower=$1; dir=$2; xrd=$3; host_home=$4; ps1=$5
      merged=$dir/merged

      setup() {
        fuse-overlayfs -o "lowerdir=$lower,upperdir=$dir/upper,workdir=$dir/work" "$merged" || return 1
        mount --rbind /dev  "$merged/dev"  || return 1
        mount -t proc proc "$merged/proc"  || return 1
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

      exec chroot "$merged" /usr/bin/env \
        XDG_RUNTIME_DIR="$xrd" \
        WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
        DISPLAY="$DISPLAY" \
        PULSE_SERVER="unix:$xrd/pulse/native" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$xrd/bus" \
        ${SSH_AUTH_SOCK:+SSH_AUTH_SOCK="$SSH_AUTH_SOCK"} \
        ${XAUTHORITY:+XAUTHORITY="$XAUTHORITY"} \
        "$DEFAULT_SH"
	' sh "$lower" "$dir" "$xrd" "$HOME" "$PS1"
}

validate "$@"
init "$@"
