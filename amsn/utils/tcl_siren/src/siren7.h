#ifndef _SIREN7_H
#define _SIREN7_H

#include "encoder.h"

extern SirenEncoder Siren7_NewEncoder(int sample_rate); /* MUST be 16000 to be compatible with MSN Voice clips (I think) */
extern void Siren7_CloseEncoder(SirenEncoder encoder);
extern int Siren7_EncodeFrame(SirenEncoder encoder, unsigned char *DataIn, unsigned char *DataOut);
extern void Siren7_GenerateWavHeader(SirenEncoder encoder, SirenWavHeader header);

#endif /* _SIREN7_H */