# Capabilities

Traditionally, Linux implementation distinguishes two categories of processes:

1. **privileged processes** (referred to as superuser or root), which bypass all kernel permission checks
2. **unprivileged processes**, which are subject to full permission checking based on the process's credentials (usually: effective UID, effective GID, and supplementary group list)

Capabilities are a way to assign specific privileges to a running process. They **divide root privileges into smaller, distinct units, allowing processes to have a subset of privileges**. Capabilities are a per-thread attribute. They can also be assigned to executable files, permitting specific privileges to be used by those files even if run by a non-root user.

For example, `CAP_SYS_PTRACE` is a capability that grants a process significant debugging and monitoring powers using **ptrace** (process trace). Due to the extensive access `CAP_SYS_PTRACE` provides, it is considered a highly sensitive capability and should be granted with caution.

## Inspecting and Setting Capabilities

We can check the **/proc/{PID}/status** for capability information, e.g., `grep Cap /proc/{PID}/status`. There are different types of process capabilities set:

- `CapEff` (Effective Capability Set) contains all the capabilities the process has at a specific moment. When a process attempts a privileged operation, the kernel verifies that the relevant bit in the effective set is set.

- `CapPrm` (Permitted Capability Set) indicates what capabilities a process can use and limits what can be in effective set. A process can have capabilities that are set in `CapPrm` but not in `CapEff`. This indicates that the process has temporarily disabled those capabilities. A process can only set its effective set bit if it is included in the permitted set.

- `CapInh` (Inheritable Capability Set) contains the capabilities of the current process that can be inherited by a child process. The permitted set of a new process is masked against the inheritable set of the parent process. Note that **inheriting a capability does not necessarily automatically give any thread the effective capability**. The inherited capabilities become part of the new process's permitted set.

- `CapBnd` (Bounding Capability Set) is the maximum set of capabilities that a process is ever allowed to have (a limiting superset). Only capabilities found in the bounding set will be permitted in the inheritable and permitted sets. Processes might acquire additional capabilities through dynamic means (such as adjustments to its permitted set by another privileged process). Capabilities not included in the bounding set are not allowed to be active or passed on to child processes.

Alternatively, you can use `getpcaps` to display capabilities in a more human-readable way.

You can also use `setcap` to set capabilities.
