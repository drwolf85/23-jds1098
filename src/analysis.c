#include <stdlib.h>

/**
 * @brief Coonvert categorical data as float32 binary numbers
 * @param out Tensor of data using binary representation
 * @param dta Vector of categorical data to be convert
 * @param sz Length of the vector `dta`
 * @param yr Reference year (starting from zero)
 * @param twlen Length of the time-window in years
 */
void toBinFl32(unsigned char  *out, unsigned char *dta, size_t sz, size_t yr, size_t twlen) {
    size_t i;
    size_t const sq = twlen * 8;
    size_t const when = yr * 8;
    unsigned char k;

    #pragma omp parallel for simd private(i, k) collapse(2)
    for (i = 0; i < sz; i++) {
        for (k = 0; k < 8; k++) {
            out[(size_t) k + when + sq * i] = 1 & (dta[i] >> k);
        }
    }
}

/**
 * @brief Coonvert categorical data as float32 indicator variable
 * @param out Tensor of data using indicator variable representation
 * @param dta Vector of categorical data to be convert
 * @param sz Length of the vector `dta`
 * @param yr Reference year (starting from zero)
 * @param twlen Length of the time-window in years 
 */
void toIndFl32(unsigned char *out, unsigned char *dta, size_t sz, size_t yr, size_t twlen) {
    size_t i;
    size_t const sq = twlen * 256;
    size_t const when = yr * 256;

    #pragma omp parallel for private(i)
    for (i = 0; i < sz; i++) {
            out[(size_t) dta[i] + when + sq * i] = 1;
    }
}

/**
 * @brief Predict with multiple thresholds
 * @param cls predition array (as integer classes)
 * @param yhat predition array (as probabilities)
 * @param th thresholds (as an array of length 8)
 * @param n sample size
 */
void pred2UI8(unsigned char *cls, float *yhat, float *th, size_t n) {
    size_t i, k;

    #pragma omp parallel for simd private(i, k)
    for (i = 0; i < n; i++) {
        for (k = 0; k < 8; k++) {
            cls[i] += (unsigned char) (yhat[8 * i + k] >= th[k]) << k;
        }
    }
}
