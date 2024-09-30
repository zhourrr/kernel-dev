# Namespace and Isolation

A Linux **namespace** is a feature that Linux kernel provides to allow user to isolate resources for a set of processes.

## Main Advantages

- **Isolation of Resources**  
    One troublesome process won’t be taking down the whole host, it’ll only affect those processes belonging to a particular namespace.
- **Security**  
    The other advantage is that a security flaw in the process or processes running under a given namespace, won’t give access to the attacker to the whole system. Whatever they could do, will always be contained within the boundaries of that namespace! This is why it’s also very important to avoid running our processes using privileged users whenever possible.

## Common Namespaces

- **Session Isolation**  
    When a user logs out of a system, the kernel needs to terminate all the processes the user had running (otherwise, users would leave a bunch of old processes sitting around waiting for input that can never arrive). To simplify this task, processes are organized into sets of sessions. The session's ID is usually the same as the pid of the process that created the session. That process is known as the session leader for that session group. All of that process's descendants are then members of that session unless they specifically remove themselves from it.

    Every session is tied to a terminal from which processes in the session get their input and to which they send their output. That terminal may be the machine's local console, a terminal connected over a serial line, or a pseudo terminal that maps across a network. The terminal to which a session is related is called the controlling terminal of the session. A terminal can be the controlling terminal for only one session at a time. At most one process group in a session can be a foreground process group. An interrupt character typed on a terminal causes a signal to be sent to all members of the foreground process group in the session (if any).

    When a terminal exits, it kills all process groups in the session, including foreground and background processes. If a process wants to continue as a daemon, it must detach itself from its controlling terminal (session). If you launch a daemon process via an init system, then you might not need to detach it yourself. The init system usually invoke daemons without a controlling terminal, but as session leaders in their own sessions. Most daemon processes are parented to **init/PID 1**.
- **Process Isolation** (`pid`)  
    A PID, or process ID helps a system track a specific task on a computer. Every process is a member of a unique process group, identified by its process group ID (when the process is created, it becomes a member of the process group of its parent). By convention, the process group ID (`pgid`) of a process group equals the process ID of the first member of the process group, called the process group leader. Leaders may terminate before the others, and then the process group is without leader (orphaned). A process group is called orphaned when the parent of every member is either in the process group or outside the session. In particular, the process group of the session leader is always orphaned. When a parent process terminates, its children do not automatically get killed (unless the parent takes care of the termination of its children). Instead, the children processes become orphaned and are adopted by **init/PID 1**, which means they will continue to run unless explicitly terminated. To forcefully kill a process group, use `kill -9 -- -$PGID` (the negation of the group number) to kill all processes in that group.

    PID namespaces are hierarchical; once a new PID namespace is created, all the tasks in the current PID namespace will see the tasks (i.e. will be able to address them with their PIDs) in this new namespace. However, tasks from the new namespace will not see the ones from the current. The process namespace cuts off a branch of the PID tree, and doesn’t allow access further up the branch. Processes in child namespaces will actually have multiple PIDs—the first one representing the global PID used by the main system, and the second PID representing the PID within the child process tree, which will restart from 1. Every time we create a new namespace, the process will get assigned PID 1 (within the child process tree). Every child process created in the new namespace will be assigned subsequent IDs. For example, Docker creates a new PID namespace for the container, ensuring that the processes inside the container have their own unique process IDs, starting from 1.
- **Mount Isolation** (mnt)  
    The mount namespace virtually partitions the file system. Processes running in separate mount namespaces cannot access files outside of their mount point. As far as the namespace is concerned, it is at the root of the file system, and nothing else exists. However, you can mount portions of an underlying file system into the mount namespace, thereby allowing it to see additional information.
- **Network Isolation** (net)  
    This namespace manages which network devices a process can see. However, this doesn’t automatically set up anything for you—you’ll still need to create virtual network devices, and manage the connection between global network interfaces and child network interfaces. Containerization software like **Docker** already has this figured out, and can manage networking for you.

    When software such as an email server is receiving a connection, it expects to be on a specific port. So even if you isolated the PID, the email server would only have a single instance running because `port 25` (specifically designated for emails) is already in use. Network namespaces allow processes inside each namespace instance to have access to a new IP address along with the full range of ports. Thus, you could run multiple versions of an email server listening on `port 25` without any software conflicts.
- **CGroups** (control group)  
    cgroups are a mechanism for controlling and prioritizing system resources. It is based on a hierarchical organized file-system **cgroupfs** (usually mounted at **/sys/fs/cgroup/**), where each directory represents a bounded cgroup.
     A bounded cgroup is a collection of processes that are bound to a set of limits or parameters. When a cgroup is active, it can control the amount of CPU, RAM, block I/O, and some other resources which the group may consume. Initially, only the root cgroup exists to which all processes belong. A child cgroup can be created by creating a sub-directory:

    ```bash
    mkdir /sys/fs/cgroup/$MY_CGROUP_NAME
    ```

    The folder gets automatically populated with a set of files that can be used to configure the new cgroup, such as cpu limit and memory limit. It also contains statistic files. A given cgroup may have multiple child cgroups forming a tree structure. When a process forks a child process, the new process is born into the cgroup that the forking process belongs to at the time of the operation. A process can be migrated into another cgroup by writing its PID to the target cgroup’s **cgroup.procs** file.

    Note that Docker uses cgroups to set resource limits and priorities for the container. When you're inside a container, you typically see a single root cgroup which contains all the processes running within the container. This is because the container is running within its own PID namespace. On the host system, you can see the full cgroup hierarchy, which includes the cgroups for the container and potentially many other cgroups for other containers and processes.
