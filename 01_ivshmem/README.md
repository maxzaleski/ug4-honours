# Shared Memory Between Two x86_64 Guest VMs

September 27, 2024

## Abstract

Multiple x86_64 guest systems are created then virtualised using QEMU. A shared memory 
region is established between the VMs through QEMU's `ivshmem` device, enabling inter-VM 
communication.

## Background

PCI (Peripheral Component Interconnect) is a widely used bus standard for connecting devices to 
a computer's processor. Each PCI device communicates with the wider system via memory-mapped I/O 
(MMIO) or port I/O using memory regions that are defined by BARs (Base Address Registers).

QEMU's [[1]](https://www.qemu.org/) `ivshmem` (Inter-VM Shared Memory) 
[[2]](https://www.qemu.org/docs/master/system/devices/ivshmem.html) is a virtual PCI device that 
allows for the mapping of a shared memory region between a backend (host or otherwise) and one 
or more guest VMs. Broadly, the guest OS recognises the `ivshmem` device and maps its BAR into its own address space, 
enabling inter-VM communication.

## Implementation

### Configuration

The bash scripts mentioned in coming sections commonly draw from a set of variables defined in 
`config.sh`.

### Setup

Assumes a clean Debian installation as host OS.

A setup script is provided (`setup.sh`) to install necessary dependencies and build the 
QEMU images.

```bash
chmod +x setup.sh
./setup.sh 
```

In order, the script will:

1. Install host dependencies (`gcc` `make` `vim` `screen` `qemu-system` `qemu-utils`).
2. Download and compile a Linux kernel (default – 6.10.11).
3. Boostrap a Debian Buster root filesystem for each VM (default – 2, under `/home/vms-x86_64`)
   and configure it.
4. Create a QEMU image for each filesystem.
5. (Give execute permissions to the start and stop scripts)

Some of these steps may take a while to complete.

### Starting the VMs

Use the `start.sh` script to start the VMs, where for each, a `qemu-system-x86_64` command is 
executed as a background process (`GNU screen` [[3]](https://www.gnu.org/software/screen/)).

```bash
./start.sh
```

> The `qemu-system-x86_64` command omits the `-enable-kvm` flag, as my host machine is 
> also a managed VM and does not support nested virtualisation.
> It is generally recommended to include this flag for better performance.
 
### Stopping the VMs

Use the `stop.sh` script to stop the VMs.

```bash
./stop.sh 
```

## Experimentation

> To reiterate, the setup script will build and place these binaries under the guest filesystems.
> As one might want to modify certain portions of said programs, the source files are also
> copied (default – `/root/prog`).

C programs (`/prog`) are provided to test the shared memory region between the VMs. 

The header file `prog.h` defines the region's size and BAR address – `lspci` 
[[4]](https://man7.org/linux/man-pages/man8/lspci.8.html) instructions are provided to amend the 
address definition.

Each program executes the `mmap` syscall [[5]](https://www.man7.org/linux/man-pages/man2/mmap.2.html)
to map the shared memory region into their respective virtual address space.

<details open>
   <summary><b>Memory Copy Bandwidth</b></summary>

   `/usr/local/bin/__bandwidth`

   Measures the bandwidth of copying 64MB of data to the shared memory region.

   ```
   # expected output
   
   root@vm1:~# __bandwidth
   --- mmap successful
   memcpy bandwidth: xxxx.xx MB/s
   ```
</details>

<details open>
   <summary><b>Memory Read / Write</b></summary>

   `/usr/local/bin/__read_write`

   Attempts to read the contents of the shared memory region; otherwise, writes to it.

   ```
   # expected output
   
   root@vm1:~# __read_write
   --- mmap successful
   Written to shmem: 'Other VM says hello world!'; run this program again on another VM
   
   root@vm2:~# __read_write
   --- mmap successful
   Read from shmem: 'Other VM says hello world!'
   ```
</details>