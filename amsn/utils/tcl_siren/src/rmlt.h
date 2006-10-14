#ifndef _SIREN7_RMLT_H_
#define _SIREN7_RMLT_H_

extern void siren_rmlt_init();
extern int siren_rmlt(float *samples, float *old_samples, int dct_length, float *rmlt_coefs);

#endif /* _SIREN7_RMLT_H_ */