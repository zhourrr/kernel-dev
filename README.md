# Kernel Development

A kernel is a program that constitutes the central core of a computer operating system. It is responsible for translating the command into something that can be understood by the computer hardware. It is the first thing that is loaded into memory when a computer is booted up (i.e., started), and it remains in memory for the entire time that the computer is in operation. An executable, also called an executable file, is a file that can be run as a program.

## Kernel and Operating System

The kernel is a part of an operating system. An operating system is something that includes a kernel plus quite a few lower-level applications (file manager, control panel, etc.) to make computers more user-friendly.

A distribution is an operating system packaged with distribution-specific patches which aim to make the system more usable.

## [Kernel Source Index Tool Elixir](https://elixir.bootlin.com)

## [References](./references/README.md)

## Table of Contents

1. [Kernel Source Tree](./notes/kernel-source/kernel-source-tree.md)
    - [Setting Up a Virtual Machine](./notes/kernel-source/setting-up-VM.md)
    - [Setting Up VSCode and clangd for Kernel Development](./notes/kernel-source/setting-up-vscode-and-clangd.md)
1. [Boot Process](./notes/kernel-source/boot-process.md)
    - [GRUB Configuration](./notes/kernel-source/GRUB-configuration.md)
1. [Compiling Kernel](./notes/kernel-source/compiling-kernel.md)
1. [Hello World Module](./notes/kernel-module/hello-world-module.md)
    - [In-Tree Module](./notes/kernel-module/in-tree-module.md)
    - [Symbols and Module Export](./notes/kernel-module/symbols-and-module-export.md)
    - [Kernel Context and Thread](./notes/kernel-module/kernel-context-and-thread.md)
1. [Tracing System Overview](./notes/kernel-trace/tracing-system-overview.md)
    - [ftrace](./notes/kernel-trace/ftrace.md)
    - [Kernel Tracepoints](./notes/kernel-trace/kernel-tracepoints.md)
    - [Kprobe](./notes/kernel-trace/kprobe.md)
    - [Perf](./notes/kernel-trace/perf.md)
    - [eBPF](./notes/kernel-trace/ebpf.md)
1. [Kernel Utilities](./notes/kernel-utilities/kernel-utilities.md)
    - [Data Types](./notes/kernel-utilities/data-types.md)
    - [Preemption](./notes/kernel-utilities/preemption.md)
    - [Floating-Point Operations](./notes/kernel-utilities/floating-point-operations.md)
    - [Kernel Debugging](./notes/kernel-utilities/kernel-debugging.md)
1. [Namespace and Isolation](./notes/kernel-filesystem/namespace-and-isolation.md)
1. [Filesystem](./notes/kernel-filesystem/filesystem.md)
1. [User-Kernel Communication](./notes/kernel-filesystem/user-kernel-communication.md)
1. [Kernel Unit Test](./notes/kernel-utilities/kunit.md)
