#!/usr/bin/env bash


listall() {
    {
        printf '%-24.24s %-24.24s %9.10s\n' "SUBSYSTEM NAME" "IMAGE ID" "STATUS"

        jq -r 'to_entries[] | "\(.key)\t\(.value.imageid)"' "$subsystemindex" |
        while item=$'\t' read -r name imageid; do
            if pgrep -f "fuse-overlayfs.*upperdir=$subsystempath/$name/upper" >/dev/null; then
                state=Running
            else
                state=Stopped
            fi
            printf "%-24.24s %-24.24s %10.10s\n" "$name" "$imageid" "$state"
        done
    } | column -t -s $'\t'
}


listrunning() {
    {
        printf '%-24.24s\t%-24.24s\n' "SUBSYSTEM NAME" "IMAGE ID"

        jq -r 'to_entries[] | "\(.key)\t\(.value.imageid)"' "$subsystemindex" |
        while IFS=$'\t' read -r name imageid; do
            if pgrep -f "fuse-overlayfs.*upperdir=$subsystempath/$name/upper" >/dev/null; then
                printf '%-24.24s\t%-24.24s\t%10.10s\n' "$name" "$imageid"
            fi
        done
    } | column -t -s $'\t'
}

list(){
    if [[ $1 = "--all" || $1 = "-a" ]]; then
        listall
    else
        listrunning
    fi
}
list "$@"
