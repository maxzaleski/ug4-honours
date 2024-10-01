#!/usr/bin/env bash

source config.sh

for i in $(seq 1 $GUEST_COUNT); do
  screen -dmS $SCREEN_SESSION_ID$i \
    qemu-system-x86_64 -nographic \
      -m 2G -smp 2 \
      -drive file=$HOST_DIR/vm$i.qcow2 \
      -kernel $HOST_DIR/vm$i-rootfs/boot/vmlinuz-$KERNEL_VERSION \
      -append "root=/dev/sda rw console=ttyS0 noapic" \
      -device ivshmem-plain,memdev=ivshmem \
      -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/ivshmem,id=ivshmem,size=64M

done

screen -ls

printf "\n--- programs available under /usr/local/bin:\n"
for file in $(ls prog); do
  if [[ $file == *.c ]]; then
    echo " | __${file%.*}"
  fi
done

printf "\n--- to stop, run './stop.sh' ---\n"

