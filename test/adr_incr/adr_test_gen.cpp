#include <cstring>
#include <cstdio>
#include <stdint.h>
#include <iostream>
#include <fstream>
#include "matrix_primitives.hpp"

#define MAX_MTRX_SIZE   3

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
  sprintf(a_str, "test_vectors/%d_%d_%d_a.%s", m, p, n, "txt");
  sprintf(b_str, "test_vectors/%d_%d_%d_b.%s", m, p, n, "txt");

  std::ofstream a_file, b_file;
  a_file.open(a_str);
  b_file.open(b_str);
  for (size_t i=0; i<m*p*n; i++) {
    a_file << a_adr[i] << "\n";
    b_file << b_adr[i] << "\n";
  }
  a_file.close();
  b_file.close();
}

/**
 *
 */ 
int main(void) {
  std::ofstream map_file;
  map_file.open("test_vectors/map.txt");

  size_t m, p, n;
  m = p = n = MAX_MTRX_SIZE;

  while(m--) {
    while(p--) {
      while(n--) {
        generate(m+1, p+1, n+1);
        map_file << m << "\n" << p << "\n" << n << "\n";
      }
      n = MAX_MTRX_SIZE;
    }
    p = MAX_MTRX_SIZE;
  }

  map_file.close();
}













