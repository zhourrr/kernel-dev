# Namespace

A Linux **namespace** is a feature that Linux kernel provides to allow user to isolate resources for a set of processes.

## Main Advantages

- **Isolation of Resources**  
    One troublesome process won’t be taking down the whole host, it’ll only affect those processes belonging to a particular namespace.
- **Security**  
    The other advantage is that a security flaw in the process or processes running under a given namespace, won’t give access to the attacker to the whole system. Whatever they could do, will always be contained within the boundaries of that namespace! This is why it’s also very important to avoid running our processes using privileged users whenever possible.

## Common Namespaces

- **Process Isolation** (pid)  
    A PID, or process ID helps a system track a specific task on a computer. The process namespace cuts off a branch of the PID tree, and doesn’t allow access further up the branch. Processes in child namespaces will actually have multiple PIDs—the first one representing the global PID used by the main system, and the second PID representing the PID within the child process tree, which will restart from 1. Every time we create a new namespace, the process will get assigned PID 1 (within the child process tree). Every child process created in the new namespace will be assigned subsequent IDs.
- **Mount Isolation** (mnt)  
    The mount namespace virtually partitions the file system. Processes running in separate mount namespaces cannot access files outside of their mount point. As far as the namespace is concerned, it is at the root of the file system, and nothing else exists. However, you can mount portions of an underlying file system into the mount namespace, thereby allowing it to see additional information.
- **Network Isolation** (net)  
    This namespace manages which network devices a process can see. However, this doesn’t automatically set up anything for you—you’ll still need to create virtual network devices, and manage the connection between global network interfaces and child network interfaces. Containerization software like **Docker** already has this figured out, and can manage networking for you.  
    When software such as an email server is receiving a connection, it expects to be on a specific port. So even if you isolated the PID, the email server would only have a single instance running because `port 25` (specifically designated for emails) is already in use. Network namespaces allow processes inside each namespace instance to have access to a new IP address along with the full range of ports. Thus, you could run multiple versions of an email server listening on `port 25` without any software conflicts.
- **CGroups** (control group)  
    cgroups are a mechanism for controlling system resources. When a cgroup is active, it can control the amount of CPU, RAM, block I/O, and some other resources which a group of processes may consume.
