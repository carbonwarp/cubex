#!/usr/bin/env bash

search(){
	podman search "$1" | awk 'NR == 1 {print "\033[94m" $0 "\033[0m"; next} {print}'
}

search "$@"
