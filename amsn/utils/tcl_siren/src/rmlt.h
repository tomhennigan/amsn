#ifndef _SIREN7_RMLT_H_
#define _SIREN7_RMLT_H_

extern void siren_rmlt_init();
extern int siren_rmlt_encode_samples(float *samples, float *old_samples, int dct_length, float *rmlt_coefs);
extern int siren_rmlt_decode_samples(float *coefs, float *old_coefs, int dct_length, float *samples);

#endif /* _SIREN7_RMLT_H_ */