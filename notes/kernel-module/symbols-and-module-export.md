# Symbols and Module Export

## Name Space

When you write a small program, you use variables which are convenient and make sense to the reader. If, on the other hand, you are writing routines which will be part of a bigger problem, any global variables you have are part of a community of other people’s global variables; some of the variable names can clash. When a program has lots of global variables which aren’t meaningful enough to be distinguished, you get namespace pollution. In large projects, effort must be made to remember reserved names, and to find ways to develop a scheme for naming unique variables and symbols.

Generally the modules will never live alone. We need to divide the code into multiple modules for better organization and readability as well as we need to use the functionality which is available in other modules.

- Core kernel code can access any function or variable in any built-in modules, because they're linked together at compile time.

- The linking and invoking rules are much more stringent for loadable modules than code in the core kernel image. When modules are loaded they are dynamically linked into the kernel and can only call external functions that are explicitly **exported** for use. This allows the kernel to control the interface that modules use to interact with it and each other, and helps maintain stability and compatibility across different kernel versions.

In general, you can think of kernel symbols as visible at three different levels in the kernel source code:

- **static**: visible only within their own source file
- **external**: potentially visible to any other code built into the kernel itself
- **exported**: visible and available to any loadable module

However, it is important to remember that a ***kernel module is just a piece of kernel code and one can access non-exported symbols directly using the memory address (not the symbol name)***, though it's not recommended. If you have the memory address of a function (i.e., a function pointer), you can dereference the pointer to make use of that symbol, even if it is non-exported.

## **kallsyms**

The file **/proc/kallsyms** holds all the global symbols in the kernel and the loaded modules, which are accessible to your modules since they share the kernel’s code space. Each line in **/proc/kallsyms** corresponds to one symbol and provides:

- the memory address where the symbol is loaded,
- the type of symbol,
- the symbol's name,
- and the module which the symbol is from (this field is empty if the symbol is built into the core).

When an external module is loaded, any symbol exported by the module becomes part of the kernel symbol table, and you can see it appear in  **/proc/kallsyms**.

Note that **/proc/kallsyms** might show zeros instead of the real memory addresses of symbols for a non-root user. This lowers the security risk.

Some common symbol types:

- `b` or `B`: These symbols generally represent uninitialized variables. `b` for local symbols and `B` for global symbols.
- `d` or `D`: These symbols generally represent initialized variables. `d` for local symbols and `D` for global symbols.
- `t` or `T`: These symbols generally represent functions. `t` for local symbols and `T` for global symbols.

To find a symbol

```bash
sudo grep symbol_name /proc/kallsyms
```

## `EXPORT_SYMBOL()` Macro

- `EXPORT_SYMBOL()` is used to make kernel symbols (functions and data structures) available to all loadable modules; only the symbols that have been explicitly exported can by used by modules.
- Your module will not load if it is expecting a symbol that is not present in the kernel (you would get an `Unknown Symbol` error).
- Similarly, your module will not unload if some other modules depend on it.
- `EXPORT_SYMBOL_GPL()` exports only to **GPL-licensed** modules.

Module 1:

```c
int GLOBAL_VARIABLE = 1000;
EXPORT_SYMBOL(GLOBAL_VARIABLE);

/*
 * Function to print hello for num times.
 */
void print_hello(int num)
{
    while (num--) {
        printk(KERN_INFO "Hello Friend!!!\n");
    }
}
EXPORT_SYMBOL(print_hello);

static int __init my_init(void)
{
    printk(KERN_INFO "Hello from Module 1.\n");
    return 0;
}

static void __exit my_exit(void)
{
    printk(KERN_INFO "Bye from Module 1.\n");
}

module_init(my_init);
module_exit(my_exit);
```

Module 2:

```c
extern int GLOBAL_VARIABLE;
extern void print_hello(int);

/*
 * The function has been written just to call the functions which are in other module.
 */
static int __init my_init(void)
{
    printk(KERN_INFO "Hello from Module 2.\n");
    print_hello(10);
    printk(KERN_INFO "Value of GLOBAL_VARIABLE %d\n", GLOBAL_VARIABLE);
    return 0;
}

static void __exit my_exit(void)
{
    printk(KERN_INFO "Bye from Module 2.\n");
}

module_init(my_init);
module_exit(my_exit);
```

## Relevant Files

During a kernel/module build, some relevant files are generated:

- **Module.symvers** file contains all exported symbols from the compiled modules
- **modules.order** file specifies the order in which the modules should be loaded

## Symbols and External Modules

When building an external module, the build system needs access to the symbols from the kernel to check if all external symbols are defined. This is done in the **modpost** step. **modpost** obtains the symbols by reading **Module.symvers** from the kernel source tree. During the **modpost** step, a new **Module.symvers** file will be written to the module directory containing all exported symbols from that external module.

### Symbols From Another External Module

Sometimes, an external module uses exported symbols from another external module. **Kbuild** needs to have full knowledge of all symbols to avoid spitting out warnings and errors about undefined symbols. Two solutions exist for this situation.

- **Use a top-level kbuild file**:  
    If you have two modules, **foo.ko** and **bar.ko**, where **foo.ko** needs symbols from **bar.ko**, you can use a common top-level kbuild file so both modules are compiled in the same build. Consider the following directory layout:

    ![Two External Modules](../images/two-external-modules.png)

    The top-level kbuild file would then look like:

    ```makefile
    obj-m += foo/
    obj-m += bar/
    ```

- **Use `make` variable `KBUILD_EXTRA_SYMBOLS`**:  
    If it is impractical to add a top-level kbuild file, you can assign a space-separated list of files to `KBUILD_EXTRA_SYMBOLS` in your build file. These files will be loaded by **modpost** during the initialization of its symbol tables.

    ```makefile
    obj-m := foo.o
    KBUILD_EXTRA_SYMBOLS := /home/your-user/path/to/bar/Module.symvers
    ```

## **modprobe**

**modprobe** is an intelligent command to add or remove a module from the Linux kernel and takes care of their dependencies. **insmod** on the other hand does not handle dependencies automatically. In fact, **modprobe** makes use of the lower-level **insmod** under the hood.

**modprobe** usually looks in the module directory **/lib/modules/$(uname -r)** for all the modules and other files.
