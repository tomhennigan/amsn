#include <stdlib.h>
#include <string.h>

#include "kidhash.h"
#include "constants.h"

double append_multiplicator = 4.614703357219696e-7;

const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789./";

int init_variable = 0x0FE0637B1;

int init_table[31];
int init_table_size = 31;
int *init_table_ptr = NULL;
int *init_table_end = NULL;
int *init_table_idx2 = NULL;
int *init_table_idx1 = NULL;
int init_table_idx_diff = 3;

int fixed_value_3 = 3;

int key[26];


void crazy_algorithm(int *table,int *temp_data) {

	unsigned int i, idx, temp;

	// Initialize the 4 temp variables
	int P = table[1],
		PP = table[2],
		PPP = table[3],
		PPPP = table[0];


	// four loops made into one
	for (i = 0; i < 16*4; i++) {
		temp = PPPP + const_mult[i] * const_values[i];	// Common to all loops
		if(i/16 == 0) temp += temp_data[i] + (PPP ^ (P & (PP ^ PPP)));		// add this for first loop i =[0..15]
		if(i/16 == 1) temp += temp_data[((i-16)*5 + 1)%16] + (PP ^ (PPP & (P ^ PP))); // add for second i = [16..31]
		if(i/16 == 2) temp += temp_data[((i-32)*3 + 5)%16] + (P ^ (PP ^ PPP)); // add for second i = [31..47]
		if(i/16 == 3) temp += temp_data[choose_data_idx[i-48]] + (PP ^ ((PPP ^ 0xFFFFFFFF) | P)); // add for the last loop
		PPPP = PPP; PPP = PP; PP = P;
		P += (temp >> shifts_right[(i%4) + 4*(i/16)]) | (temp << shifts_left[(i%4) + 4*(i/16)]); // look for the shifts in the table
	}

	// store in the output variables
	table[0] += PPPP;
	table[1] += P;
	table[2] += PP;
	table[3] += PPP;


	return;
}


int alter_table() {

	int ret;

	if (fixed_value_3 != 0 ) {
		*init_table_idx2 = *init_table_idx1 + *init_table_idx2;
		ret = *init_table_idx2 >> 1 & 0x7fffffff;
		if (init_table_idx2 + 1 < init_table_end) {
			if(init_table_idx1 + 1 >= init_table_end) 
				init_table_idx1 = init_table_ptr;
			else
				init_table_idx1++;

			init_table_idx2++;
		} else {
			init_table_idx2 = init_table_ptr;
			init_table_idx1++;
		}

	} else {
		init_table_ptr[0] =  init_table_ptr[0] % 0x1f31d * 0x41a7 - 
			init_table_ptr[0] / 0x1f31d * 0xb14;
		if ( init_table_ptr[0] <= 0)
			init_table_ptr[0] += 0x7fffffff;
		init_table_ptr[0] &= 0x7fffffff;
		ret = init_table_ptr[0];
	}

	return ret;

}


void init(int value) {
	int i = 0;

	*init_table_ptr = value;

	if(fixed_value_3) {

		for (i = 1; i < init_table_size; i++) {
			init_table_ptr[i] =   init_table_ptr[i-1] % 0x1f31d * 0x41a7 - 
				init_table_ptr[i-1] / 0x1f31d * 0xb14;
			if ( init_table_ptr[i] <= 0)
				init_table_ptr[i] += 0x7fffffff;
		}

		init_table_idx1 = init_table_ptr;
		init_table_idx2 = init_table_ptr + init_table_idx_diff;

		for(i = init_table_size * 10; i > 0; i--) alter_table();
	}

	return;

}


