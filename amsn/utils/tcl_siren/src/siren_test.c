#include <stdio.h>
#include "siren7.h"

#define RIFF_ID 0x46464952
#define WAVE_ID 0x45564157
#define FMT__ID 0x20746d66
#define DATA_ID 0x61746164
#define FACT_ID 0x74636166

typedef struct {
	unsigned int ChunkId;
	unsigned int ChunkSize;
} WAVE_CHUNK;

typedef struct {
	unsigned int ChunkId;
	unsigned int ChunkSize;
	unsigned int TypeID;
} RIFF;

typedef struct {
	unsigned short Format; 
	unsigned short Channels;
	unsigned int SampleRate; 
	unsigned int ByteRate;
	unsigned short BlockAlign;
	unsigned short BitsPerSample;
} fmtChunk;

typedef struct {
	fmtChunk fmt;
	unsigned short ExtraSize;
	unsigned char *ExtraContent;
} fmtChunkEx;


#define IDX(val, i) ((unsigned int) ((unsigned char *) &val)[i])

#define GUINT16_FROM_LE(val) ( (unsigned short) ( IDX(val, 0) + (unsigned short) IDX(val, 1) * 256 ))
#define GUINT32_FROM_LE(val) ( (unsigned int) (IDX(val, 0) + IDX(val, 1) * 256 + \
        IDX(val, 2) * 65536 + IDX(val, 3) * 16777216)) 



int main(int argc, char *argv[]) {
	FILE * input;
	FILE * output;
	RIFF riff_header;
	WAVE_CHUNK current_chunk;
	fmtChunkEx fmt_info;
	unsigned char *out_data = NULL;
	unsigned char *out_ptr = NULL;
	unsigned char InBuffer[640];
	unsigned int fileOffset;
	unsigned int chunkOffset;

	SirenEncoder encoder = Siren7_NewEncoder(16000);

	if (argc < 3) {
		fprintf(stderr, "Usage : %s <input wav file> <output wav file>\n",  argv[0]);
		return -1;
	}
	
	input = fopen(argv[1], "rb");
	if (input == NULL) {
		perror("fopen input");
		Siren7_CloseEncoder(encoder);
		return -1;
	}
	output = fopen(argv[2], "wb");
	if (output == NULL) {
		perror("fopen output");
		Siren7_CloseEncoder(encoder);
		return -1;
	}


	fileOffset = 0;
	fread(&riff_header, sizeof(RIFF), 1, input);
	fileOffset += sizeof(RIFF);

	riff_header.ChunkId = GUINT32_FROM_LE(riff_header.ChunkId);
	riff_header.ChunkSize = GUINT32_FROM_LE(riff_header.ChunkSize);
	riff_header.TypeID = GUINT32_FROM_LE(riff_header.TypeID);

	if (riff_header.ChunkId == RIFF_ID && riff_header.TypeID == WAVE_ID) {
		while (fileOffset < riff_header.ChunkSize) {
			fread(&current_chunk, sizeof(WAVE_CHUNK), 1, input);
			fileOffset += sizeof(WAVE_CHUNK);
			current_chunk.ChunkId = GUINT32_FROM_LE(current_chunk.ChunkId);
			current_chunk.ChunkSize = GUINT32_FROM_LE(current_chunk.ChunkSize);

			chunkOffset = 0;
			if (current_chunk.ChunkId == FMT__ID) {
				fread(&fmt_info, sizeof(fmtChunk), 1, input);
				/* Should convert from LE the fmt_info structure, but it's not necessary... */
				if (current_chunk.ChunkSize > sizeof(fmtChunk)) {
					fread(&(fmt_info.ExtraSize), sizeof(short), 1, input);
					fmt_info.ExtraSize= GUINT32_FROM_LE(fmt_info.ExtraSize);
					fmt_info.ExtraContent = (unsigned char *) malloc (fmt_info.ExtraSize);
					fread(fmt_info.ExtraContent, fmt_info.ExtraSize, 1, input);
				} else {
					fmt_info.ExtraSize = 0;
					fmt_info.ExtraContent = NULL;
				}
			} else if (current_chunk.ChunkId  == DATA_ID) {
				out_data = (unsigned char *) malloc(current_chunk.ChunkSize / 16);
				out_ptr = out_data;
				while (chunkOffset + 640 <= current_chunk.ChunkSize) {
					fread(InBuffer, 1, 640, input);
					Siren7_EncodeFrame(encoder, InBuffer, out_ptr);
					out_ptr += 40;
					chunkOffset += 640;
				}
				fread(InBuffer, 1, current_chunk.ChunkSize - chunkOffset, input);
			} else {
				fseek(input, current_chunk.ChunkSize, SEEK_CUR);
			}
			fileOffset += current_chunk.ChunkSize;
		}
	}
	
	/* The WAV heder should be converted TO LE, but should be done inside the library and it's not important for now ... */
	fwrite(&(encoder->WavHeader), sizeof(encoder->WavHeader), 1, output);
	fwrite(out_data, 1, encoder->WavHeader.DataSize, output);
	fclose(output);

	Siren7_CloseEncoder(encoder);

	free(out_data);
	if (fmt_info.ExtraContent != NULL)
		free(fmt_info.ExtraContent);
	
}

