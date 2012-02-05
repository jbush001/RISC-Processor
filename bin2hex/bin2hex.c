#include <stdio.h>


int main(int argc, const char *argv[])
{
	FILE *f;
	unsigned char c;

	f = fopen(argv[1], "r");
	if (f == NULL)
	{
		perror("fopen");
		return 1;
	}

	while (fread(&c, 1, 1, f))
		printf("%02x\n", c);

	return 0;
}

