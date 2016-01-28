#include <cmath>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <cstdio>
#include <stdint.h>
#include <iostream>
#include <fstream>

#define INPUT_LEN   31

static const double MAX_MTRX_NUM = 10000;
static const double MIN_MTRX_NUM = .0001;

/**
 *
 */
static double rand_double(void) {
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
static double double_accumulate(const double *d, size_t len) {
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
    return(double_accumulate(buf, N)); // recursive call
}

/**
 *
 */
static void generate(size_t len, FILE *in_file, FILE *out_file, FILE *map_file) {
  double buf[len];
  double sum_ref = 0;
  double sum_dbg = 0;
  
  for (size_t i=0; i<len; i++) {
    buf[i] = rand_double();
    dbl2file(in_file, buf[i]);
    sum_dbg += buf[i];
  }

  sum_ref = double_accumulate(buf, len);
  double delta = fabs(sum_ref - sum_dbg);
  //std::cout << "delta = " << delta << "\n";
  if (delta > 1e-10) {
    std::cout << "*** ERROR: results too differ: " << sum_ref << " " << sum_dbg << "\n";
    std::exit(-1);
  }

  dbl2file(out_file, sum_ref);
  len2file(map_file, len);
}

/**
 *
 */ 
int main(void) {

  FILE *in_file  = fopen("stim/in.txt",  "w");
  FILE *out_file = fopen("stim/out.txt", "w");
  FILE *map_file = fopen("stim/map.txt", "w");

  srand (static_cast <unsigned> (time(0)));

  generate(INPUT_LEN, in_file, out_file, map_file);

  return 0;
}


