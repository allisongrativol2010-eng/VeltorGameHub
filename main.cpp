#include <orbis/libkernel.h>
#include <stdio.h>

int main(void)
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    printf("Veltor GameHub\n");
    printf("Initial homebrew build is running.\n");

    // Keep the process alive for initial runtime verification.
    for (;;) {
        sceKernelUsleep(1000000);
    }

    return 0;
}
