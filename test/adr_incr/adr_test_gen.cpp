#include <cstring>
#include <cstdio>
#include <stdint.h>
#include "matrix_primitives.hpp"

#define MAX_MTRX_SIZE   8

/**
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 */
void matrix_iterate(uint32_t m, uint32_t p, uint32_t n, 
                    uint32_t *a_adr, uint32_t *b_adr) {
  uint32_t i, j, k;

  for(i=0; i<m; i++) {     //each row in A
    for(j=0; j<n; j++) {   //each column in B
      for(k=0; k<p; k++) { //each element in row A & column B
        *a_adr++ = i*p + k;
        *b_adr++ = k*n + j;
      }
    }
  }
}

/**
 *
 */
static void generate(uint32_t m, uint32_t p, uint32_t n) {
  FILE *a_fp;
  FILE *b_fp;
  const size_t N = 64;
  char a_str[N];
  char b_str[N];
  uint32_t a_adr[m*p*n];
  uint32_t b_adr[m*p*n];

  memset(a_adr, 0x55, sizeof(a_adr));
  memset(b_adr, 0xAA, sizeof(b_adr));

  matrix_iterate(m, p, n, a_adr, b_adr);

  memset(a_str, 0x00, N);
  memset(b_str, 0x00, N);
  sprintf(a_str, "test_vectors/%d_%d_%d_a.%s", m, p, n, "u32");
  sprintf(b_str, "test_vectors/%d_%d_%d_b.%s", m, p, n, "u32");

  a_fp = fopen(a_str, "wb");
  b_fp = fopen(b_str, "wb");

  fwrite(a_adr, sizeof(a_adr), 1, a_fp);
  fwrite(b_adr, sizeof(b_adr), 1, b_fp);

  fclose(a_fp);
  fclose(b_fp);
}

/**
 *
 */ 
int main(void) {
  size_t m, p, n;
  m = p = n = MAX_MTRX_SIZE;

  while(m--) {
    while(p--) {
      while(n--) {
        generate(m+1, p+1, n+1);
      }
      n = MAX_MTRX_SIZE;
    }
    p = MAX_MTRX_SIZE;
  }
}