void set_result (int *table, char * temp_data, int * result) {
	char * temp_data_ptr = temp_data;
	int idx;

	idx = (table[4] / 8) & 63;
	temp_data_ptr = temp_data + idx;
	*temp_data_ptr = 0x80;
	temp_data_ptr++;

	idx = 55 - idx;

	if ( idx  < 0) {
		memset(temp_data_ptr, 0, idx + 8);
		crazy_algorithm(table, (int *)temp_data);
		memset(temp_data, 0, 56);
	} else 
		memset(temp_data_ptr, 0, idx);

	temp_data_ptr += idx;

	// The last 2 dwords are size / 8 and a bool for if size > 64
	*((int *)temp_data_ptr) = table[4];
	temp_data_ptr+=4;
	*((int *)temp_data_ptr) = table[5];

	crazy_algorithm(table, (int *)temp_data);

	result[0] = table[0];
	result[1] = table[1];
	result[2] = table[2];
	result[3] = table[3];
	result[4] = 0;

}

void Hash(char * a, int key_size) {

	int result[5],
		table[] = {0x67452301, 
		0x0EFCDAB89,
		0x98BADCFE,
		0x10325476, 
		8*key_size,
		key_size >> 29};
	char temp_data[64];

	int *key_ptr = key;
	char *a_ptr = a;

	int i, temp;

	if(key_size >= 64) {
		for(i = key_size / 64; i > 0 ; i--) {
			memcpy(temp_data, key_ptr, 64);
			crazy_algorithm(table, (int *)temp_data);
			key_ptr += 16;
		} 
		key_size &= 63;
	}

	memcpy(temp_data, key_ptr, key_size);
	set_result(table, temp_data, result);

	for (i = 0 ; i < 18; i += 3) {
		temp = (0x000000ff &((char *) result)[i]) << 16 |
			(0x000000ff & ((char *) result)[i+1]) << 8  | 
			(0x000000ff & ((char *) result)[i+2]);

		a_ptr[0] = alphabet[temp >> 6 >> 6 >> 6 & 0x3F];
		a_ptr[1] = alphabet[temp >> 6 >> 6 & 0x3F];
		a_ptr[2] = alphabet[temp >> 6 & 0x3F];
		a_ptr[3] = alphabet[temp & 0x3F];
		a_ptr+=4;
	}

	*(a_ptr - 2) = 0;
}

int MakeKidHash(char *a, int *a_size, int kid, char * sid) {
	int i;
	char * sid_ptr = sid;
	char *key_ptr = (char *) key;

	if(kid < 0 || kid > 100) return 0;
	if (*a_size < 25) return 0;
	memset(key, 0, 26);

	init_table_ptr = init_table;
	init_table_idx1 = init_table_ptr;
	init_table_idx2 = init_table_ptr + init_table_idx_diff;
	init_table_end = init_table_ptr + init_table_size;


	for (i = 0 ; i < 100; i++) {
		if(*sid_ptr == 0) break;
		*key_ptr =  *sid_ptr;
		key_ptr++;
		sid_ptr++;
	}

	if (sid_ptr - sid + append_size > 100) return 0;

	init(init_variable);

	while(kid > 0) { 
		alter_table();
		kid--; 
	}

	memcpy(key_ptr, 
		key_append + (long) (alter_table() * append_multiplicator) * 4,
		append_size);

	Hash(a, (int) (sid_ptr - sid) + append_size);  

	return 1;
}

int test () {
	char sid[] = "sid=aD4ENXNY3Q";
	char sid2[] = "sid=KCSwrDFrVg"; 
	char a[30];
	int kid = 64;
	int kid2 = 98;
	int a_size = 30;

	printf("\n");

	if (MakeKidHash(a, &a_size, kid2, sid2)) {
		printf("Computed hash is : %s\n", a);
		printf("Should be        : hHQbVkZ/eApiRzPiTg6jyw\n\n\n");
	}

	if(MakeKidHash(a, &a_size, kid, sid)) {
		printf("Computed hash is : %s\n", a);
		printf("Should be        : HlyPs6/kiWhr0JxmMO1A4Q\n");
	} 

	printf("\n\n");

	return 0;    

}
