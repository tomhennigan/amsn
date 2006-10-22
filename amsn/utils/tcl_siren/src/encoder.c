#include "siren7.h"

static int siren_initialized = 0;


#define RIFF_ID 0x46464952
#define WAVE_ID 0x45564157
#define FMT__ID 0x20746d66
#define DATA_ID 0x61746164
#define FACT_ID 0x74636166

SirenEncoder Siren7_NewEncoder(int sample_rate) {
	SirenEncoder encoder = (SirenEncoder) malloc(sizeof(struct stSirenEncoder));
	encoder->sample_rate = sample_rate;
	
	encoder->WavHeader.riff.RiffId = GUINT32_TO_LE(RIFF_ID);
	encoder->WavHeader.riff.RiffSize = sizeof(SirenWavHeader) - 2*sizeof(int);
	encoder->WavHeader.riff.RiffSize = GUINT32_TO_LE(encoder->WavHeader.riff.RiffSize);
	encoder->WavHeader.WaveId = GUINT32_TO_LE(WAVE_ID);

	encoder->WavHeader.FmtId = GUINT32_TO_LE(FMT__ID);
	encoder->WavHeader.FmtSize = GUINT32_TO_LE(sizeof(FmtChunk));
	
	encoder->WavHeader.fmt.Format = GUINT16_TO_LE(0x028E);
	encoder->WavHeader.fmt.Channels = GUINT16_TO_LE(1);
	encoder->WavHeader.fmt.SampleRate = GUINT32_TO_LE(16000);
	encoder->WavHeader.fmt.ByteRate = GUINT32_TO_LE(2000);
	encoder->WavHeader.fmt.BlockAlign = GUINT16_TO_LE(40);
	encoder->WavHeader.fmt.BitsPerSample = GUINT16_TO_LE(0);
	encoder->WavHeader.fmt.ExtraSize = GUINT16_TO_LE(2);
	encoder->WavHeader.fmt.DctLength = GUINT16_TO_LE(320);

	encoder->WavHeader.FactId = GUINT32_TO_LE(FACT_ID);
	encoder->WavHeader.FactSize = GUINT32_TO_LE(sizeof(int));
	encoder->WavHeader.Samples = GUINT32_TO_LE(0);

	encoder->WavHeader.DataId = GUINT32_TO_LE(DATA_ID);
	encoder->WavHeader.DataSize = GUINT32_TO_LE(0);

	memset(encoder->context, 0, sizeof(encoder->context));

	siren_init();
	return encoder;
}

void Siren7_CloseEncoder(SirenEncoder encoder) {
	free(encoder);
}


/*
 STEPSIZE = 2.0 * log(sqrt(2));
 */
#define STEPSIZE 0.3010299957

void siren_init() {
	int i;
	float region_power,
		standard_deviation;

	if (siren_initialized == 1)
		return;

	region_size = 20; 
	region_size_inverse = 1.0f/region_size; 
	
	for (i = 0; i < 64; i++) {		
		region_power = (float) pow(10, (i-24) * STEPSIZE); 
		standard_deviation = (float) sqrt(region_power); 
		deviation_inverse[i] = (float) 1.0 / standard_deviation;
	}

	for (i = 0; i < 63; i++) 
		region_power_table_boundary[i] = (float) pow(10, (i-24 + 0.5) * STEPSIZE); 

	for (i = 0; i < 8; i++) 
		step_size_inverse[i] = (float) 1.0 / step_size[i];

	siren_dct4_init();
	siren_rmlt_init();

	siren_initialized = 1;
}


