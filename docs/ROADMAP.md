# Roadmap - Cubex

Cubex aims to implement its core functionality in-house using primitives provided by the Linux kernel. Third-party dependencies are currently used for supporting utilities and adjacent functionality where they reduce implementation complexity, accelerate development and help focuse on security. These dependencies are intended to be progressively replaced with in-house implementations if any ceilings hit.

OCI image processing is currently complemented by Buildah and Podman. Images are processed from these tools and converted into Cubex's local registry format for storage. The Cubex (subsystem and image) registry is currently not OCI-compliant, with OCI registry support planned.


For usability before a stable version, $HOME is binded and network is directly shared with host.

## CURRENT

* Image and subsystem processing and storing in Cubex registry.
* Display and device support for subsystems.
* Integrates with the LSM of the host.
* Signed RPM

## IN PROGRESS

* Remove images and subsystems by ID or name.
* opt-in for $HOME bind and share network

## NEXT

* Package Cubex for brew tap.
* Support for loading custom policies and profiles for subsystems
* Pre written custom policies and profiles for common use cases (ie. browser subsystem)

## FUTURE

* Port to BSD, macOS, and Windows through optimized emulation, virtualization, or any better alternative.

