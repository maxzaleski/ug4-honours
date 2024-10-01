#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include "prog.h"

int main()
{
    int fd;
    void *shm;
    char *error, *buffer;
    clock_t start;
    double memcpy_dur;

    /* Open memory device */
    fd = open("/dev/mem", O_RDWR);
    if (fd < 0)
    {
        error = "unable to open /dev/mem";
        goto exit;
    }

    /* Create a new mapping in the process' virtual address space */
    shm = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, SHM_BAR);
    if (shm == MAP_FAILED)
    {
        close(fd);
        error = "unable to mmap shared memory";
        goto exit;
    }
    printf("--- mmap successful\n");

    buffer = malloc(SHM_SIZE);
    memset(buffer, 0, SHM_SIZE);

    start = clock();
    memcpy(shm, buffer, SHM_SIZE);
    memcpy_dur = (double)(clock() - start) / CLOCKS_PER_SEC;

    printf("memcpy bandwidth: %.2f MB/s\n", SHM_SIZE / (1024 * 1024 * memcpy_dur));

    free(buffer);
    munmap(shm, SHM_SIZE);
    close(fd);

    return 0;

exit:
    perror(error);
    return 1;
}