static int GetEncoderInfo(int flag, int sample_rate, int *sample_rate_bits, int *rate_control_bits, int *rate_control_possibilities, int *val5, int *esf_adjustment, int *number_of_regions, int *sample_rate_code, int *bits_per_frame ) {
	switch (flag) {
		case 0:
			*sample_rate_bits = 0;
			*rate_control_bits = 4;
			*rate_control_possibilities = 16;
			*val5 = 0;
			*esf_adjustment = 7;
			*number_of_regions = 14; 
			*sample_rate_code = 0;
			break;
		case 1:
			*sample_rate_bits = 2;
			*rate_control_bits = 4;
			*rate_control_possibilities = 16;
			*val5 = 4;
			*esf_adjustment = -2;
			*number_of_regions = 14;
			if (sample_rate == 16000)
				*sample_rate_code = 1;
			else if (sample_rate == 24000)
				*sample_rate_code = 2;
			else if (sample_rate == 32000)
				*sample_rate_code = 3;
			else
				return 3;
			break;
		case 2:	
			*sample_rate_bits = 2;
			*rate_control_bits = 5;
			*rate_control_possibilities = 32;
			*val5 = 4;
			*esf_adjustment = 7;
			*number_of_regions = 28;

			if (sample_rate == 24000)
				*sample_rate_code = 1;
			else if (sample_rate == 24000)
				*sample_rate_code = 2;
			else if (sample_rate == 48000)
				*sample_rate_code = 3;
			else
				return 3;
			
			break;
		case 3:
			*sample_rate_bits = 6;
			*rate_control_bits = 5;
			*rate_control_possibilities = 32;
			*val5 = 4;
			*esf_adjustment = 7;
			switch (sample_rate) {
			case 8800:
				*number_of_regions = 12;
				*sample_rate_code = 59;
				break;
			case 9600:
				*number_of_regions = 12;
				*sample_rate_code = 1;	
				break;			
			case 10400:
				*number_of_regions = 12;
				*sample_rate_code = 13;
				break;
			case 10800:
				*number_of_regions = 12;
				*sample_rate_code = 14;
				break;
			case 11200:
				*number_of_regions = 12;
				*sample_rate_code = 15;
				break;
			case 11600:
				*number_of_regions = 12;
				*sample_rate_code = 16;
				break;
			case 12000:
				*number_of_regions = 12;
				*sample_rate_code = 2;
				break;
			case 12400:
				*number_of_regions = 12;
				*sample_rate_code = 17;
				break;
			case 12800:
				*number_of_regions = 12;
				*sample_rate_code = 18;
				break;
			case 13200:
				*number_of_regions = 12;
				*sample_rate_code = 19;
				break;
			case 13600:
				*number_of_regions = 12;
				*sample_rate_code = 20;
				break;
			case 14000:
				*number_of_regions = 12;
				*sample_rate_code = 21;
				break;
			case 14400:
				*number_of_regions = 16;
				*sample_rate_code = 3;
				break;
			case 14800:
				*number_of_regions = 16;
				*sample_rate_code = 22;
				break;
			case 15200:
				*number_of_regions = 16;
				*sample_rate_code = 23;
				break;
			case 15600:
				*number_of_regions = 16;
				*sample_rate_code = 24;
				break;
			case 16000:
				*number_of_regions = 16;
				*sample_rate_code = 25;
				break;
			case 16400:
				*number_of_regions = 16;
				*sample_rate_code = 26;
				break;
			case 16800:
				*number_of_regions = 18;
				*sample_rate_code = 4;
				break;
			case 17200:
				*number_of_regions = 18;
				*sample_rate_code = 27;
				break;
			case 17600:
				*number_of_regions = 18;
				*sample_rate_code = 28;
				break;
			case 18000:
				*number_of_regions = 18;
				*sample_rate_code = 29;
				break;
			case 18400:
				*number_of_regions = 18;
				*sample_rate_code = 30;
				break;
			case 18800:
				*number_of_regions = 18;
				*sample_rate_code = 31;
				break;
			case 19200:
				*number_of_regions = 20;
				*sample_rate_code = 5;
				break;
			case 19600:
				*number_of_regions = 20;
				*sample_rate_code = 32;
				break;
			case 20000:
				*number_of_regions = 20;
				*sample_rate_code = 33;
				break;
			case 20400:
				*number_of_regions = 20;
				*sample_rate_code = 34;
				break;
			case 20800:
				*number_of_regions = 20;
				*sample_rate_code = 35;
				break;
			case 21200:
				*number_of_regions = 20;
				*sample_rate_code = 36;
				break;
			case 21600:
				*number_of_regions = 22;
				*sample_rate_code = 6;
				break;
			case 22000:
				*number_of_regions = 22;
				*sample_rate_code = 37;
				break;
			case 22400:
				*number_of_regions = 22;
				*sample_rate_code = 38;
				break;
			case 22800:
				*number_of_regions = 22;
				*sample_rate_code = 39;
				break;
			case 23200:
				*number_of_regions = 22;
				*sample_rate_code = 40;
				break;
			case 23600:
				*number_of_regions = 22;
				*sample_rate_code = 41;
				break;
			case 24000:
				*number_of_regions = 24;
				*sample_rate_code = 7;
				break;
			case 24400:
				*number_of_regions = 24;
				*sample_rate_code = 42;
				break;
			case 24800:
				*number_of_regions = 24;
				*sample_rate_code = 43;
				break;
			case 25200:
				*number_of_regions = 24;
				*sample_rate_code = 44;
				break;
			case 25600:
				*number_of_regions = 24;
				*sample_rate_code = 45;
				break;
			case 26000:
				*number_of_regions = 24;
				*sample_rate_code = 46;
				break;
			case 26400:
				*number_of_regions = 26;
				*sample_rate_code = 8;
				break;
			case 26800:
				*number_of_regions = 26;
				*sample_rate_code = 47;
				break;
			case 27200:
				*number_of_regions = 26;
				*sample_rate_code = 48;
				break;
			case 27600:
				*number_of_regions = 26;
				*sample_rate_code = 49;
				break;
			case 28000:
				*number_of_regions = 26;
				*sample_rate_code = 50;
				break;
			case 28400:
				*number_of_regions = 26;
				*sample_rate_code = 51;
				break;
			case 28800:
				*number_of_regions = 28;
				*sample_rate_code = 9;
				break;
			case 29200:
				*number_of_regions = 28;
				*sample_rate_code = 52;
				break;
			case 29600:
				*number_of_regions = 28;
				*sample_rate_code = 53;
				break;
			case 30000:
				*number_of_regions = 28;
				*sample_rate_code = 54;
				break;
			case 30400:
				*number_of_regions = 28;
				*sample_rate_code = 55;
				break;
			case 30800:
				*number_of_regions = 28;
				*sample_rate_code = 56;
				break;
			case 31200:
				*number_of_regions = 28;
				*sample_rate_code = 10;
				break;
			case 31600:
				*number_of_regions = 28;
				*sample_rate_code = 57;
				break;
			case 32000:
				*number_of_regions = 28;
				*sample_rate_code = 58;
				break;
			default:
				return 3;
				break;
		}
			break;
		default:
			return 6;
	}

	*bits_per_frame  = sample_rate / 50; 
	return 0;	
}



