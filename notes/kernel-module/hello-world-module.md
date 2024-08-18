# Hello World Module

Your first loadable kernel module. When loading into the kernel, it will generate a "Hello World" message. When unloading the kernel module, a "Bye" message will be generated.

## Table of Contents

1. [Kernel Source Tree](#kernel-source-tree)
1. [Notes on Compiling a Module](#notes-on-compiling-a-module)
1. [Writing Hello World Module](#writing-hello-world-module)
1. [Compiling Kernel Modules](#compiling-kernel-modules)
1. [Loading and Unloading the Kernel Module](#loading-and-unloading-the-kernel-module)
1. [A More Complicated Makefile](#a-more-complicated-makefile)
1. [Module Parameters](#module-parameters)

## [Kernel Source Tree](../kernel-source/kernel-source-tree.md)

In order to compile a kernel module, you need at least part of a kernel source tree against which to compile. That’s because when you write your module, all of the libraries or helper routines you use do not refer to the normal user space files. Rather, they refer to the kernel space header files found in the kernel source tree. Therefore, you have to have the relevant portion of some kernel tree available to build against.

You can either download your own kernel source tree for this or install the official kernel development package ***that matches your running kernel***. Kernel development package normally installs under **/usr/src/kernel-version**.

Example

```bash
sudo apt install linux-headers-$(uname -r)
```

## Notes on Compiling a Module

- **Out of tree**, when the code is outside the kernel source tree, in a different directory
  - Not integrated into the kernel configuration/compilation process
  - Needs to be built separately
  - The driver cannot be built statically, only as a module
- **Inside the kernel tree**
  - Well-integrated into the kernel configuration/compilation process
  - The driver can be built statically or as a module

## Writing Hello World Module

Create a new directory to place the **Hello World** kernel module.

```bash
mkdir hello_module
cd hello_module
```

Create a **hello_mod.c** file.

```c
/* Module Source File 'hello_mod.c'. */

#include <linux/module.h>

// Module metadata
MODULE_AUTHOR("Zhou Qinren");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Hello World Module");

static int __init hello(void) {
  // \n flushes the message immediately
  printk(KERN_INFO "Hello World! Module being loaded.\n");
  return 0; // To signify a successful load
}

static void __exit bye(void) {
  // \n flushes the message immediately
  printk(KERN_INFO "Bye! Module being unloaded.\n");
}

module_init(hello); // What is called upon loading this module
module_exit(bye);   // What is called upon unloading this module
```

### `__init` and `__exit` Macros

The `__init` macro tells the linker to place the code in a dedicated section into the kernel object file. This section is known in advance to the kernel, and freed when the module is loaded and the init function finished. This applies only to built-in drivers, not to loadable modules. The kernel will run the init function of the driver for the first time during its boot sequence. Since the driver cannot be unloaded, its init function will not be called again until the next reboot. There is no need to keep references on its init function anymore.

The `__exit` macro causes the omission of the function when the module is built into the kernel, and like `__init` , has no effect for loadable modules. Again, if you consider when the cleanup function runs, this makes perfect sense; built-in drivers do not need a cleanup function, while loadable modules do.

### `module_init` and `module_exit` Macros

Kernel modules always begin with the function you specify with the `module_init` call. This is the entry function for modules; it tells the kernel what functionality the module provides and sets up the kernel to run the module’s functions when they are needed. Once it does this, entry function returns and the module does nothing until the kernel wants to do something with the code that the module provides.

All modules end by calling the function you specify with the `module_exit` call. This is the exit function for modules; it undoes whatever entry function did. It unregisters the functionality that the entry function registered.

### printk

Kernel programming rule one: **you don’t normally interact with user space, so don’t expect to see `printk()` output coming back to your terminal**.

The `printk()` function is the kernel’s version of the classic print function in C language, which prints to the kernel logs. You have the `KERN_INFO` macro for logging general information. You can also use macros like `KERN_ERROR` in case an error occurs, which will alter the output format.

## Compiling Kernel Modules

Compiling a kernel module differs from compiling an user program. First, kernel space headers should be used. The module should not be linked to user space libraries. Additionally, the module must be compiled with the same options as the kernel in which we load the module. For these reasons, there is a standard compilation method **Kbuild**.

### Goal Definitions

Goal definitions define the files to be built, any special compilation options, and any subdirectories to be entered recursively.

- Built-in object goals - `obj-y`

    The Kbuild Makefile specifies object files for **vmlinux** in the `$(obj-y)` lists. These lists depend on the kernel configuration. Kbuild compiles all the `$(obj-y)` files, which will be later linked into **vmlinux**.

- Loadable module goals - `obj-m`

    `$(obj-m)` specifies object files which are built as loadable kernel modules.

Example

```makefile
obj-$(CONFIG_FOO) += foo.o
```

`$(CONFIG_FOO)` option indicates whether **FOO** feature should be included. It is set through **.config** file and evaluates to either **y** (for built-in) or **m** (for module). If `CONFIG_FOO` is neither **y** nor **m**, then the corresponding source file will not be compiled nor linked.

### Kbuild Makefile

Contained in this file will be the name of the module(s) being built, along with the list of requisite source files. The file may be as simple as a single line:

```makefile
obj-m := <module_name>.o
```

The Kbuild system will build **\<module_name\>.o** from **\<module_name\>.c** (auto-dependency generation), and after linking, will result in the kernel module **\<module_name\>.ko**.

When the module is built from multiple sources, an additional line is needed listing the files:

```makefile
obj-m := <module_name>.o
<module_name>-y := <src1>.o <src2>.o ...
```

If you want to build multiple separate kernel modules with one Makefile, you can list all of them in the `obj-m` variable.

```makefile
obj-m += module1.o
obj-m += module2.o
obj-m += module3.o
```

Below is the Makefile for our module. From a technical point of view just the first line is really necessary, the `all` and `clean` targets were added for pure convenience (not used by Kbuild). Compile our module by running `make`.

```makefile
# Makefile

obj-m := hello_mod.o

LINUX_KERNEL := $(shell uname -r)
LINUX_KERNEL_PATH := /usr/src/linux-headers-$(LINUX_KERNEL)

all:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) modules

install:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) modules_install

clean:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) clean
 ```

The command to build an external module is (the default target is `modules` when no target is specified, the output files will be generated in current directory):

```makefile
make -C <path_to_kernel_src> M=$(PWD)
```

The command to install the module just built is:

```makefile
make -C <path_to_kernel_src> M=$(PWD) modules_install
```

Options:

- `-C $Kernel_DIR`: The directory where the kernel source is located. **make** will actually change to the specified directory when executing and will change back when finished.
- `M=$(PWD)`: Informs Kbuild that an external module is being built. The value given to `M` is the absolute path of the directory where the external module (Kbuild file) is located.

## Loading and Unloading the Kernel Module

After compiling the kernel module, a file named **hello_mod.ko** was generated. This is a fully functional, compiled kernel module.

### Load the Module

```bash
sudo insmod hello_mod.ko
```

You can verify this by running `lsmod`, which lists all of the modules currently in the kernel. You can also run `lsmod | grep hello_mod`.

In the module source code, we print a "Hello World" message, to see that you can run `sudo dmesg` which prints the kernel’s logs to the screen and prettifies it a bit so that it’s more readable.

#### A tip about `dmesg`

```bash
dmesg -T --follow
```

- `-T` enables timestamps
- `--follow` enables real-time (continuous) logs

```bash
dmesg -T --follow | tee log.txt
```

Writes to both the standard output and a file named **log.txt**.

```bash
dmesg -c
```

Prints the kernel message buffer and clears it.

### Unload the Module

```bash
sudo rmmod hello_mod
```

You can verify this by running `lsmod | grep hello_mod` and `sudo dmesg`.

## A More Complicated Makefile

The example below demonstrates how to create a build file for the out-of-tree (external) module **8123.ko**, which is built from the following files:

- 8123_if.c
- 8123_if.h
- 8123_pci.c
- 8123_bin.o_shipped (a binary blob)

```makefile
# Makefile

ifneq ($(KERNELRELEASE),)
# Kbuild part of Makefile
obj-m  := 8123.o
8123-y := 8123_if.o 8123_pci.o 8123_bin.o

else
# Normal Makefile
LINUX_KERNEL := $(shell uname -r)
LINUX_KERNEL_PATH := /usr/src/linux-headers-$(LINUX_KERNEL)
all:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) modules

install:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) modules_install

clean:
    $(MAKE) -C $(LINUX_KERNEL_PATH) M=$(PWD) clean


# Module specific targets
createBin:
    echo "X" > 8123_bin.o_shipped

endif
```

An external module always includes a wrapper that supports building the module using `make` with no arguments. This target is not used by Kbuild; it is only for convenience. Additional functionality, such as test targets, can be included but should be filtered out from Kbuild due to possible name clashes.

The check for `KERNELRELEASE` is used to separate the two parts of the Makefile. In the example, Kbuild will only see the first two assignments, whereas `make` will see everything except these two assignments. This is due to two passes made on the file:

1. The first pass is by the `make` instance run on the command line. At this point, `KERNELRELEASE` is not defined, so the `else` part is executed and it calls the kernel Makefile, passing the module directory in the `M` variable;
2. The second pass is by the Kbuild system, which is initiated by the parameterized `make` in the `all` target (it will go into `$(LINUX_KERNEL_PATH)` and call the top-level Makefile, which defines `KERNELRELEASE`). The top-level Makefile knows how to compile a kernel module and recursively calls the Makefile in the current directory (thanks to the `M` variable), but this time `KERNELRELEASE` is defined, so the `if` part is executed.

### Include Files

External modules tend to place header files in a separate **include/** directory. To inform Kbuild of the
directory, use `ccflags-y` flag.

Example

```makefile
obj-m := 8123.o
ccflags-y := -I$(Include_DIR)
8123-y := 8123_if.o 8123_pci.o 8123_bin.o
```

### `ccflags-y`

This flag only applies to the Kbuild file in which it is assigned. It is used for the compiler.

### `CFLAGS_${filename}.o`

This flag only applies to commands in the Kbuild file in which it is assigned. It specifies per-file options associated with file `${filename}` for the compiler.

Example

```makefile
CFLAGS_my_file1.o = -DDEBUG
CFLAGS_your_file2.o = -I$(src)/include
```

These two lines specify compilation flags for **my_file1.o** and **your_file2.o**.

## Module Parameters

We can pass arguments to kernel modules.

### Setting a Module Parameter

```c
module_param(
    name,   /* name of an already defined variable */
    type,   /* data type */
    perm    /* permission mask, for exposing parameters in sysfs (if non-zero) at a later stage */
);

MODULE_PARM_DESC(name, "Description");  /* Description of the parameter */
```

The variable will be set to the value passed to the kernel module.

Example

```c
#define DEFAULT_PARAM1 100
#define DEFAULT_PARAM2 200

int param1 = DEFAULT_PARAM1;
int param2 = DEFAULT_PARAM2;

// Get the parameters.
module_param(param1, int, 0);
module_param(param2, int, 0);

static int __init my_init(void)
{
    if (param1 == DEFAULT_PARAM1) {
        printk(KERN_INFO "Nothing passed or Default Value :%d: for param1 is passed\n", DEFAULT_PARAM1);
    } else {
        printk(KERN_INFO "param1 passed is :%d:", param1);
    }

    if (param2 == DEFAULT_PARAM2) {
        printk(KERN_INFO "Nothing passed or Default Value :%d: for param2 is passed\n", DEFAULT_PARAM2);
    } else {
        printk(KERN_INFO "param2 passed is :%d:", param2);
    }

    return 0;
}
```

```bash
sudo insmod my_module.ko param1=1000
```

Modules parameter arrays are also possible with `module_param_array()`.

### Module Parameters in **sysfs**

The parameters of a module can be found in **/sys/module/$(module_name)/parameters/**, which contains individual files that are each individual parameters of the module that are able to be changed at runtime.

The permission mask dictates who is allowed to do what with the parameter file under **/sys/module/**. If you create a parameter with a permission setting of `0`, that means that parameter will not show up under **/sys/module/** at all, so no one will have any read or write access to it whatsoever (not even root). The only use that parameter will have is that you can set it at module load time, and that’s it.

The permission `0660` (an octal number) indicates read-write access for the owner and group and no access for others.

```c
module_param(param1, int, 0660);
```

You can change a parameter value at runtime like this:

```bash
sudo sh -c "echo 42 > /sys/module/my_module/parameters/param1"
```

Please note that *if you choose to define writable parameters and really do write/update them at runtime, your module is not informed that the value has changed*. That is, there is no callback or notification mechanism for modified parameters; the value will quietly change in your module while your code keeps running, oblivious to the fact that there’s a new value in that variable (if you truly need write access to your module and some sort of notification mechanism, you probably don’t want to use module parameters for this purpose).
