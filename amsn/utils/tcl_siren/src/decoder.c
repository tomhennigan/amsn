#include "siren7.h"

SirenDecoder Siren7_NewDecoder(int sample_rate) {
	SirenDecoder decoder = (SirenDecoder) malloc(sizeof(struct stSirenDecoder));
	decoder->sample_rate = sample_rate;
	
	decoder->WavHeader.riff.RiffId = GUINT32_TO_LE(RIFF_ID);
	decoder->WavHeader.riff.RiffSize = sizeof(PCMWavHeader) - 2*sizeof(int);
	decoder->WavHeader.riff.RiffSize = GUINT32_TO_LE(decoder->WavHeader.riff.RiffSize);
	decoder->WavHeader.WaveId = GUINT32_TO_LE(WAVE_ID);

	decoder->WavHeader.FmtId = GUINT32_TO_LE(FMT__ID);
	decoder->WavHeader.FmtSize = GUINT32_TO_LE(sizeof(FmtChunk));
	
	decoder->WavHeader.fmt.Format = GUINT16_TO_LE(0x01);
	decoder->WavHeader.fmt.Channels = GUINT16_TO_LE(1);
	decoder->WavHeader.fmt.SampleRate = GUINT32_TO_LE(16000);
	decoder->WavHeader.fmt.ByteRate = GUINT32_TO_LE(32000);
	decoder->WavHeader.fmt.BlockAlign = GUINT16_TO_LE(2);
	decoder->WavHeader.fmt.BitsPerSample = GUINT16_TO_LE(16);

	decoder->WavHeader.FactId = GUINT32_TO_LE(FACT_ID);
	decoder->WavHeader.FactSize = GUINT32_TO_LE(sizeof(int));
	decoder->WavHeader.Samples = GUINT32_TO_LE(0);

	decoder->WavHeader.DataId = GUINT32_TO_LE(DATA_ID);
	decoder->WavHeader.DataSize = GUINT32_TO_LE(0);

	memset(decoder->context, 0, sizeof(decoder->context));
	memset(decoder->backup_frame, 0, sizeof(decoder->backup_frame));

	decoder->previous_frame_error = 0;
	decoder->dw1 = 1;
	decoder->dw2 = 1;
	decoder->dw3 = 1;
	decoder->dw4 = 1;

	siren_init();
	return decoder;
}

void Siren7_CloseDecoder(SirenDecoder decoder) {
	free(decoder);
}

