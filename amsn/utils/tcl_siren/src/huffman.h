#ifndef _SIREN7_HUFFMAN_H_
#define _SIREN7_HUFFMAN_H_

extern int compute_region_powers(int number_of_regions, float *coefs, int *drp_num_bits, int *drp_code_bits, int *absolute_region_power_index, int esf_adjustment);
extern int quantize_mlt(int number_of_regions, int rate_control_possibilities, int number_of_available_bits, float *coefs, int *absolute_region_power_index, 
				 int *power_categories, int *category_balance, int *region_mlt_bit_counts, int *region_mlt_bits);


#endif /* _SIREN7_HUFFMAN_H_ */