#include <stdint.h>

int main()
{
  int64_t x = 0, y = 1;
  y = __sync_val_compare_and_swap(&x, x, y);
  return 0;
}
