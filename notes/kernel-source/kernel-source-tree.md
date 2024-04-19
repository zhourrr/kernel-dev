# Kernel Source Tree

The source tree is a directory which contains all of the kernel source. You could build a new kernel, install that, and reboot your machine to use the newly built kernel.

[Mainline Source Tree](https://github.com/torvalds/linux)

- Mainline:  
  Mainline tree is maintained by Linus Torvalds at [here](https://github.com/torvalds/linux). It's the tree where all new features are introduced and where all the exciting new development happens. This repo contains many "RC" (release candidate) kernels but it doesn't have many stable release tags.
- Stable:  
  After each mainline kernel is released, it is considered **stable**. Any bug fixes for a stable kernel are backported from the mainline tree and applied by a designated stable kernel maintainer. There are usually only a few bugfix kernel releases until next mainline kernel becomes available -- unless it is designated as a  **long-term maintenance kernel**. Stable kernel updates are released on as-needed basis. To download the stable kernels:

  ```bash
  git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
  ```

## Notes on Linux Code Space

***Monolithic Kernel***:  
Every feature of the kernel is compiled into a single file and all the services (like process and memory management, file systems, device drivers, etc.) are executed in the kernel space. The problem with this is that, whenever you need to add a driver for a new device or support for a new type of filesystem, you need to rebuild the kernel, re-install it and reboot the computer.

***Linux Design***:  
Linux is a ***monolithic*** kernel but also adopts some characteristics of ***microkernel***s, which allows you to dynamically add or remove code from the running kernel. But, unlike in ***microkernel***s, these kernel code (modules) run in kernel space and have the same privileges as the rest of the kernel, so an error in a kernel module can crash the entire system, which is a characteristic of ***monolithic*** kernels.  
For example, if you start writing over data because of an off-by-one error, then you’re trampling on kernel data (or code). This is even worse than it sounds, so try your best to be careful.

## Linux Modules

Linux is very modular by design. Different components of a Linux system originate from different developers; each has their own specific design goals and focus on those goals. Further, each component is configured separately, generally by the use of configuration files. This modular design means that crashes and security vulnerabilities in applications tend to remain localized, rather than affecting the system as a whole.

- ***Static Linux Kernel Module***:  
    When you build a Linux kernel, you can make your module statically linked to the kernel image. That means the module becomes part of the final Linux kernel image. This method increases the size of the final Linux kernel image.  
    Since the module is ‘built-in’ into the Linux kernel image, you can’t unload the module. It occupies the memory permanently during the runtime.
- ***Dynamic Linux Kernel Module***:  
    When you build a Linux kernel, these modules are not built into the final kernel image; instead, they are compiled and linked separately to produce **.ko** files.  
    You can dynamically load and unload these modules from the kernel using user-space programs such as `insmod`, `modprobe`,or `rmmod`.

Loadable Kernel Modules (LKM) are chunks of code that are dynamically loaded and unloaded into the kernel as needed (at runtime), thus extending the functionality of the base kernel without requiring a reboot. In fact, unless users inquire about modules using commands like `lsmod`, they won't likely know that anything has changed. Kernel modules are usually stored under **/lib/modules/kernel-version/** directory.

To load a kernel module, you can use the `insmod` utility. This utility receives as a parameter the path to the **.ko** file in which the module was compiled and linked. Unloading the module from the kernel is done using the `rmmod` command, which receives the module name as a parameter.

## Directories

Directory      | Description
-------------- | --------------
Documentation | Kernel source documentation
arch | Architecture-specific source
block | Block I/O layer
certs | Certificates and signs to allow module signatures for the kernel to load signed modules
crypto | Handles cryptographic and compression tasks
drivers | Device drivers
fs | Sources for file systems
include | Kernel headers for kernel modules, no user-space library is linked to the kernel module during a kernel build procedure (don't use any user-space library in kernel development because they are usually implemented on top of kernel services)
init | Boot process and initialization of the kernel
ipc | Inter-process communication, such as signals and pipes
kernel | Core subsystems, such as the scheduler
lib | Library routines, such as debugging routines
mm | Memory management subsystem
net | Networking subsystem
samples | Samples, demonstrative code
scripts | Scripts used to build the kernel
security | Security Module
sound | Sound subsystem
tools | Tools helpful for developing Linux
usr | Code included allows you to execute code in user space in the boot process when the kernel isn't fully loaded (called initramfs)
virt | Virtualization infrastructure (KVM)

## Files

Build System File           | Description
-------------- | --------------
Kconfig | Used to enable or disable kernel features. It first loads an initial configuration database, then updates the initial one by reading other existing configuration files or/and utilizing a user-interactive configuration program. The final configuration database is dumped into a **.config** file.
Kbuild | A build system used by Linux which provides component-wise building. By dividing source files into different modules/components, each component is managed by its own Makefile. When you start building, a top-level Makefile invokes each component's Makefile in the proper order, builds the components, and collects them into the final executive.
Top-level Makefile | The top-level Makefile reads **.config** file, builds up each module, and links all the intermediate objects into **vmlinux**. One only interacts with this top-level Makefile.
Kbuild Makefile | Most Makefiles within the kernel are Kbuild Makefiles that use the Kbuild infrastructure. The preferred name for the Kbuild files are **Makefile**.

## Executables

Executable     | Description
-------------- | --------------
vmlinux | A non-compressed (huge!) and non-bootable Linux kernel in ELF (Executable and Linkable Format), just an intermediate step to producing **vmlinuz**, but can be used for debugging or other purposes.
vmlinuz | A compressed and bootable Linux kernel (no debugging info integrated). Bootable means that it is capable of loading the operating system into memory so that the computer becomes usable and application programs can be run. **vmlinuz** is located in the **/boot** directory, which is the directory that contains the files needed to begin booting the system.
bzImage | Linux kernel is compiled by issuing `make bzImage`, this results in the creation of a file named **bzImage**, which is one format of **vmlinuz**. **bzImage** is then copied to the **/boot** directory and usually renamed to **vmlinuz**.

## ***API*** vs ***ABI*** vs ***ISA***

- Application Program Interface (API): an interface between the operating system and application programs in the context of source code, e.g., libraries and helper routines
- Application Binary Interface (ABI): an interface between the operating system and application programs in the context of object/binary code (how compiler builds applications), e.g., how parameters are passed to functions (stack/registers) and who cleans parameter from the stack (caller/callee)
- Instruction Set Architecture (ISA): a hardware interface

## User API/ABI Stability

- Linux kernel to user-space API is stable: source code for user-space applications will not have to be updated when compiling for a more recent kernel
- Linux kernel to user-space ABI is stable: binaries are portable and can be executed on a more recent kernel

## Internal API/ABI Instability

- Linux internal API is not stable: the source code of a driver is not portable across versions
  - In-tree drivers are updated by the developer proposing the API change
  - An out-of-tree driver compiled for a given version may no longer compile or work on a more recent one
- Linux internal ABI is not stable: a binary module compiled for a given kernel version cannot be used with another version (the module loading utilities will perform this check prior to the insertion)
