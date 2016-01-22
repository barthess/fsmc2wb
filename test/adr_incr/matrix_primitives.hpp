#ifndef MATRIX_PRIMITIVES_H
#define MATRIX_PRIMITIVES_H

#include <cstdint>

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
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 * @note    matrix A transposed
 */
template <typename T>
void matrix_multiply_TA(size_t m, size_t p, size_t n,
                        const T *A, const T *B, T *C) {
  size_t i, j, k;
  T tmp;

  for(i=0; i<m; i++) {
    for(j=0; j<n; j++) {
      tmp = 0;
      for(k=0; k<p; k++)
        tmp += A[k*m + i] * B[k*n + j];
      *C++ = tmp;
    }
  }
}

/**
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 * @note    matrix B transposed
 */
template <typename T>
void matrix_multiply_TB(size_t m, size_t p, size_t n,
                        const T *A, const T *B, T *C) {
  size_t i, j, k;
  T tmp;

  for(i=0; i<m; i++) {
    for(j=0; j<n; j++) {
      tmp = 0;
      for(k=0; k<p; k++)
        tmp += A[i*p + k] * B[j*p + k];
      *C++ = tmp;
    }
  }
}

/**
 * @brief   multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
 * @note    matrices A and B transposed
 */
template <typename T>
void matrix_multiply_TAB(size_t m, size_t p, size_t n,
                         const T *A, const T *B, T *C) {
  size_t i, j, k;
  T tmp;

  for(i=0; i<m; i++) {
    for(j=0; j<n; j++) {
      tmp = 0;
      for(k=0; k<p; k++)
        tmp += A[k*m + i] * B[j*p + k];
      *C++ = tmp;
    }
  }
}

#endif
