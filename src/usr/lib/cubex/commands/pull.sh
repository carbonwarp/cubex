#!/usr/bin/env bash

# squash the image into single layer by creating a subsystem then exporting it as a .tar.gz then removing subsystem
# convert into tar
# store at $HOME/.local/cubex/registry

pull(){
	# Sometimes, an image cx pulls might already be in podman's local registry 
	# that podman subsystems use therefore, do not rm the image and let the user decide.
	if ! imageid="$(podman pull -q "$1")"; then
   	 echo "ERROR: Pulling failed"
   	 exit 1
	fi
	
	export imageid
	export rootfspath="$registrypath"/"$imageid" 
	echo "image's pulled. Preparing and writing on cubex registry..."
	bash "$libdir"/commands/registry/store.sh
	echo "done $imageid"
}

pull "$@"