int Siren7_DecodeFrame(SirenDecoder decoder, unsigned char *DataIn, unsigned char *DataOut) {
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
	int decoded_sample_rate_code;
	
	static int absolute_region_power_index[28] = {0}; 
	static float decoder_standard_deviation[28] = {0};
	static int power_categories[28] = {0};
	static int category_balance[28] = {0};
	int ChecksumTable[4] = {0x7F80, 0x7878, 0x6666, 0x5555};
	int i, j;

	int dwRes = 0;
	int envelope_bits = 0;
	int rate_control = 0;
	int number_of_available_bits;
	int number_of_valid_coefs;
	int frame_error;

	int In[20];
	float coefs[320];
	float BufferOut[320];
	int sum;
	int checksum;
	int calculated_checksum;
	int idx;
	int temp1;
	int temp2;
	
	int mystery[10];
	
	for (i = 0; i < 10; i++) 
	  mystery[i] = (i - 5) > 0 ? i-5: 5-i;

	for (i = 0; i < 20; i++) 
#ifdef __BIG_ENDIAN__
		In[i] = ((short *) DataIn)[i];
#else
		In[i] = ((((short *) DataIn)[i] << 8) & 0xFF00) | ((((short *) DataIn)[i] >> 8) & 0x00FF);
#endif

	dwRes = GetSirenCodecInfo(1, decoder->sample_rate, &number_of_coefs, &sample_rate_bits, &rate_control_bits, &rate_control_possibilities, &checksum_bits, &esf_adjustment, &scale_factor,  &number_of_regions, &sample_rate_code, &bits_per_frame );

	if (dwRes != 0)
		return dwRes;

	
	set_bitstream(In);

	decoded_sample_rate_code = 0;
    for (i = 0; i < sample_rate_bits; i++) {
		decoded_sample_rate_code <<= 1;
		decoded_sample_rate_code |= next_bit();
    } 


	if (decoded_sample_rate_code != sample_rate_code) 
		return 7;

	number_of_valid_coefs = region_size * number_of_regions;
	number_of_available_bits = bits_per_frame - sample_rate_bits  - checksum_bits ; 


	envelope_bits = decode_envelope(number_of_regions, decoder_standard_deviation, absolute_region_power_index, esf_adjustment);

	number_of_available_bits -= envelope_bits;
	
	for (i = 0; i < rate_control_bits; i++) {
		rate_control <<= 1;
		rate_control |= next_bit();
    }

	number_of_available_bits -= rate_control_bits; 

	categorize_regions(number_of_regions, number_of_available_bits, absolute_region_power_index, power_categories, category_balance);

	for (i = 0; i < rate_control; i++) {
		power_categories[category_balance[i]]++;
	}

	number_of_available_bits = decode_vector(decoder, number_of_regions, number_of_available_bits, decoder_standard_deviation, power_categories, coefs, scale_factor);


	frame_error = 0;
	if (number_of_available_bits > 0) {
		for (i = 0; i < number_of_available_bits; i++) {
			if (next_bit() == 0) 
				frame_error = 1;
		}	
	} else if (number_of_available_bits < 0 && rate_control + 1 < rate_control_possibilities) {
		frame_error |= 2;
	}

	for (i = 0; i < number_of_regions; i++) {
		if (absolute_region_power_index[i] > 33 || absolute_region_power_index[i] < -31)
			frame_error |= 4;
	}

	if (checksum_bits > 0) {
		bits_per_frame >>= 4;
		checksum = In[bits_per_frame - 1] & ((1 << checksum_bits)  - 1);
		In[bits_per_frame - 1] &= ~checksum;
		sum = 0;
		idx = 0;
		do {
			sum ^= (In[idx] & 0xFFFF) << (idx % 15);
		} while (++idx < bits_per_frame);
 
		sum = (sum >> 15) ^ (sum & 0x7FFF);
		calculated_checksum = 0;
		for (i = 0; i < 4; i++) {
			temp1 = ChecksumTable[i] & sum;
			for (j = 8; j > 0; j >>= 1) {
				temp2 = temp1 >> j;
				temp1 ^= temp2;
			}
			calculated_checksum <<= 1;
			calculated_checksum |= temp1 & 1;
		}
 
		if (checksum != calculated_checksum)
			frame_error |= 8;
	}

	if (frame_error != 0) {
		for (i = 0; i < number_of_valid_coefs; i++) {
			coefs[i] = decoder->backup_frame[i];
			decoder->backup_frame[i] = 0;
		}
	} else if (decoder->previous_frame_error == 0) {
		for (i = 0; i < number_of_valid_coefs; i++)
			decoder->backup_frame[i] = coefs[i];
	}
	decoder->previous_frame_error = frame_error;


	for (i = number_of_valid_coefs; i < number_of_coefs; i++)
		coefs[i] = 0;


	dwRes = siren_rmlt_decode_samples(coefs, decoder->context, 320, BufferOut);


	for (i = 0; i < 320; i++) {
		if (BufferOut[i] > 32767.0)
			((short *)DataOut)[i] =  32767;
		else if (BufferOut[i] <= -32768.0) 
			((short *)DataOut)[i] =  32768;
		else
			((short *)DataOut)[i] = (short) BufferOut[i];
	}

	decoder->WavHeader.Samples = GUINT32_FROM_LE(decoder->WavHeader.Samples);
	decoder->WavHeader.Samples += 320;
	decoder->WavHeader.Samples = GUINT32_TO_LE(decoder->WavHeader.Samples);
	decoder->WavHeader.DataSize = GUINT32_FROM_LE(decoder->WavHeader.DataSize);
	decoder->WavHeader.DataSize += 640;
	decoder->WavHeader.DataSize = GUINT32_TO_LE(decoder->WavHeader.DataSize);
	decoder->WavHeader.riff.RiffSize = GUINT32_FROM_LE(decoder->WavHeader.riff.RiffSize);
	decoder->WavHeader.riff.RiffSize += 640;
	decoder->WavHeader.riff.RiffSize = GUINT32_TO_LE(decoder->WavHeader.riff.RiffSize);


	return 0;
}

