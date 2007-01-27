#include "siren7.h"


SirenEncoder Siren7_NewEncoder(int sample_rate) {
	SirenEncoder encoder = (SirenEncoder) malloc(sizeof(struct stSirenEncoder));
	encoder->sample_rate = sample_rate;
	
	encoder->WavHeader.riff.RiffId = GUINT32_TO_LE(RIFF_ID);
	encoder->WavHeader.riff.RiffSize = sizeof(SirenWavHeader) - 2*sizeof(int);
	encoder->WavHeader.riff.RiffSize = GUINT32_TO_LE(encoder->WavHeader.riff.RiffSize);
	encoder->WavHeader.WaveId = GUINT32_TO_LE(WAVE_ID);

	encoder->WavHeader.FmtId = GUINT32_TO_LE(FMT__ID);
	encoder->WavHeader.FmtSize = GUINT32_TO_LE(sizeof(SirenFmtChunk));
	
	encoder->WavHeader.fmt.fmt.Format = GUINT16_TO_LE(0x028E);
	encoder->WavHeader.fmt.fmt.Channels = GUINT16_TO_LE(1);
	encoder->WavHeader.fmt.fmt.SampleRate = GUINT32_TO_LE(16000);
	encoder->WavHeader.fmt.fmt.ByteRate = GUINT32_TO_LE(2000);
	encoder->WavHeader.fmt.fmt.BlockAlign = GUINT16_TO_LE(40);
	encoder->WavHeader.fmt.fmt.BitsPerSample = GUINT16_TO_LE(0);
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



int Siren7_EncodeFrame(SirenEncoder encoder, unsigned char *DataIn, unsigned char *DataOut) {
	int number_of_coefs,
		sample_rate_bits,
		rate_control_bits, 
		rate_control_possibilities, 
		checksum_bits,
		esf_adjustment,
		scale_factor,
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

	dwRes = siren_rmlt_encode_samples(In, context, 320, coefs); 


	if (dwRes != 0)
		return dwRes;

	dwRes = GetSirenCodecInfo(1, sample_rate, &number_of_coefs, &sample_rate_bits, &rate_control_bits, &rate_control_possibilities, &checksum_bits, &esf_adjustment, &scale_factor, &number_of_regions, &sample_rate_code, &bits_per_frame );

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