int Siren7_EncodeFrame(SirenEncoder encoder, unsigned char *DataIn, unsigned char *DataOut) {
	int sample_rate_bits,
		rate_control_bits, 
		rate_control_possibilities, 
		checksum_bits,
		esf_adjustment,
		number_of_regions, 
		sample_rate_code,
		bits_per_frame;
	int sample_rate = encoder->sample_rate;
	
	static int absolute_region_power_index[28] = {0}; 
	static int power_categories[28] = {0};
	static int category_balance[28] = {0};
	static int drp_num_bits[30] = {0};
	static int drp_code_bits[30] = {0};
	static int region_mlt_bit_counts[28] = {0};
	static int region_mlt_bits[112] = {0};
	int ChecksumTable[4] = {0x7F80, 0x7878, 0x6666, 0x5555};
	int i, j;

	int dwRes = 0;
	short out_word;
	int bits_left;
	int current_word_bits_left;
	int region_bit_count;
	unsigned int current_word;
	unsigned int sum;
	unsigned int checksum;
	int temp1 = 0;
	int temp2 = 0;
	int region;
	int idx = 0;
	int envelope_bits = 0;
	int rate_control;
	int number_of_available_bits;

	float coefs[320];
	float In[320];
	short BufferOut[20];
	float *context = encoder->context;
	int mystery[10];
	
	for (i = 0; i < 10; i++) 
	  mystery[i] = (i - 5) > 0 ? i-5: 5-i;
	

	for (i = 0; i < 320; i++) 
		In[i] = (float) ((short) GUINT16_FROM_LE(((short *) DataIn)[i]));

	dwRes = siren_rmlt(In, (float *) context, 320, coefs); 


	if (dwRes != 0)
		return dwRes;

	dwRes = GetEncoderInfo(1, sample_rate, &sample_rate_bits, &rate_control_bits, &rate_control_possibilities, &checksum_bits, &esf_adjustment, &number_of_regions, &sample_rate_code, &bits_per_frame );

	if (dwRes != 0)
		return dwRes;

	envelope_bits = compute_region_powers(number_of_regions, coefs, drp_num_bits, drp_code_bits, absolute_region_power_index, esf_adjustment); 

	number_of_available_bits = bits_per_frame - rate_control_bits - envelope_bits - sample_rate_bits  - checksum_bits ; 

	categorize_regions(number_of_regions, number_of_available_bits, absolute_region_power_index, power_categories, category_balance);

	for(region = 0; region < number_of_regions; region++) {
		absolute_region_power_index[region] += 24;
		region_mlt_bit_counts[region] = 0;
	}

	rate_control = quantize_mlt(number_of_regions, rate_control_possibilities, number_of_available_bits, coefs, absolute_region_power_index, power_categories, category_balance, region_mlt_bit_counts, region_mlt_bits); 

	idx = 0;
	bits_left = 16 - sample_rate_bits;
	out_word = sample_rate_code << (16 - sample_rate_bits);
	drp_num_bits[number_of_regions] = rate_control_bits;
	drp_code_bits[number_of_regions] = rate_control;
	for (region = 0; region <= number_of_regions; region++) {
		i = drp_num_bits[region] - bits_left;
		if (i < 0) {
			out_word += drp_code_bits[region] << -i; 
			bits_left -= drp_num_bits[region];
		} else {
			BufferOut[idx++] = out_word + (drp_code_bits[region] >> i);
			bits_left += 16 - drp_num_bits[region];
			out_word = drp_code_bits[region] << bits_left;
		}
	}

	for (region = 0; region < number_of_regions && (16*idx) < bits_per_frame; region++) {
		current_word_bits_left = region_bit_count = region_mlt_bit_counts[region];
		if (current_word_bits_left > 32) 
			current_word_bits_left = 32;
		
		current_word = region_mlt_bits[region*4];
		i = 1;
		while(region_bit_count > 0 && (16*idx) < bits_per_frame) {
			if (current_word_bits_left < bits_left) {
				bits_left -= current_word_bits_left;
				out_word += (current_word >> (32 - current_word_bits_left)) << bits_left;
				current_word_bits_left = 0;
			} else {
				BufferOut[idx++] = (short) (out_word + (current_word >> (32 - bits_left)));
				current_word_bits_left -= bits_left;
				current_word <<= bits_left;
				bits_left = 16;
				out_word = 0;
			}
			if (current_word_bits_left == 0) {
				region_bit_count -= 32;
				current_word = region_mlt_bits[(region*4) + i++];
				current_word_bits_left = region_bit_count;
				if (current_word_bits_left > 32) 
					current_word_bits_left = 32;
			}
		}
	}


	while ( (16*idx) < bits_per_frame) {
		BufferOut[idx++] = (short) ((0xFFFF >> (16 - bits_left)) + out_word);
		bits_left = 16;
		out_word = 0;
	}

	if (checksum_bits > 0) {
		BufferOut[idx-1] &= (-1 << checksum_bits);
		sum = 0;
		idx = 0;
		do {
			sum ^= (BufferOut[idx] & 0xFFFF) << (idx % 15);
		} while ((16*++idx) < bits_per_frame);
	
		sum = (sum >> 15) ^ (sum & 0x7FFF);
		checksum = 0;
		for (i = 0; i < 4; i++) {
			temp1 = ChecksumTable[i] & sum;
			for (j = 8; j > 0; j >>= 1) {
				temp2 = temp1 >> j;
				temp1 ^= temp2;
			}
			checksum <<= 1;
			checksum |= temp1 & 1;
		}
		BufferOut[idx-1] |= ((1 << checksum_bits) -1) & checksum;
	}

	

	for (i = 0; i < 20; i++) 
#ifdef __BIG_ENDIAN__
		((short *) DataOut)[i] = BufferOut[i];
#else
		((short *) DataOut)[i] = ((BufferOut[i] << 8) & 0xFF00) | ((BufferOut[i] >> 8) & 0x00FF);
#endif

	encoder->WavHeader.Samples = GUINT32_FROM_LE(encoder->WavHeader.Samples);
        encoder->WavHeader.Samples += 320;
	encoder->WavHeader.Samples = GUINT32_TO_LE(encoder->WavHeader.Samples);
	encoder->WavHeader.DataSize = GUINT32_FROM_LE(encoder->WavHeader.DataSize);
        encoder->WavHeader.DataSize += 40;
	encoder->WavHeader.DataSize = GUINT32_TO_LE(encoder->WavHeader.DataSize);
	encoder->WavHeader.riff.RiffSize = GUINT32_FROM_LE(encoder->WavHeader.riff.RiffSize);
        encoder->WavHeader.riff.RiffSize += 40;
	encoder->WavHeader.riff.RiffSize = GUINT32_TO_LE(encoder->WavHeader.riff.RiffSize);


	return 0;
}

