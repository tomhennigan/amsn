#include "siren7.h"


static int rmlt_initialized = 0;
static float rmlt_window_640[640];
static float rmlt_window_320[320];

#define PI_2     1.57079632679489661923

void siren_rmlt_init() { 
	int i = 0;
	float angle;

	for (i = 0; i < 640; i++) {
		angle = (float) (((i + 0.5) * PI_2) / 640);
		rmlt_window_640[i] = (float) sin(angle); 
	}
	for (i = 0; i < 320; i++) {
		angle = (float) (((i + 0.5) * PI_2) / 320);
		rmlt_window_320[i] = (float) sin(angle); 
	}

	rmlt_initialized = 1;
}

int siren_rmlt(float *samples, float *old_samples, int dct_length, float *rmlt_coefs) { 
	int half_dct_length = dct_length / 2;
	float *old_ptr = old_samples + half_dct_length;
	float *coef_high = rmlt_coefs + half_dct_length;
	float *coef_low = rmlt_coefs + half_dct_length;
	float *samples_low = samples;
	float *samples_high = samples + dct_length;
	float *window_low = NULL;
	float *window_high = NULL;
	int i = 0;

	if (rmlt_initialized == 0)
		siren_rmlt_init();

	if (dct_length == 320)
		window_low = rmlt_window_320;
	else if (dct_length == 640)
		window_low = rmlt_window_640;
	else 
		return 4;
	
	window_high = window_low + dct_length;

	
	for (i = 0; i < half_dct_length; i++) {
		*--coef_low = *--old_ptr;
		*coef_high++ = (*samples_low * *--window_high) - (*--samples_high * *window_low);
		*old_ptr = (*samples_high * *window_high) + (*samples_low++ * *window_low++);
	}
	siren_dct4(rmlt_coefs, rmlt_coefs, dct_length);

	return 0;
}