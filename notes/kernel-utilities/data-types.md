# Data Types

Linux kernels are highly portable, running on numerous different architectures.

Data types used by kernel data are divided into three main classes:

- traditional `C` types such as `int`
- explicitly sized types such as `u32`
- types used for specific kernel objects, such as `pid_t`

Note that the traditional `C` data types are not the same size on all architectures.

## Sized Types

Sometimes kernel code requires data items of a specific size, perhaps to match pre-defined binary structures, to communicate with user space, or to align data within structures by inserting “padding” fields. The kernel offers the sized data types to use whenever you need to know the size of your data. Include **<linux/types.h>** if you want to use them.

Examples

```c
u8;     /* unsigned byte (8 bits) */
u16;    /* unsigned 16-bit value */
u32;    /* unsigned 32-bit value */
u64;    /* unsigned 64-bit value */
```

Note that the above types are Linux-specific, and using those types makes it hard to port the driver to other operating systems.

`C` language has introduced standard fixed-width types defined in **<stdint.h>**, such as `uint8_t`, `uint32_t`, and `int64_t`. You can use `C`  fixed-width types to preserve portability. As long as a compiler is able to compile a modern Linux kernel, it has support for fixed-width types, so feel free to use them. In fact, Linux `typedef`s its own sized types as `C` standard fixed-width types, e.g., `typedef u64 uint64_t;`.

### History

Linux-specific sized types predate `C` standard fixed-width types.
