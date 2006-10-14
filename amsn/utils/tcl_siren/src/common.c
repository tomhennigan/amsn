#include "siren7.h"

int region_size;
float region_size_inverse;

float deviation_inverse[64];
float region_power_table_boundary[63];

int expected_bits_table[8] = {52, 47, 43, 37, 29, 22, 16, 0}; 
int vector_dimension[8] = {2, 2, 2, 4, 4, 5, 5, 1};
int number_of_vectors[8] = {10, 10, 10, 5, 5, 4, 4, 20};
float dead_zone[8] = {0.3f, 0.33f, 0.36f, 0.39f, 0.42f, 0.45f, 0.5f, 0.5f}; 

int max_bin[8] = { 
		13,
		9,
		6,
		4,
		3,
		2,
		1,
		1};

float step_size[8] = {
		0.3536f,
		0.5f,
		0.70709997f,
		1.0f,
		1.4141999f,
		2.0f,
		2.8283999f,
		2.8283999f};

float step_size_inverse[8]; 


int categorize_regions(int number_of_regions, int number_of_available_bits, int *absolute_region_power_index, int *power_categories, int *category_balance) {
	int region, delta, i, temp;
	int expected_number_of_code_bits;
	int min, max;
	int offset,
		num_rate_control_possibilities, 
		raw_value,
		raw_max_idx = 0, 
		raw_min_idx = 0;
	int max_rate_categories[28];
	int min_rate_categories[28];
	int temp_category_balances[64]; 
	int *min_rate_ptr = NULL;
	int *max_rate_ptr = NULL;

	if (number_of_regions == 14) {
		num_rate_control_possibilities = 16;
		if ( number_of_available_bits > 320) 
			number_of_available_bits = ((number_of_available_bits - 320) * 5/8) + 320;
		
	} else {
		num_rate_control_possibilities = 32;
		if (number_of_regions  == 28 && number_of_available_bits > 640) 
			number_of_available_bits = ((number_of_available_bits - 640) * 5/8) + 640;
	} 

	offset = -32;
	for (delta = 32; number_of_regions > 0 && delta > 0; delta /= 2) {
		expected_number_of_code_bits = 0;
		for (region = 0; region < number_of_regions; region++) {
			i = (delta + offset - absolute_region_power_index[region]) >> 1;
			if (i > 7) 
				i = 7;
			else if (i < 0)
				i = 0;
			
			power_categories[region] = i;
			expected_number_of_code_bits += expected_bits_table[i];

		}
		if (expected_number_of_code_bits >= number_of_available_bits-32) 
			offset += delta;
		
	}

	expected_number_of_code_bits = 0;
	for (region = 0; region  < number_of_regions; region++) {
		i = (offset - absolute_region_power_index[region]) >> 1;
		if (i > 7)
			i = 7;
		else if (i < 0)
			i = 0;
		max_rate_categories[region] = min_rate_categories[region] = power_categories[region] = i;
		expected_number_of_code_bits += expected_bits_table[i];
	}
	

	min = max = expected_number_of_code_bits;
	min_rate_ptr = max_rate_ptr = temp_category_balances + num_rate_control_possibilities;
	for (i = 0; i < num_rate_control_possibilities -1; i++) {
		if (min + max > number_of_available_bits * 2) {
			raw_value = -99;
			for (region = number_of_regions-1; region >= 0; region--) {
				if (min_rate_categories[region] < 7) {
					temp = offset - absolute_region_power_index[region] - 2*min_rate_categories[region];
					if (temp > raw_value) {
						raw_value = temp;
						raw_min_idx = region;
					}
				}
			}
			*min_rate_ptr++ = raw_min_idx;
			min += expected_bits_table[min_rate_categories[raw_min_idx] + 1] - expected_bits_table[min_rate_categories[raw_min_idx]];
			min_rate_categories[raw_min_idx]++;
		} else {
			raw_value = 99;
			for (region = 0; region < number_of_regions; region++) {
				if (max_rate_categories[region] > 0 ) {
					temp = offset - absolute_region_power_index[region] - 2*max_rate_categories[region];
					if (temp < raw_value) {
						raw_value = temp;
						raw_max_idx = region;
					}
				}
			}

			*--max_rate_ptr = raw_max_idx;
			max += expected_bits_table[max_rate_categories[raw_max_idx] - 1] - expected_bits_table[max_rate_categories[raw_max_idx]];
			max_rate_categories[raw_max_idx]--;
		}
	}

	for (region = 0; region < number_of_regions; region++) 
		power_categories[region] = max_rate_categories[region];

	for (i = 0; i < num_rate_control_possibilities-1; i++)
		category_balance[i] = *max_rate_ptr++;
	

	return 0;
}


