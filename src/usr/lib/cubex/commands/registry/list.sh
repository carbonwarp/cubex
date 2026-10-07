#!/usr/bin/env bash
set -euo pipefail

main(){
	jq -r '
	  ["IMAGE ID", "REMOTE REPOSITORY", "SIZE"],
	  (to_entries[] | [.key, .value.repotag, .value.size])
	  | @tsv' \
	  "$registryindex" | awk -F '\t' '{ printf "%-12.12s %-52.52s %-4.4s\n", $1, $2,$3 }'
}
main

