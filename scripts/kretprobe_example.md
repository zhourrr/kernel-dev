# Kretprobe Example

```c
#include <linux/kernel.h>
#include <linux/kprobes.h>
#include <linux/ktime.h>
#include <linux/module.h>
#include <linux/sched.h>

/* per-instance private data */
struct my_data {
    ktime_t entry_stamp;
};

/* Here we use the entry_hanlder to timestamp function entry */
static int entry_handler(struct kretprobe_instance *ri, struct pt_regs *regs) {
    struct my_data *data;

     if (!current->mm)
        return 1; /* Skip kernel threads */

    data = (struct my_data *)ri->data;
    data->entry_stamp = ktime_get();
    return 0;
}
NOKPROBE_SYMBOL(entry_handler);

/*
 * Return-probe handler: Log the return value and duration. Duration may turn
 * out to be zero consistently, depending upon the granularity of time
 * accounting on the platform.
 */
static int ret_handler(struct kretprobe_instance *ri, struct pt_regs *regs) {
    unsigned long retval = regs_return_value(regs);
    struct my_data *data = (struct my_data *)ri->data;
    s64 delta;
    ktime_t now;

    now = ktime_get();
    delta = ktime_to_ns(ktime_sub(now, data->entry_stamp));
    pr_info("%s returned %lu and took %lld ns to execute\n", func_name, retval,
            (long long)delta);
    return 0;
}
NOKPROBE_SYMBOL(ret_handler);

static struct kretprobe my_kretprobe = {
    .handler = ret_handler,
    .entry_handler = entry_handler,
    .data_size = sizeof(struct my_data),
    /* Probe up to 20 instances concurrently. */
    .maxactive = 20,
};

static int __init kretprobe_init(void) {
    int ret;

    my_kretprobe.kp.symbol_name = "func_name";
    ret = register_kretprobe(&my_kretprobe);
    if (ret < 0) {
        pr_err("register_kretprobe failed, returned %d\n", ret);
        return ret;
    }
    pr_info("Planted return probe at %s: %p\n", my_kretprobe.kp.symbol_name,
            my_kretprobe.kp.addr);
    return 0;
}

static void __exit kretprobe_exit(void) {
    unregister_kretprobe(&my_kretprobe);
    pr_info("kretprobe at %p unregistered\n", my_kretprobe.kp.addr);

    /* nmissed > 0 suggests that maxactive was set too low. */
    pr_info("Missed probing %d instances of %s\n", my_kretprobe.nmissed,
            my_kretprobe.kp.symbol_name);
}

module_init(kretprobe_init);
module_exit(kretprobe_exit);
```
