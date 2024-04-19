# --import option specifies that the VM will be imported from the virtual disk
# image specified by the --disk /path/to/imported/disk.qcow option.

# Remember to replace the option values with the actual values.
virt-install \
--name demo-z \
--memory 2048 \
--vcpus 2 \
--disk /path/to/imported/disk.qcow \
--import \
--os-variant your_os