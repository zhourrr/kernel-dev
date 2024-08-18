# --cdrom specifies the path to the ISO file.

# Remember to replace the option values with the actual values.
virt-install \
--name demo-z \
--memory 2048 \
--vcpus 2 \
--disk size=8 \
--cdrom /path/to/install.iso \
--os-variant your_os