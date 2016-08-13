#include <miksys.h>

unsigned primes[640];
int primes_count = 0;

int is_prime(unsigned x) {
    unsigned *p = primes;
    int i;
    for (i = primes_count; i > 0; i--) {
        if (x % *p == 0) return 0;
        p++;
    }
    return 1;
}

char buf[128];

void main() {
    unsigned i = 1;
    unsigned mem_addr = 0;
    char* str = buf;
    register unsigned *p = primes;
    unsigned count = 0;
    while (count < 640) {
        if (is_prime(++i)) {
            *p = i;
            p++;
            primes_count = ++count;
            str = print(str, "    %U ", TEXT_GREEN, i);
            if ((count&15) == 0) {
                sdram(SDRAM_WRITE, buf, str-buf, mem_addr, 0);
                str = buf;
                mem_addr += 128;
            }
        }
        
    }
}

