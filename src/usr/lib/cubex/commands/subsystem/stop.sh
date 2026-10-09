#!/usr/bin/env bash

validate(){
    if ! jq -e --arg cname "$1" 'has($cname)' "$subsystemindex" >/dev/null; then
        echo "subsystem name \"${1}\" does not match any."
        exit 2
    fi
}


nsprocs() {   # pids sharing the mount namespace of $1
    local ns p
    ns=$(readlink /proc/$1/ns/mnt) || return 1
    for p in /proc/[0-9]*; do
        [ "$(readlink "$p/ns/mnt" 2>/dev/null)" = "$ns" ] && echo "${p#/proc/}"
    done
}

stop() {
    dir="$subsystempath/$1"
    fpid=$(pgrep -o -f "fuse-overlayfs.*upperdir=$dir/upper") ||
        { echo "not running: $1" >&2; return 0; }
    pids=$(nsprocs "$fpid")

    if [[ "$2" = force || "$2" = -f ]]; then
        kill -KILL $pids 2>/dev/null
    else
        # 1. TERM everything except the overlay daemon
        kill -TERM $(printf '%s\n' $pids | grep -vx "$fpid") 2>/dev/null
        for i in $(seq 100); do
            [ -z "$(printf '%s\n' $(nsprocs "$fpid") | grep -vx "$fpid")" ] && break
            sleep 0.1
        done
        # 2. TERM the daemon so it unmounts and flushes cleanly
        kill -TERM "$fpid" 2>/dev/null
        for i in $(seq 100); do
            kill -0 "$fpid" 2>/dev/null || return 0
            sleep 0.1
        done
        echo "did not stop in 10s, use: stop $1 force" >&2
        return 1
    fi
}


validate "$@"
stop "$@"
