# Floating-Point Operations

Floating-point operations are generally avoided in the kernel. When floating-point numbers are used in Linux kernel code, all floating-point calculations must be guarded between a pair of macros `kernel_fpu_begin()` and `kernel_fpu_end()`, since the Linux kernel doesn’t save and restore **floating-point unit** (FPU) states at context switches.

```c
#include <asm/fpu/api.h>
kernel_fpu_begin();
/*
 * use floating-point operations
 */
kernel_fpu_end();
```

The Linux kernel does not use floating-point operations because some computer systems might not have an FPU and not having to save and restore FPU states allows faster context switches. As a result, the use of floating-point numbers might bring extra overhead to calculation-heavy application, and that can be avoided by using fixed-point numbers at cost of precision.

## `kernel_fpu_begin()` and `kernel_fpu_end()`

They are defined in **asm/fpu/api.h**, `kernel_fpu_begin()` saves the FPU context if it's necessary and allows the kernel to use FPU instructions. The `kernel_fpu_end()` is then used to restore the FPU context if it was previously saved.

You need to make sure you don't do anything that might fault or [sleep](./preemption.md#blocking-functions-vs-non-blocking-functions) in between the two macros, because `kernel_fpu_xxx()` macros make sure that preemption is turned off.

### Be Careful

Failure to use `kernel_fpu_xxx()` doesn’t necessarily mean FPU instructions will fault. Instead it will silently corrupt user-space’s FPU state (user-space program could also corrupt kernel's FPU state). This is bad; don’t do it.

## Compilation Flags

Normally kernel code is not expected to use floating-point operations and the kernel does not link with standard `C` library, so you can't use any fancy floating-point operations except for those that the compiler can do in-line, without any function calls.

To use fancy floating-point operations, you need to add a few flags to your compiler. The following are some commonly used ones:

- `-msse`  
    Enables the use of **SSE** (Streaming SIMD Extensions) instructions. Note that using **SSE** instructions requires a processor that supports them.
- `-msse2`  
    Enables the use of **SSE2** instructions. Note that using **SSE2** instructions requires a processor that supports them.
- `-msoft-float`  
    Instructs the compiler to generate code that uses software routines, instead of hardware instructions, to perform floating-point operations. This flag is primarily used when you want the compiled code to be compatible with systems that may not have an FPU. Note that this flag can significantly decrease the performance of programs that do a lot of floating-point calculations.
- `-mhard-float`  
    Instructs the compiler to generate code that uses the hardware FPU for floating-point operations. Note that the code compiled with `-mhard-float` is not compatible with systems that don't have a hardware FPU.

Example

```makefile
ccflags-y := -mhard-float -msse
```

### Additional Notes

Using `-msse` flag would reuslt in your compiler generating SSE instructions at disallowed places (outside `kernel_fpu_begin()` and `kernel_fpu_end()`). One workaround is to separate functions that use floating-point operations from those that do not use them, write them in different files, and only add `-msse` flag for the files that use floating-point operations. See [Kbuild Flags](../kernel-module/hello-world-module.md#a-more-complicated-makefile) for how to do that.
