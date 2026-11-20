parted /dev/nvme0n2 --script mklabel gpt mkpart xfspart xfs 0% 100%
partprobe /dev/nvme0n2