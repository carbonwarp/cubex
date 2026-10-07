 #!/usr/bin/env bash
set -euo pipefail

main(){
	echo "WARNING: This will wipe all images and subsystems found in cubex registry"
	
	read -p "Press y to proceed. (y/n): " ans

	if [[ "${ans,,}" == y || "${ans,,}" == yes ]]; then
	    echo "yes"
	    pkexec rm -rf "$HOME"/.local/share/cubex
	else
	    echo "Operation aborted"
	fi
}
main "$@"
