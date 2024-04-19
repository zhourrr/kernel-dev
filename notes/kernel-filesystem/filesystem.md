# Filesystem

All filesystems need to provide a namespace — that is, a naming and organizational methodology. This defines how a file can be named, specifically the length of a file name and the subset of characters that can be used for file names out of the total set of characters available. It also defines the logical structure of the data on a storage device, such as the use of directories for organizing files instead of just lumping them all together in a single, huge bucket of files.

Once the namespace has been defined, a metadata structure is necessary to provide the logical foundation for that namespace. This usually includes

- data structures required to support a hierarchical directory structure
- data structures to determine which space on the storage device are used and which are available
- information about the files such as their sizes and timestamps at which they were created, modified or last accessed
- locations of the data belonging to the files on the storage device
- access rights to files and directories

Filesystems also provide an Application Programming Interface (API) that allows manipulation of filesystem objects like files and directories. This API enables operations such as creation, relocation, and deletion of files. Additionally, they usually include algorithms that decide where a file should be placed within a filesystem. These algorithms are designed to improve filesystem performance.

## Linux Unified Directory Structure

In some operating systems, if there are multiple physical storage devices, each device is assigned a drive letter. It is necessary to know on which storage device a file or program is located, such as `C:` or `D:` on Windows system. Each storage device has its own separate and complete directory tree.

The Linux filesystem unifies all physical storage devices into a single directory structure. It all starts at the top – the `root` (`/`) directory. All other directories and their subdirectories are located under the `root` directory. This means that there is only one single directory tree in which to search for files and programs.

This can work only because a filesystem, such as `/home` or `/tmp` can be created on separate physical storage devices and then be mounted on a mount point (directory) as part of the `root` filesystem tree. Even removable drives such as a USB drive will be mounted onto the `root` filesystem and become an integral part of that directory tree.

### Mounting

A mount point is simply a directory, like any other, that is created as part of the `root` filesystem. So, for example, the `home` filesystem is mounted on the directory `/home`. Filesystems can be mounted at mount points on other non-root filesystems but this is less common.

Filesystems are mounted on an existing directory/mount point using the `mount` command. In general, any directory that is used as a mount point should be empty and not have any other files contained in it. Linux will not prevent users from mounting one filesystem over one that is already there or on a directory that contains files. If you mount a filesystem on an existing directory or filesystem, the original contents will be hidden and only the content of the newly mounted filesystem will be visible.

## Write Atomicity

A write operation is treated as a single, indivisible action. This means that the write operation either completely succeeds or fails entirely, without leaving the system in an intermediate or inconsistent state. This concept is crucial for maintaining data integrity, especially in scenarios involving concurrent access or system failures.

1. All-or-Nothing Commitment: The file system ensures that a write operation is fully committed to the storage media. If a failure occurs during the write process (such as a power outage or system crash), the file system can either revert to the previous consistent state or complete the pending write upon recovery. This is often managed through mechanisms like journaling or write-ahead logging.

1. Journaling File Systems: Many file systems use a journaling approach. In this method, write operations are first logged to a dedicated area (journal) before they are actually written to the main file system. If a system failure occurs, the file system can check the journal to determine which operations were in progress and complete them or roll them back as necessary.

1. Copy-on-Write (COW) Techniques: Many file systems use Copy-on-Write mechanisms. When data is modified, these file systems write the new data to a different location on the disk. Only after the write is successfully completed, the file system updates the pointers to the data. This approach ensures that the original data is not corrupted if the write operation fails.
