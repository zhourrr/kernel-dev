# User-Kernel Communication

`__user` is a macro that annotates the following pointer arguments that point to user-space memory. This doesn't have an effect on the actual execution of the code, but it is useful for documentation and is used by some tools to catch potential bugs.

```c
int my_func(void __user *user_ptr);
```

## Table of Contents

1. [system() Function](#system-function)
1. [copy_to_user() and copy_from_user() Functions](#copy_to_user-and-copy_from_user-functions)
1. [Reading and Writing Files Within the Kernel](#reading-and-writing-files-within-the-kernel)
1. [proc Filesystem](#proc-filesystem)
1. [sys Filesystem](#sys-filesystem)
1. [ioctl() Function](#ioctl-function)

## `system()` Function

```c
#include <stdlib.h>
int system(const char *command);
```

`system()` function executes a command specified in `command`, and returns after the command has been completed. You can call it inside a user-space application program.

Example

```c
if (system("insmod /path/to/helloWorld.ko") == 0) {
    printf("Module loaded successfully.");
}
```

## `copy_to_user()` and `copy_from_user()` Functions

Kernel code isn’t allowed to directly access user space memory, using `memcpy()` or direct pointer dereferencing, because the kernel can write to any address it wants. If you just use a user-space address you got, an attacker could write to or copy from kernel data. `copy_to_user()/copy_from_user()` checks that the address is valid and can be accessed by the current process.

**Rule of Thumb**:  
*Whenever the pointer is specified by the user-space process, either indirectly or directly, you use `copy_to_user()/copy_from_user()`. You only use `memcpy()` with pointers internal to the kernel that are never supplied to user space.*

Both `copy_to_user()` and `copy_from_user()` take three parameters: the `to` pointer (destination buffer), the `from` pointer (source buffer), and `n`, the number of bytes to copy.  
The return value is the number of uncopied bytes; in other words, a return value of 0 indicates success and a non-zero return value indicates that the given number of bytes were not copied. If a non-zero return occurs, you should return an error indicating an I/O fault.

```c
unsigned long copy_to_user(void __user *to, const void *from, unsigned long n);
unsigned long copy_from_user(void *to, const void __user *from, unsigned long n);
```

Example

```c
static ssize_t read_method(struct file *filp, char __user *ubuf, size_t count, loff_t *off) {
    char *kbuf = kzalloc(...);
    /* ... do what's required to get data from the hardware device into kbuf ... */
    [ ... ]
    if (copy_to_user(ubuf, kbuf, count)) { goto read_fail; }
    /* ... do something else ... */
    [ ... ]
    return count;   /* success */
read_fail:
    kfree(kbuf);
    return -EIO;    /* error */
}
```

## Reading and Writing Files Within the Kernel

Usually, it is **not recommended to read or write a file within the kernel**.

- Writing a file interpreter from within the kernel is a process ripe for problems and bugs. Any errors in the interpreter could cause the buffer overflows, which might allow unprivileged users to take over a machine or get access to protected data.
- Having a module read/write a file from/to a filesystem at a specific location forces the policy of the location of that file to be set. If a Linux distributor decides the easiest way to handle all configuration files for the system is to place them in the **/var/black/hole/of/configs** instead of the old configuration file directory, this kernel module has to be modified to support this change.
- Since Linux supports namespaces, some programs might see only portions of the entire filesystem, while others see the filesystem in different locations. Trying to determine that your module lives in the proper filesystem namespace is an almost impossible task.

However, the kernel still provides a few helper functions for you to manipulate files just in case it is really necessary.

- `filp_open()`
- `filp_close()`
- `kernel_read()`
- `kernel_write()`

## `proc` Filesystem

Linux has a virtual filesystem named `proc` which is used for dealing with **kernel internals**; the default mount point for it is `/proc`. The first thing to realize regarding the `proc` filesystem is that its content is not on a non-volatile disk. Its content is in RAM, and is thus volatile. The files and directories you can see under `/proc` are pseudo files that have been set up by the kernel code for `proc`; the kernel hints at this fact by (almost) always showing the file's size as zero.

- The directories under `/proc` whose names are integer values represent processes currently alive on the system. The name of the directory is the **PID** of the process (technically, it's the **TGID** of the process). The folder – `/proc/PID/` – contains information regarding this process. For example, for the **init** or **systemd** process (always PID 1), you can examine detailed information about this process (its attributes, open files, memory layout, children, and so on) under the `/proc/1/` folder.

- There are also many directories and files in `/proc` that do not correspond to processes and have non-numeric names. They correspond to general kernel configuration and information. For example, the `/proc/kallsyms` pseudo-file gives the symbolic names of kernel functions and variables from the loaded modules. It provides a listing of all the symbolic links to memory addresses for the kernel's exported symbols. See [here](../kernel-module/symbols-and-module-export.md#kallsyms) for more information.

### Purpose Behind the `proc` Filesystem

1. It is a simple interface for developers, system administrators, and anyone really to look deep inside the kernel so that they can gain information regarding the internals of processes, the kernel, and even hardware. Using this interface only requires you to know basic shell commands such as `cd`, `cat`, `echo`, `ls`, and so on.
2. As the root user and, at times, the owner, you can write into certain pseudo files under `/proc/sys`, thus tuning various kernel parameters. This feature is called `sysctl`.

For example, to change the maximum number of threads allowed at any given point in time:

```bash
echo 10000 > /proc/sys/kernel/threads-max
cat /proc/sys/kernel/threads-max

result: 10000
```

However, it should be clear that the preceding operation is volatile – the change only applies to this session; a power cycle or reboot will result in reverting back to the default value.

## `sys` Filesystem

`sysfs` is a virtual filesystem typically mounted on the `/sys` directory. In effect, `sysfs`, very similarly to `procfs`, is a kernel-exported tree of information (hardware and logical device) that's sent to the user space. Via `sysfs`, you can view the system in several different ways or via different "viewports"; for example, you can view the system via the various buses it supports (the bus view), via various "classes" of devices (the class view), via the devices themselves, and so on.

## `ioctl()` Function

```c
#include <sys/ioctl.h>
int ioctl(int fd, int cmd, ... /* arg */);
```

`ioctl()` (input/output control) is a system call for device-specific input/output operations and other operations which cannot be expressed by regular system calls. The argument `fd` must be an open file descriptor. The `cmd` argument and an optional third argument (with varying type) are passed to and interpreted by the device associated with `fd`. The `cmd` argument selects the control function to be performed and will depend on the device being addressed.
