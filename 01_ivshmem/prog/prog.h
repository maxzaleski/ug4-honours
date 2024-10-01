#define SHM_SIZE 64*1024*1024 // 64MB

/*
 * ivshmem device BAR (Base Address Register)
 *
 * Run `lspci` on guest VM (output may be different):
 * | .
 * | 00:04.0 RAM memory: Red Hat, Inc Inter-VM shared memory (rev 01)
 *   -------
 *
 * Run `lspci -vv -s 00:04.0` on guest VM (output may be different):
 * | .
 * | Region 2: Memory at 0xf8000000 (64-bit, prefetchable) [size=64M]
 *                       ----------                         --------
 */
#define SHM_BAR 0xf8000000