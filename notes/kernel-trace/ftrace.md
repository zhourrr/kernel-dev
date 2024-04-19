# ftrace

**ftrace** is an internal tracer designed to help out developers and designers of systems to find what is going on inside the kernel. It can be used for debugging or analyzing latencies and performance issues that take place outside of user space. **ftrace** is a framework of several assorted tracing utilities. One of the most common uses of **ftrace** is the event tracing. Through out the kernel is hundreds of static event points that can be enabled via the **tracefs** file system to see what is going on in certain parts of the kernel.

**ftrace** is a part of the Linux kernel and is usually automatically enabled.

## Table of Contents

1. [General Workflow (kind of annoying, though)](#general-workflow-kind-of-annoying-though)
1. [tracefs](#tracefs)
1. [Trace Filter](#trace-filter)
1. [Tracing Specific PID](#tracing-specific-pid)
1. [trace-cmd](#trace-cmd)

## General Workflow (kind of annoying, though)

1. Write to some specific files to enable/disable tracing.
2. Write to some specific files to set/unset filters to fine-tune tracing.
3. Read generated trace output from files based on 1 and 2.
4. Clear earlier output or buffer from files.
5. Narrow down to your specific use case (kernel functions to trace) and repeat steps 1, 2, 3, 4.

Example

```bash
cd /sys/kernel/tracing
echo function > current_tracer
echo do_page_fault > set_ftrace_filter
cat trace
```

## tracefs

**ftrace** uses the **tracefs** file system to hold the control files as well as the files to display output. When **tracefs** is configured into the kernel (it usually is), the directory **/sys/kernel/tracing/** will be created.

Key files:

- **current_tracer**: This is used to set or display the current tracer that is configured.
- **available_tracers**: This holds the different types of tracers that have been compiled into the kernel. The tracers listed here can be configured by `echo`ing their name into **current_tracer**.
- **tracing_on**: This sets or displays whether writing to the trace ring buffer is enabled. `echo 0` into this file to disable the tracer or `1` to enable it. Note, this only disables writing to the ring buffer, the tracing overhead may still be occurring.
- **trace**: This file holds the output of the trace in a human readable format. Note, tracing is temporarily disabled while this file is being read (opened). This file is static, and if the tracer is not adding more data, it will display the same information every time it is read.
- **trace_pipe**: The output is the same as the **trace** file but this file is meant to be streamed with live tracing. Reads from this file will block until new data is retrieved. But unlike the **trace** file, this file is a consumer. This means reading from this file causes sequential reads to display more current data. Once data is read from this file, it is consumed (flushed or cleared), and will not be read again with a sequential read.  This file will not disable tracing while being read.
- **trace_options**: This file lets the user control the amount of data that is displayed in one of the above output files. Options also exist to modify how a tracer or events work (stack traces, timestamps, etc).
- **snapshot**: This displays the snapshot buffer and also lets the user take a snapshot of the current running trace.

Key tracers:

- **nop**: This is the “trace nothing” tracer. To remove all tracers from tracing simply `echo nop` into **current_tracer**.
- **function**: Function call tracer to trace all kernel functions.
- **function_graph**: Similar to the **function** tracer except that the **function** tracer probes the functions on their entry whereas the **function_graph** tracer traces on both entry and exit of the functions. It then provides the ability to draw a graph of function calls.
- **irqsoff**: Traces the areas that disable interrupts and saves the trace with the longest max latency. When a new max is recorded, it replaces the old trace. It is best to view this trace with the latency-format option enabled, which happens automatically when the tracer is selected.
- **wakeup**: Traces and records the max latency that it takes for the highest priority task to get scheduled after it has been woken up. Traces all tasks as an average developer would expect.

**trace** output format:

Different tracers might have different formats.

```bash
cd /sys/kernel/tracing
echo 1 > tracing_on
echo function > current_tracer
cat trace

# tracer: function
#
# entries-in-buffer/entries-written: 140080/250280   #P:4
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
            bash-1977  [000] .... 17284.993652: sys_close <-system_call_fastpath
            bash-1977  [000] .... 17284.993653: __close_fd <-sys_close
            bash-1977  [000] .... 17284.993653: _raw_spin_lock <-__close_fd
            sshd-1974  [003] .... 17284.993653: __srcu_read_unlock <-fsnotify
            bash-1977  [000] .... 17284.993654: add_preempt_count <-_raw_spin_lock
            bash-1977  [000] ...1 17284.993655: _raw_spin_unlock <-__close_fd
            bash-1977  [000] ...1 17284.993656: sub_preempt_count <-_raw_spin_unlock
            bash-1977  [000] .... 17284.993657: filp_close <-__close_fd
            bash-1977  [000] .... 17284.993657: dnotify_flush <-filp_close
            sshd-1974  [003] .... 17284.993658: sys_select <-system_call_fastpath
```

A header is printed with the tracer name that is represented by the trace. In this case the tracer is **function**. Then it shows the number of events (entries) in the buffer as well as the total number of events that were written. The difference is the number of events that were lost due to the buffer filling up (`250280` - `140080` = `110200` events lost). This trace was taken on a system with 4 processors (`#P:4`).

The header explains the content of the events. Take the first line as an example:

- task name `bash`,
- the task PID `1977`,
- the CPU that it was running on `000`,
- the status, for example, `irqs-off` is `d` if interrupts are disabled; `.` otherwise
- the timestamp in `<seconds>.<microseconds>` format (the time at which the function was entered),
- the function name that was traced `sys_close` and the parent function that called this function `system_call_fastpath`.

```bash
cd /sys/kernel/tracing
echo 1 > tracing_on
echo function_graph > current_tracer
cat trace

# tracer: function_graph
#
# CPU  DURATION                  FUNCTION CALLS
# |     |   |                     |   |   |   |
 6)               |              n_tty_write() {
 6)               |                down_read() {
 6)               |                  __cond_resched() {
 6)   0.341 us    |                    rcu_all_qs();
 6)   1.057 us    |                  }
 6)   1.807 us    |                }
 6)   0.402 us    |                process_echoes();
 6)               |                add_wait_queue() {
 6)   0.391 us    |                  _raw_spin_lock_irqsave();
 6)   0.359 us    |                  _raw_spin_unlock_irqrestore();
 6)   1.757 us    |                }
 6)   0.350 us    |                tty_hung_up_p();
 6)               |                mutex_lock() {
 6)               |                  __cond_resched() {
 6)   0.404 us    |                    rcu_all_qs();
 6)   1.067 us    |                  }
 ```

With **function_graph** tracer, you can see the `CPU ID` and the `DURATION` of the kernel function execution. Next, you see curly braces indicating the beginning of a function and what other functions were called from inside it.

The **function_graph** tracer records the time the function was entered and exited and reports the difference as the duration. These numbers only appear with the leaf functions and the `}` symbol. Note that this time also includes the overhead of all functions within a nested function as well as the overhead of the **function_graph** tracer itself. The **function_graph** tracer hijacks the return address of the function in order to insert a trace callback for the function exit. This breaks the CPU's branch prediction and causes a bit more overhead than the **function** tracer. Sometimes, the duration time is prefixed with a `+` or `!` sign. When the duration is greater than 10 microseconds, a `+` is shown. If the duration is greater than 100 microseconds an `!` will be displayed.

You can always tweak the tracer slightly to see more/less depth of the function calls using the steps below. After which, you can view the contents of the trace file and see that the output is slightly more/less detailed.

```bash
cat max_graph_depth
# 1

echo 3 > max_graph_depth
```

## Trace Filter

To enable tracing of specific functions or patterns, you can make use of the **set_ftrace_filter** file to specify which functions you want to trace. This file accepts the `*` pattern, which expands to include additional functions with the given pattern.

```bash
cat set_ftrace_filter
# #### all functions enabled ####

echo ext4_get* > set_ftrace_filter

cat set_ftrace_filter
# ext4_get_group_number
# ext4_get_group_no_and_offset
# ext4_get_group_desc
# ext4_get_group_info
# ext4_get_es_cache
# ext4_getfsmap_dev_compare
# ext4_getfsmap_compare
# ...
```

Now, when you see the tracing output, you can only see kernel functions related to `ext4_get` for which you had set a filter earlier.

You don't always know what you want to trace but, you surely know what you **don't want** to trace. For that, there is this file named **set_ftrace_notrace**. You can write your desired pattern in this file and enable tracing, upon which everything except the mentioned pattern gets traced.

```bash
cat set_ftrace_notrace
# #### no functions disabled ####
```

A special note for **function_graph** tracer. If you want to trace a function and all of its children, you just have to `echo` its name into **set_graph_function**:

```bash
echo __do_fault > set_graph_function

echo sys_close >> set_graph_function
```

Now if you want to go back to trace all functions you can clear this special filter via:

```bash
echo > set_graph_function
```

## Tracing Specific PID

If you want to trace activity related to a specific process that is already running, you can write that `PID` to a file named **set_ftrace_pid** and then enable tracing. That way, tracing is limited to this `PID` only, which is very helpful in some instances.

```bash
echo $PID > set_ftrace_pid
```

## `trace-cmd`

The above process is kind of annoying. Luckily, we have an easier-to-use interface called `trace-cmd`!  
First, you need to install `trace-cmd`.

```bash
sudo apt install trace-cmd
```

When using **ftrace**, you must view a file's contents to see what tracers are available. But with `trace-cmd`, you can get this information with:

```bash
trace-cmd list -t
```

`-t` is for listing available tracers.

If you want to trace only certain functions and ignore the rest, you need to know the exact function names. You can get them with:

```bash
trace-cmd list -f | grep $WHAT_YOU_WANT_TO_TRACE
```

`-f` is for listing available functions to filter on.

To record a trace, use `trace-cmd record`, which will by default write the trace to a **trace.dat** file (use `-p` to specify a tracer, in this case, the **function** tracer):

```bash
trace-cmd record -p function
# plugin 'function'
# Hit Ctrl^C to stop recording
```

Running this for some time then hit `Ctrl+C`. Awesome! It created a file called **trace.dat**. Then use `trace-cmd report` to view the trace:

```bash
trace-cmd report
```

The `trace-cmd record [options] [command]` command will set up the **ftrace** to record the specified plugins or events that happen while the command executes. If no command is given, then it will record until the user hits `Ctrl+C`.

To record a trace of some specific functions, use `-l` option (more than one `-l` may be specified to trace more than one pattern):

```bash
trace-cmd record -p function -l ext4_*
```

Similarly, use `-n` option to exclude some functions:

```bash
trace-cmd record -p function -n ext4_*
```

For **function_graph** tracer, you can use `-g` option to trace only the function and all functions that it calls:

```bash
trace-cmd record -p function_graph -g ext4_*
```

To record a trace of a specific process, use `-P` option:

```bash
trace-cmd record -p function -P 25314  # record for PID 25314
```

### `profile`

You can add a `--profile` option to `trace-cmd record/report` to report more statistics or you could also use `trace-cmd profile` command.

`trace-cmd record --profile` will enable tracing that can be used with `trace-cmd report --profile`.
This will process all the events first, and then output a format showing where events occur and their frequency and timing statistics (e.g., function running time).

`trace-cmd profile` will start tracing just like `trace-cmd record --profile`, except that it does not write to a file, but instead, it will read the events as they happen and will update the accounting of the events. When the trace is finished, it will report the results. The advantage of using the `profile` command is that the profiling can be done over a long period of time where recording all events would take up too much storage space. By default, `trace-cmd profile` will enable several events (e.g., scheduling events, interrupt events) as well as the **function_graph** tracer with a depth of one (if the kernel supports it). This is to show where tasks enter and exit the kernel and how long they were in the kernel. You can filter the events and choose another tracer by specifying the options.
