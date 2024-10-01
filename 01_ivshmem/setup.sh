#!/usr/bin/env bash

source config.sh

if [ ! -d "$HOST_DIR" ]; then
  mkdir $HOST_DIR
fi

printf "\n--- [1/3] Installing host dependencies, this may take a while...\n"
sudo apt-get update
sudo apt-get install -y debootstrap qemu-utils qemu-system \
  screen gcc make flex bison libssl-dev bc libelf-dev libncurses-dev

printf "\n--- [2/3] Downloading and compiling Linux kernel $KERNEL_VERSION, this may take a while...\n"
if [ ! -d "$HOST_DIR/linux-$KERNEL_VERSION" ]; then
  wget https://cdn.kernel.org/pub/linux/kernel/v$(echo $KERNEL_VERSION | cut -d. -f1).x/linux-$KERNEL_VERSION.tar.xz \
    -P $HOST_DIR/
  tar -xvf $HOST_DIR/linux-$KERNEL_VERSION.tar.xz -C $HOST_DIR
  else echo " |--- linux kernel $KERNEL_VERSION already downloaded; skipping"
fi
if [ ! -f "$HOST_DIR/linux-$KERNEL_VERSION/arch/x86/boot/bzImage" ]; then
  cd $HOST_DIR/linux-$KERNEL_VERSION
  make x86_64_defconfig
  make kvm_guest.config
  make -j$(nproc)
  cd $REALPATH
  else echo " |--- linux kernel $KERNEL_VERSION already compiled; skipping"
fi

printf "\n--- [3/3] Creating qcow2 images under $HOST_DIR, this may take a while...\n"
for i in $(seq 1 $GUEST_COUNT); do
  rootfs=$HOST_DIR/vm$i-rootfs

  # Init rootfs (Debian Buster):
  if [ ! -d $rootfs ]; then
    sudo debootstrap --arch=amd64 buster $rootfs
    else printf " |--- rootfs $rootfs already exists; applying configuration only\n"
  fi

  cp /etc/resolv.conf $rootfs/etc/resolv.conf
  cp $HOST_DIR/linux-$KERNEL_VERSION/arch/x86/boot/bzImage $rootfs/boot/vmlinuz-$KERNEL_VERSION
  cp -rf $REALPATH/prog $rootfs/$GUEST_PROG_DIR/

  # Configure rootfs:
  chroot $rootfs /bin/bash -c "
    export LANG=C
    echo 'vm$i' > /etc/hostname
    echo -e '$GUEST_PW\n$GUEST_PW' | passwd

    apt-get update
    apt-get install -y gcc qemu-guest-agent pciutils

    cd /root/prog
    chmod +x build.sh
    ./build.sh
  "

  # Create disk image:
  dd if=/dev/zero of=$HOST_DIR/vm$i.raw bs=1M count=10240
  mkfs.ext4 $HOST_DIR/vm$i.raw

  mkdir -p $HOST_DIR/mnt/vm$i
  sudo mount -o loop $HOST_DIR/vm$i.raw $HOST_DIR/mnt/vm$i
  sudo cp -r $rootfs/* $HOST_DIR/mnt/vm$i
  sudo umount $HOST_DIR/mnt/vm$i
  rm -rf $HOST_DIR/mnt

  qemu-img convert -f raw -O qcow2 $HOST_DIR/vm$i.raw $HOST_DIR/vm$i.qcow2
  rm $HOST_DIR/vm$i.raw

  printf " |--- finished building $HOST_DIR/vm$i.qcow2\n"
done

chmod +x start.sh stop.sh

printf "\n--- setup complete | run './start.sh' to start VMs ---\n\n"
