#!/usr/bin/env bash

validate(){
    if ! jq -e --arg cname "$1" 'has($cname)' "$subsystemindex" >/dev/null; then
        echo "subsystem name \"${1}\" does not match any."
        exit 2
    fi
}

init(){

    imageid=$(jq -r --arg name "$1" '.[$name].imageid' "$subsystemindex")
    [ "$imageid" = null ] && { echo "no such subsystem: $1" >&2; exit 1; }

    lower="$registrypath/$imageid"
    export dir="$subsystempath/$1"
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


    # join the namespace cx start created
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

    echo "ERROR: Cannot run a subsystem that is not started"
    exit 1
}

validate "$@"
init "$@"
