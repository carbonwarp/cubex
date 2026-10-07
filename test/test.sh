#!/usr/bin/env bash
# INCOMPLETE !
set -u

BINS=(cubex cx)
IM=docker.io/library/busybox:musl
IMI=$(podman image inspect -f '{{.Id}}' "$IM")

for i in $BINS $IM $IMI; do
	echo $i
done


check() {
    if "$@" > /dev/null 2>&1; then
        printf "\033[8C PASSED\n"
        printf '%q ' "$@"
        printf '\n'
    else
        printf "\033[8C FAILED  "
        printf '%q ' "$@"
        printf '\n'
    fi
}

for CI in cubex cx; do
	for X in -h --help -v --version; do
		check $CI $X
	done

	for X in pull p; do
		for Y in $IM; do
			check $CI $X $Y
		done
	done

	for X in create c; do
		for Y in $IMI; do
			RND=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 30)	
			check "$CI" "$X" "$Y" "${RND}"

	done	
done


