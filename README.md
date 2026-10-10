>[!caution]
>Cubex is currently an experimental proof of concept, exploring the feasibility of its vision through preliminary implementations. It is not yet suitable for untrusted or critical workloads. If the concept proves viable, future development will adopt established runtimes, security mechanisms, and industry practices while preserving the project's original vision.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/cubex-white.svg" width=200>
  <source media="(prefers-color-scheme: light)" srcset="docs/cubex-black.svg">
  <img src="cubex-black.svg" alt="Your image">
</picture>


## Cubex Subsystem 
### The subsystem technology that integrates with  host's system security

<details>
    <summary>Abstraction</summary>

- Subsystems - Systems that run on a (host) system parallel and simultaneously to host. Virtualization, containerization, and technologies similar to stated ones can be grouped into it.
    
- Security through Integration - Depending on the use-case, Integration offers security as much as or better than isolation by requiring the stated program to be governed by the same security model that restricts other programs on the system. It does not mean to not look after integrity. 
</details>


Cubex works with any OCI-compliant image to create subsystems that integrate natively with the host system’s LSMs and integrates with host's security with flexible access controls that can provide access to the host path, the network with control over ports, both, or neither, depending on the needs.

It is specifically developed for immutable Linux hosts, with flexible controls that can provide access to the host path, the network with control over ports, both, or neither, depending on the needs.


## Installation & Usage

Cubex is available as .rpm, .deb, and archlinux's pkg.tar.zst. Installation guide is available [here](https://carbonwarp.com/cubex#install).

Usage with creating a subsystem and running firefox is available [here](https://carbonwarp.com/cubex/#how-to-use).
