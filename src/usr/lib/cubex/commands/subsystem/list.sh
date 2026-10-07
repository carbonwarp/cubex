#!/usr/bin/env bash

main(){
	jq -r '
	  ["SUBSYSTEM NAME", "IMAGE ID"],
	  (to_entries[] | [.key, .value.imageid])
	  | @tsv' \
	  "$subsystemindex" | awk -F '\t' '{ printf "%-24.24s %-24.24s\n", $1, $2}'
}
main "$@"
