#!/usr/bin/env bash

main(){
	echo "WARNING: This will wipe all subsystems found in cubex registry. Images won't be affected"

	read -p "Press y to proceed. (y/n): " ans

	if [[ "${ans,,}" == y || "${ans,,}" == yes ]]; then
	    echo "yes"
	    pkexec rm -rf "$HOME"/.local/share/cubex/subsystem*
	else
	    echo "Operation aborted"
	fi
}
main "$@"
