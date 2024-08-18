# Kernel Unit Test

**KUnit** is an in-kernel unit test framework.

Refer to [documentation](https://kunit.dev/) for its usage.

There are two ways of running **KUnit** tests:

- build the kernel with **KUnit** enabled, read out test results, and manually parse the results
- use **kunit_tool**, which is a `Python` script located in **tools/testing/kunit/kunit.py**, to configure and build a kernel, run tests and format the test results

## Table of Contents

1. [Configuring Tests with kunit_tool](#configuring-tests-with-kunit_tool)
1. [Running Tests with kunit_tool](#running-tests-with-kunit_tool)
1. [Writing Tests](#writing-tests)
1. [Running Tests without kunit_tool](#running-tests-without-kunit_tool)

## Configuring Tests with kunit_tool

**.kunitconfig** file is used to configure **KUnit** tests, which contains the regular Kernel configs and specific test targets.  
**kunit_tool** uses **.kunitconfig** to generate a kernel **.config** file, which is used to build the kernel. Note that `CONFIG_KUNIT=y` is set in **.kunitconfig** file because the compiled kernel must have **KUnit** enabled.

**kunit_tool** allows you to specify the build directory by `--build_dir` option. This build directory includes **.kunitconfig**, **.config** files and compiled kernel.  
By default, `--build_dir` is set to **.kunit** directory.

To create a default **.kunitconfig** file, run:

```bash
cd $PATH_TO_LINUX_REPO
cp tools/testing/kunit/configs/default.config .kunit/.kunitconfig
```

You can then add any other config options. For example:

```bash
CONFIG_LIST_KUNIT_TEST=y
```

You may want to remove `CONFIG_KUNIT_ALL_TESTS` from the **.kunitconfig** as it will enable a number of additional tests that you may not want.

If you add something to the **.kunitconfig**, **kunit.py** might trigger a rebuild of the **.config** file. But you can edit the **.config** file directly or with tools like `make menuconfig O=.kunit`. As long as its a superset of **.kunitconfig**, **kunit.py** won't overwrite your changes.

Note that the following command will create the **.kunit** directory and default **.kunitconfig** if they do not exist.

```bash
./tools/testing/kunit/kunit.py run
```

## Running Tests with kunit_tool

Once you have the **.kunitconfig** file, just run:

```bash
cd $PATH_TO_LINUX_REPO
./tools/testing/kunit/kunit.py run
```

This will configure and build a **UML** (User Mode Linux) kernel, run the specified tests, and print the results (nicely formatted) to the screen.

Because it is building a lot of sources for the first time, the building kernel step may take a while.

You can also pass some flags:

```bash
./tools/testing/kunit/kunit.py run --timeout=30 --jobs=24 --build_dir=.my_kunit_build_dir
```

- `--timeout` sets a maximum amount of time to allow tests to run.

- `--jobs` sets the number of threads to use to build the kernel.

- `--build_dir` specifies the build directory.

We can generate a **.config** from a **.kunitconfig** by using the `config` argument:

```bash
./tools/testing/kunit/kunit.py config
```

To build a **KUnit** kernel from the current **.config**, we can use the `build` argument:

```bash
./tools/testing/kunit/kunit.py build
```

If we already have built **UML** kernel, we can run the kernel, and display the test results with the `exec` argument:

```bash
./tools/testing/kunit/kunit.py exec
```

The `run` command is equivalent to running the above three commands in sequence.

## Writing Tests

### Test Cases

The fundamental unit in **KUnit** is a **KUnit test case**, which is a function with type signature `void test_function_name(struct kunit* test)`, and calls the various `KUNIT_EXPECT_*` macros to verify the state under test. A test case should be created with the `KUNIT_CASE` macro. You can use a `struct kunit_case` to group multiple test cases together.

```c
/* Test Cases */
#include <kunit/test.h>
#include "example.h"

static void example_test_foo(struct kunit *test)
{
    /* example_add is a function that adds two integers. */
    KUNIT_EXPECT_EQ(test, 1, example_add(1, 0));
    KUNIT_EXPECT_EQ(test, 2, example_add(1, 1));
    KUNIT_EXPECT_EQ(test, 0, example_add(-1, 1));
}

static void example_test_bar(struct kunit *test)
{
    /* KUNIT_FAIL is used to indicate a test failure. */
    KUNIT_FAIL(test, "This test never passes.");
}

static void example_test_baz(struct kunit *test)
{
    /* Do nothing. This test always passes. */
}

static struct kunit_case example_test_cases[] = {
    KUNIT_CASE(example_test_foo),
    KUNIT_CASE(example_test_bar),
    KUNIT_CASE(example_test_baz),
    {}
};
```

Each KUnit test function gets a `struct kunit` context object passed to it that tracks a running test. The KUnit assertion macros and other KUnit utilities use the `struct kunit` context object. Note that the first parameter of `KUNIT_EXPECT_EQ` is the `struct kunit` context object.

**KUnit** verifies state using expectations and assertions.

- `KUNIT_EXPECT_*`: if the check fails, marks the test as failed and logs the failure.
- `KUNIT_ASSERT_*`: if the check fails, marks the test as failed and terminates immediately.

### Test Suites

It is common to have many similar tests to cover all the unit's behaviors. A **KUnit suite** is a collection of test cases for a unit of code with optional setup and teardown functions that run before/after the whole suite and/or every test case. The **KUnit suites** are represented by the `struct kunit_suite`. For example:

```c
/* Test Suites */
static struct kunit_suite example_test_suite = {
    .name = "example",
    .init = example_test_init,
    .exit = example_test_exit,
    .test_cases = example_test_cases,
};

kunit_test_suite(example_test_suite);
```

In the above example, the test suite `example_test_suite`, runs the test cases `example_test_foo`, `example_test_bar`, and `example_test_baz`. Before running the test, the `example_test_init` is called, and after running the test `example_test_exit` is called.

The `kunit_test_suite(example_test_suite`) registers the test suite with the **KUnit** test framework.

### Configuration and Build Setup

See [here](../kernel-module/hello-world-module.md#compiling-kernel-modules) for how to compile a kernel module.

Assume our test file is named **example_test.c**, then add the following line to **Makefile**:

```makefile
obj-$(CONFIG_MY_EXAMPLE_TEST) += example_test.o
```

Add the following lines to **Kconfig**:

```makefile
config MY_EXAMPLE_TEST
    tristate "Test for my example" if !KUNIT_ALL_TESTS
    depends on MY_EXAMPLE && KUNIT=y
    default KUNIT_ALL_TESTS
```

`MY_EXAMPLE` refers to the example source code under test.

Then add the following line to **.kunitconfig**:

```makefile
CONFIG_MY_EXAMPLE_TEST=y
```

## Running Tests without kunit_tool

If you do not want to use **kunit_tool**, you can build a kernel with **KUnit** enabled, read out test results, and parse manually.

**KUnit** is configured with the `CONFIG_KUNIT` option.

In-tree tests can be built individually by enabling their config options in **.config** file. Most tests can either be built as a module, or be built into the kernel.  
We can enable the `KUNIT_ALL_TESTS` config option to automatically enable all tests with satisfied dependencies. This is a good way of quickly testing everything applicable to the current config.

Once we have built our kernel (and/or modules), it is simple to run the tests. If the tests are built-in (e.g., `CONFIG_KUNIT_EXAMPLE_TEST=y`), they will run automatically on the kernel boot. The results will be written to the kernel log. If the tests are built as modules (e.g., `CONFIG_KUNIT_EXAMPLE_TEST=m`), they will run when the module is loaded.

For external module test, you can write a `test.c` file which contains the **KUnit** tests, then add `obj-m += test.o` to your **Makefile**. Your test cases will be built as a kernel module, and they will run when you load this module.
