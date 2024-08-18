# Kernel Context and Thread

## Table of Contents

1. [Kernel Context](#kernel-context)
1. [What is a Kernel Thread](#what-is-a-kernel-thread)
1. [Using a Kernel Thread](#using-a-kernel-thread)
1. [Wait for Completion](#wait-for-completion)

## Kernel Context

Usually, each of the CPUs in a system can be in one of the following states:

- not associated with any user process, serving an interrupt
  - serving a hardware interrupt
  - serving a software interrupt
- running in kernel space, associated with a user process
- running a user process in user space

Therefore, we generally have two contexts:

- **Process Context**:  
    A user-space process has both a user-space address space and a kernel-space address space. When the process or thread issues a system call, it switches to (privileged) kernel mode and executes kernel code, and possibly works on kernel data. In this case, we say that kernel code executes within the context of a user-space process – we call this the **process context** or **user context**. The kernel code also has access to the user-space address space. In **process context**, the `current` pointer (points to the currently executing task) is valid, and you can use it to access the information about the current process.
- **Interrupt Context**:  
    When an interrupt (e.g., from a keyboard) occurs, the CPU's control unit saves the current context and immediately switches to run the code of the interrupt handler (interrupt service routine — ISR). This interrupt handler runs in (privileged) kernel mode and we call this the **interrupt context**.  
    Hardware interrupt handler has to be fast, because the kernel guarantees that this handler is never re-entered: if the same interrupt arrives, it is queued (or dropped). Hardware interrupt handler usually just acknowledges the interrupt, marks a software interrupt for later execution and exits. Software interrupts are usually executed when a system call is about to return to user space or a hardware interrupt handler exits. Much of the real interrupt handling work is done in software interrupt handlers.

Kernel code is very **event-based**.

## What is a Kernel Thread

A thread is an execution path; it's purely concerned with executing a given function. That function is its life and scope; once the thread returns from that function, it's dead.

- In user space, a thread is an execution path within a process; processes can be single or multi-threaded.
- Kernel threads are very similar to user-mode threads, except that they run within the kernel virtual address space, with kernel privilege.

The majority of the kernel threads have been created for a definite purpose; often, they're created at system startup and run forever (in an infinite loop). They put themselves into a sleep state, and, when some work is required to be done, wake up, perform it, and go right back to sleep.

- Kernel threads run in process context and have a task structure (`PID` and all other typical thread attributes) but they run entirely in kernel space and do not have user-space memory map. Thus, their `current->mm` value is always `NULL` (you can use this to quickly identify a kernel thread).
- Kernel threads compete for the CPU resource with other threads, including user-mode threads, via the CPU scheduler (because they run in process context); kernel threads do get a slight bump in priority. Kernel threads can be preempted by the scheduler, can go to sleep, and can be awakened.

## Using a Kernel Thread

The primary API for creating kernel threads (that's exposed to module authors) is `kthread_create()`. However, calling `kthread_create()` alone isn't sufficient to have your kernel thread do anything useful; this is because, while this macro does create the kernel thread, you need to make it a candidate for the scheduler by setting its state to running and waking it up. This can be done with the `wake_up_process()` API (once successful, it's enqueued onto a CPU run queue, which makes it schedulable so that it runs in the near future). The good news is that the `kthread_run()` helper macro can be used to invoke both `kthread_create()` and `wake_up_process()` in one go.

```c
#include <linux/kthread.h>
struct task_struct* thread = kthread_run(threadfn, data, namefmt, ...);
```

- `threadfn` is the name of the function to run
- `data` is a pointer to the function arguments
- `namefmt` is the name of the thread, specified in a `printf` formatting string
- returns a `task_struct`

The moment `kthread_run()` succeeds in creating the kernel thread, it will begin running its code in parallel with the rest of the system: it's now a schedulable thread! A thread will continue to run even though it has nothing to do, which would eat up resources. Therefore, we usually put kernel threads to sleep and only wake them up when some event happens.

A kernel thread continues to exist until itself decides to exit. The thread should `return 0` if it has successfully finished its task. If it needs continuous execution, you should wrap it in an infinite `while` loop.

### `kthread_stop()` and `kthread_should_stop()`

A typical way to exit the infinite loop is to use `kthread_stop()`, passing in the address of the corresponding `task_struct` structure, to send the cancellation request to our kernel thread.

```c
int ret = kthread_stop(thread);
```

- sets `thread-­>kthread_should_stop` to `true`
- wakes up the thread
- waits for the thread to exit (`kthread_stop()` is a blocking function)
- cleans up the thread and returns the result of the thread function

The `kthread_should_stop()` routine returns a Boolean value that's `True` if the kthread should stop (terminate) now! Calling `kthread_stop()` in the cleanup code path will wake up the kernel thread and cause `kthread_should_stop()` to return `True`, thus causing our kernel thread to break out of the while loop and terminate via a simple `return 0`. This value (`0`) is passed back to `kthread_stop()`. *Note that calling `kthread_stop()` doesn't actually stop the thread, instead it just sets a flag indicating that thread should stop. It is totally up to the thread to decide, when it would like to exit. As a result, the thread function will not be interrupted in the middle of some important task. But, if the thread function never returns and does not check for signals, it will never actually stop.*

```c
while (!kthread_should_stop()) {
    /* do some work here */
    ...
    /* sleep for a while */
}

return 0;
```

Please note that you should not call `kthread_stop()` on threads that have already exited because the `task_struct` is no longer valid. In general, it is not a good practice to initiate the end of a thread from more than one context. You have to decide where the responsibility for stopping the thread lies. If it is within the thread, then it should simply return after it has finished its work. If it is external to the thread, then the thread should poll `kthread_should_stop()` until it is `True` and return.

### Example

See [here](../../scripts/kthread_example.md)

## `Wait for Completion`

If you have one or more threads that must wait for some kernel activity to have reached a point or a specific state, completions can provide a race-free solution to this problem. Completions are built on top of the `waitqueue` and `wakeup` infrastructure of the Linux scheduler. The event the threads on the `waitqueue` are waiting for is reduced to a simple flag in `struct completion`, appropriately called `done`.

There are three main parts to using completions:

1. The initialization of the `struct completion` synchronization object

1. The waiting part through a call to one of the variants of `wait_for_completion()`

1. The signaling side through a call to `complete()` or `complete_all()`

There are also some helper functions for checking the state of completions. Note that while initialization must happen first, the waiting and signaling part can happen in any order. I.e., it's entirely normal for a thread to have marked a completion as `done` before another thread checks whether it has to wait for it.

### Initialization

`struct completion` is defined in **<linux/completion.h>** as follows:

```c
struct completion {
    unsigned int done;
    wait_queue_head_t wait;
};
```

Initializing of dynamically allocated (and static) `completion` objects is done via a call to `init_completion()`;  
Initializing of static `completion` objects is done via a call to `DECLARE_COMPLETION()`.

```c
#include <linux/completion.h>

struct completion data_read_done;
init_completion(&data_read_done);
```

`reinit_completion()` should be used to reinitialize a `completion` structure so it can be reused (it simply resets the `done` field to 0 without touching the `waitqueue`). This is especially important after `complete_all()` is used. Callers of this function must make sure that there are no racy `wait_for_completion()` calls going on in parallel. Calling `init_completion()` on the same `completion` object twice is most likely a bug as it re-initializes the queue to an empty queue and enqueued tasks could get "lost".

### Waiting

For a thread to wait for some concurrent activity to finish, it calls `wait_for_completion()` on the initialized `completion` structure:

```c
wait_for_completion (struct completion *done);
```

A typical usage scenario is (this does not imply any particular order between `wait_for_completion()` and the call to `complete()`):

```bash
CPU#1                                       CPU#2

struct completion setup_done;

init_completion(&setup_done);
initialize_work(...,&setup_done,...);

/*run non-dependent code */                 /* do setup*/

wait_for_completion(&setup_done);           complete(&setup_done);
```

The default behavior is to wait without a timeout and to mark the task as `uninterruptible`. `wait_for_completion()` and its variants are only safe in process context (as they can sleep) but not in atomic context, interrupt context, with disabled IRQs, or preemption is disabled. Threads will be awakened in the same order in which they were queued (but do you really know the order in which they were queued?).

`int wait_for_completion_interruptible(struct completion *done)` marks the task `TASK_INTERRUPTIBLE` while it is waiting. `wait_for_completion()` will put the thread to sleep unconditionally until the `completion` is signaled. `wait_for_completion_interruptible()` will put the thread to sleep until the `completion` is signaled or a signal is received, e.g., interrupted by `KILL` signal, causing it to return early. Note that hardware interrupts can preempt both `wait_for_completion()` and `wait_for_completion_interruptible()`, but it won't cause them to return early.

Note that if your code calls `wait_for_completion()` and nobody ever `complete`s the task, the result will be an unkillable process.

### Signaling

A thread that wants to signal that the conditions for continuation have been achieved calls `complete()` to signal exactly one of the waiters that it can continue:

```c
void complete(struct completion *done)
```

or calls `complete_all()` to signal all current and future waiters:

```c
void complete_all(struct completion *done)
```

If `complete()` is called multiple times then this will allow for that number of waiters to continue - each call to `complete()` will simply increment the `done` field and each waiter will decrement (consume) it. Calling `complete_all()` multiple times is a bug though. Both `complete()` and `complete_all()` can be called in IRQ/atomic context safely. `complete()` and `complete_all()` are designed to be thread-safe (synchronized through the internal waitqueue spinlock). However, frequent concurrent calls to `complete()` or `complete_all()` are probably a design bug, because they are competing for the spinlock (if you have multiple threads that might call `complete` but the probability of concurrent execution is low, it's generally fine).

If `complete_all()` is not used, a `completion` structure can be reused without any problems as long as there is no ambiguity about what event is being signaled. If you use `complete_all()` then you must reinitialize the `completion` structure before reusing it.

The `try_wait_for_completion()` function will not put the thread on the wait queue but rather returns `false` if it would need to enqueue (block) the thread, else it consumes one posted `completion` and returns `true`.
