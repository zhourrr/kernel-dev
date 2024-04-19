# In-Tree Module

To add a new driver to the kernel source:

- Add your new source file to the appropriate source directory, e.g., **$(Kernel_Source_Dir)/drivers/my_module/**.
- Single-file drivers in the common case, even if the file is several thousand lines of code big. Only really big drivers are split in several files or have their own directory.
- Describe the configuration interface for your new module by adding the following lines to the **Kconfig** file in this directory:

    ```makefile
    menu "the menu in which the module should be"
    config MY_MODULE
        tristate "My new module"
        depends on MY_OLD_MODULE
        help
            This is my module!
            To compile this driver as a module, choose M.
    endmenu
    ```

- Create a **Makefile** based on the **Kconfig** setting:

    ```makefile
    obj-$(CONFIG_MY_MODULE) += my_module.o
    ```

    It tells the kernel-build system to build **my_module.c** when the `MY_MODULE` option is enabled. It works for both compiled statically or as a module.

- Add a line to **$(Kernel_Source_Dir)/drivers/Kconfig** so that Kconfig system is able to find the new module's **Kconfig** file:

    ```makefile
    source "drivers/my_module/Kconfig"
    ```

- Add a line to **$(Kernel_Source_Dir)/drivers/Makefile** so that Kbuild system is able to find the module and determine whether to compile it based on the configuration:

    ```makefile
    obj-y += my_module/
    ```

    or

    ```makefile
    obj-$(CONFIG_MENU_WHICH_MY_MODULE_IS_IN) += my_module/
    ```

## Kconfig File

The configuration database is a collection of configuration options organized in a tree structure. Every entry has its own dependencies. These dependencies are used to determine the visibility of an entry. Any child entry is only visible if its parent entry is also visible.

Every line starts with a key word and can be followed by multiple arguments. `config` starts a new config entry. The following lines define attributes for this `config` option. Attributes can be the type of the config option, input prompt, dependencies, help text and default values. A config option can be defined multiple times with the same name, but every definition can have only a single input prompt and the type must not conflict.

### Menu Attributes

A menu entry can have a number of attributes. But not all of them are applicable everywhere. Below are a few common ones:

- Type definition: `bool` / `tristate` / `string` / `hex` / `int`. Every config option must have a type. There are only two basic types: `tristate` and `string`; the other types are based on these two.
- Input prompt: `prompt <prompt> [ if <expr> ]`. Every menu entry can have at most one prompt, which is used to display to the user. Conditional dependencies for this prompt can be added with `if` (the prompt will be displayed if the `<expr>` evaluates to `true`). The type definition optionally accepts an input prompt, so these two examples are equivalent:

    ```makefile
    bool "Networking support"
    ```

    and

    ```makefile
    bool
    prompt "Networking support"
    ```

- Default value: `default <expr> [ if <expr> ]`. A config option can have any number of default values. If multiple default values are visible, only the first defined one is active. Default values are not limited to the menu entry where they are defined. This means the default can be defined somewhere else or be overridden by an earlier definition. The default value is only assigned to the config symbol if no other value was set by the user (via the input prompt above). If an input prompt is visible the default value is presented to the user and can be overridden by them. Conditional dependencies for this default value can be added with `if`.
**The default value deliberately defaults to `n` if no default value is provided in the Kconfig file in order to avoid bloating the build**. With few exceptions, new config options should not change this. The intent is for `make olddefconfig` to add as little as possible to the config from release to release.
  - type definition + default value: `def_bool/def_tristate <expr> [ if <expr> ]`. This is a shorthand notation for a type definition plus a default value.
- Dependencies: `depends on <expr>`.
    This defines a dependency for this menu entry. If multiple dependencies are defined, they are connected with `&&`. For example:

    ```makefile
    config OPTION_A
    bool "Option A"

    config OPTION_B
    bool "Option B"
    depends on OPTION_A
    ```

    In this case, `OPTION_B` can only be selected if `OPTION_A` is set to `y`. If `OPTION_A` is `n`, `OPTION_B` will not be available for selection in the configuration process, and it will be as if `OPTION_B` did not exist in the Kconfig files.

    Dependencies are applied to all other options within this menu entry (which also accept an `if` expression), so these two examples are equivalent:

    ```makefile
    bool "foo" if BAR
    default y if BAR
    ```

    and

    ```makefile
    depends on BAR
    bool "foo"
    default y
    ```

- Reverse dependencies (use with care!): `select <symbol> [ if <expr> ]`.

    ```makefile
    config OPTION_A
    bool "Option A"
    select OPTION_B

    config OPTION_B
    bool "Option B"
    ```

    In this case, if `OPTION_A` is enabled (set to `y`), then `OPTION_B` will automatically be enabled. This is useful if `OPTION_A` cannot function correctly without `OPTION_B` being enabled.

- Help text: `help`. This defines a help text. The end of the help text is determined by the indentation level, this means it ends at the first line which has a smaller indentation than the first line of the help text.

### Menu Structures

The position of a menu entry in the tree is determined in two ways. First it can be specified explicitly:

```makefile
menu "Network device support"
      depends on NET

config NETDEVICES
      ...

endmenu
```

All entries within the `menu` ... `endmenu` block become a submenu of `Network device support`. All subentries inherit the dependencies from the menu entry, e.g. this means the dependency `NET` is added to the dependency list of the config option `NETDEVICES`.

The other way to generate the menu structure is done by analyzing the dependencies. If a menu entry somehow depends on the previous entry, it can be made a submenu of it. First, the previous (parent) symbol must be part of the dependency list and then one of these two conditions must be true:

- the child entry must become invisible, if the parent is set to 'n'
- the child entry must only be visible, if the parent is invisible:

```makefile
config MODULES
    bool "Enable loadable module support"

config MODVERSIONS
    bool "Set version information on all module symbols"
    depends on MODULES

comment "module support disabled"
    depends on !MODULES
```

`MODVERSIONS` directly depends on `MODULES`, this means it's only visible if `MODULES` is different from `n`. The `comment` on the other hand is only visible when `MODULES` is set to `n`.

We can also use `menuconfig`.

```makefile
menuconfig <symbol>
<config options>
```

This is similar to the simple `config` entry above, but it also gives a hint to front ends, that all suboptions should be displayed as a separate list of options. To make sure all the suboptions will really show up under the `menuconfig` entry and not outside of it, every item in the `<config options>` list must depend on the `menuconfig` symbol. In practice, this is achieved by using one of the next two constructs:

```makefile
menuconfig M
if M
    config C1
    config C2
endif
```

```makefile
menuconfig M
config C1
    depends on M
config C2
    depends on M
```
