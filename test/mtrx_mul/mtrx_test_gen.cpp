#include <cmath>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <cstdio>
#include <stdint.h>
#include <iostream>
#include <fstream>

#define MAX_MTRX   32

/**
 *
 */
static double pyramid_accumulate(const double *d, size_t len) {
  size_t N;

  if (len % 2 == 1) {
    N = (len + 1) / 2;
  }
  else {
    N = len / 2;
  }

  //std::cout << len << " -> " << N << "\n";

  double buf[N];
  size_t i = 0, j = 0;
  while (len > 1) {
    buf[i] = d[j] + d[j+1];
    i++;
    j += 2;
    len -= 2;
  }

  // copy last element as is when len is odd
  if (len == 1) {
    buf[i] = d[j];
    //std::cout << "odd case \n";
  }

  if (1 == N)
    return buf[0];
  else
    return(pyramid_accumulate(buf, N)); // recursive call
}

/**
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 */
void matrix_multiply_fpga(size_t m, size_t p, size_t n,
                          const double *A, const double *B, double *C) {
  size_t i, j, k;
  double tmp[p];

  for(i=0; i<m; i++) {      //each row in A
    for(j=0; j<n; j++) {    //each column in B
      for(k=0; k<p; k++) {  //each element in row A & column B
        tmp[k] = A[i*p + k] * B[k*n + j];
      }
      *C++ = pyramid_accumulate(tmp, p);
    }
  }
}

/**
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 */
template <typename T>
void matrix_multiply(size_t m, size_t p, size_t n,
                     const T *A, const T *B, T *C) {
  size_t i, j, k;
  T tmp;

  for(i=0; i<m; i++) {     //each row in A
    for(j=0; j<n; j++) {   //each column in B
      tmp = 0;
      for(k=0; k<p; k++)  //each element in row A & column B
        tmp += A[i*p + k] * B[k*n + j];
      *C++ = tmp;
    }
  }
}

/**
 *
 */
static double rand_double(void) {
  const double MAX_MTRX_NUM = 10000;
  const double MIN_MTRX_NUM = .0001;
  double r = MAX_MTRX_NUM + 1;
  double a, b;

  while ((r > MAX_MTRX_NUM) or (r < MIN_MTRX_NUM)) {
    a = rand();
    b = rand();
    r = a / b;
  }

  if ((rand() & 1) == 1)
    return -r;
  else
    return r;
}

/**
 *
 */
static void len2file(FILE *f, const uint32_t dat) {

  //printf("%d\n", dat); // debug print
  fprintf(f, "%d\n", dat);
}

/**
 *
 */
static void dbl2file(FILE *f, const double val_dbl) {
  uint64_t val_u64;
  const char fmt[] = "%016lX --   %f\n";

  memcpy(&val_u64, &val_dbl, 8); // dirty hack to convert double to bit vector
  
  // printf(fmt, val_u64, val_dbl); // debug print
  fprintf(f, fmt, val_u64, val_dbl);
}

/**
 *
 */
static void buf2file(double *buf, size_t len, FILE *f) {
  for (size_t i=0; i<len; i++) {
    dbl2file(f, buf[i]);
  }
}

/**
 *
 */
static void fill_buf_rand(double *buf, size_t len) {
  for (size_t i=0; i<len; i++) {
    buf[i] = rand_double();
  }
}

/**
 *
 */
static bool is_equal(const double *c, const double *c_ref, size_t len) {

  for (size_t i=0; i<len; i++) {
    double delta = fabs(c[i] - c_ref[i]);
    if (delta > 1e-9) {
      std::cout << "*** ERROR: results too differ: " << i << " " << c[i] << " " << c_ref[i] << "\n";
      std::exit(-1);
      return false;
    }
  }
  return true;
}

/**
 *
 */
static FILE * open_mtrx_file(uint32_t m, uint32_t p, uint32_t n, const char *prefix) {
  const size_t N = 80;
  char str[N];
  memset(str, 0, N);
  snprintf(str, N, "stim/%s_%d_%d_%d.txt", prefix, m, p, n);

  return fopen(str,  "w");
}

/**
 *
 */
static void generate(size_t m, size_t p, size_t n, FILE *map_file) {

  FILE *a_file = open_mtrx_file(m-1, p-1, n-1, "a");
  FILE *b_file = open_mtrx_file(m-1, p-1, n-1, "b");
  FILE *c_file = open_mtrx_file(m-1, p-1, n-1, "c");

  size_t aL = m*p;
  size_t bL = p*n;
  size_t cL = m*n;

  double a[aL];
  double b[bL];
  double c[cL];
  double c_ref[cL];

  fill_buf_rand(a, aL);
  fill_buf_rand(b, bL);
  fill_buf_rand(c, cL);
  fill_buf_rand(c_ref, cL);

  matrix_multiply(m, p, n, a, b, c_ref);
  matrix_multiply_fpga(m, p, n, a, b, c);

  if (is_equal(c, c_ref, m*n)) {
    buf2file(a, aL, a_file);
    buf2file(b, bL, b_file);
    buf2file(c, cL, c_file);
    // matrix iterrator generate 1 spare read outside of test space
    // It is not a problem in hardware, but needs such workaround in
    // test suite
    dbl2file(a_file, 3.0/0.0); 
  }

  len2file(map_file, m-1);
  len2file(map_file, p-1);
  len2file(map_file, n-1);
}

/**
 *
 */ 
int main(void) {

  FILE *map_file = fopen("stim/map.txt", "w");

  srand (static_cast <unsigned> (time(0)));

  // first generate corner sizes
  // generate(2, 2, 2, map_file);
  // generate(1, 1, 1, map_file);
  // generate(MAX_MTRX, MAX_MTRX, MAX_MTRX, map_file);

  generate(1, MAX_MTRX, MAX_MTRX, map_file);
  // generate(1, 1, MAX_MTRX, map_file);
  //
  // generate(MAX_MTRX, MAX_MTRX, 1, map_file);
  // generate(MAX_MTRX, 1, 1, map_file);
  // generate(MAX_MTRX, MAX_MTRX, MAX_MTRX, map_file);
  // generate(MAX_MTRX, MAX_MTRX, MAX_MTRX, map_file);
  //
  // generate(MAX_MTRX, MAX_MTRX, 1, map_file);
  // generate(1, MAX_MTRX, MAX_MTRX, map_file);
  //
  // generate(1, MAX_MTRX, MAX_MTRX, map_file);
  // generate(MAX_MTRX, 1, MAX_MTRX, map_file);
  // generate(MAX_MTRX, MAX_MTRX, 1, map_file);

  return 0;
}


