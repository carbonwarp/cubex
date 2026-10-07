#!/usr/bin/env bash
set -euo pipefail

# need: imageid

validate(){

    if [[ ! "$#" == 2 ]]; then
    	echo "Command structure: "$ci" create <image id> <subsystem name>"
	echo "For more info, please refer \""$ci" --help\""
	exit 2

    elif [[ "$(jq --arg id "$1" '[keys[] | select(startswith($id))] | length' "$registryindex")" -ne 1 ]]; then
    	echo "ERROR: Invalid image ID: no matching image found / ID is too short"
    	exit 2

    elif jq -e --arg CName "$2" 'has($CName)' "$subsystemindex" >/dev/null; then
    	echo "duplicate subsystem name is not allowed"
    	exit 2
    fi

    fullimageid="$(jq -r --arg id "$1" 'keys[] | select(startswith($id))' "$registryindex")"

}

create(){
	mkdir -p "$subsystempath"/"$2"/{upper,scratch,merged} || exit 1
}

# Update subsystem registry
update(){
    tmpci="$(mktemp "${subsystemindex}.tmp.XXXXXX")" || exit 1

    if jq --arg cname "$2" \
          --arg imageid "$fullimageid" \
          '.[$cname] = {
              imageid: $imageid
          }' "$subsystemindex" > "$tmpci"
    then
        mv -f "$tmpci" "$subsystemindex"
    else
        rm -f "$tmpci"
        rm -rf "$"
        echo "ERROR: Something went wrong"
        exit 1
    fi
}



validate "$@"
create "$@"
update "$@"
echo "Done. Try ${ci} run ${2}"
