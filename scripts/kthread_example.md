# Kthread Example

```c
#include <linux/delay.h>
#include <linux/kthread.h>
#include <linux/module.h>

// Module metadata
MODULE_AUTHOR("Zhou Qinren");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Kthread Example");

// Array for task_struct to hold task info
static struct task_struct* kthread_arr[4];

// Array for index
static int idx_arr[4];

// Indicates whether the thread has returned
static bool returned[4];

// Long-running function to be executed inside a thread, this will run for 30 secs.
int my_thread_function(void* idx) {
    unsigned int time_counter = 0;
    int thread_id = *(int*)idx;

    while (!kthread_should_stop()) { // kthread_should_stop() call is important!
        printk(KERN_INFO "Thread %d is still running...! %d secs.\n", thread_id, time_counter);
        time_counter += 5;
        if (time_counter == 30)
            break;
        ssleep(5);
    }
    returned[thread_id] = true;
    printk(KERN_INFO "Thread %d stopped.\n", thread_id);
    return 0;
}

static int __init mod_init(void) {
    int i;
    printk(KERN_INFO "Initializing kthread module.\n");
    for (i = 0; i < 4; i++) { // Initialize index array.
        idx_arr[i] = i;
        returned[i] = false;
    }
    for (i = 0; i < 4; i++) { // Initialize one thread at a time.
        kthread_arr[i] = kthread_run(my_thread_function, &idx_arr[i], "my_kthread_%d", idx_arr[i]);
        if (IS_ERR(kthread_arr[i])) {
            printk(KERN_INFO "ERROR: Cannot create my_kthread_%d.\n", i);
            return PTR_ERR(kthread_arr[i]);
        }
    }
    printk(KERN_INFO "All of the threads are running.\n");
    return 0;
}

static void __exit mod_exit(void) {
    int idx, ret;
    printk(KERN_INFO "Exiting kthread module.\n");
    for (idx = 0; idx < 4; idx++) { // Stop all of the kthreads before removing the module.
        if (returned[idx])          // Don't call kthread_stop() on thread that has already exited
            continue;
        ret = kthread_stop(kthread_arr[idx]);
        if (ret) {
            printk("Cannot stop kthread %d.\n", idx);
        }
    }
    printk(KERN_INFO "All of the kthreads are stopped.\n");
}

module_init(mod_init);
module_exit(mod_exit);
```
