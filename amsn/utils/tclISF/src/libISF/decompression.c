#include	<stdlib.h>
#include	<stdio.h>

#include	"libISF.h"
#include	"DecodeISF.h"
#include	"misc.h"

const int BitAmounts[8][11] =
{
    {0, 1, 2,  4,  6,  8, 12, 16, 24, 32, -1},
    {0, 1, 1,  2,  4,  8, 12, 16, 24, 32, -1},
    {0, 1, 1,  1,  2,  4,  8, 14, 22, 32, -1},
    {0, 2, 2,  3,  5,  8, 12, 16, 24, 32, -1},
    {0, 3, 4,  5,  8, 12, 16, 24, 32, -1, -1},
    {0, 4, 6,  8, 12, 16, 24, 32, -1, -1, -1},
    {0, 6, 8, 12, 16, 24, 32, -1, -1, -1, -1},
    {0, 7, 8, 12, 16, 24, 32, -1, -1, -1, -1},
};

const int HuffBases[8][11] =
{
    {0, 1,  2,   4,   12,    44,     172,    2220,   34988, 8423596, -1},
    {0, 1,  2,   3,    5,    13,     141,    2189,   34957, 8423565, -1},
    {0, 1,  2,   3,    4,     6,      14,     142,    8334, 2105486, -1},
    {0, 1,  3,   5,    9,    25,     153,    2201,   34969, 8423577, -1},
    {0, 1,  5,  13,   29,   157,    2205,   34973, 8423581,      -1, -1},
    {0, 1,  9,  41,  169,  2217,   34985, 8423593,      -1,      -1, -1},
    {0, 1, 33, 161, 2209, 34977, 8423585,      -1,      -1,      -1, -1},
    {0, 1, 65, 193, 2241, 35009, 8423617,      -1,      -1,      -1, -1},
};


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Decode Packet Data                                                  *
 *                                                                            *
 * Decode Packet Data from the ISF stream.\n                                  *
 * Check the encoding and decode the datas.\n                                 *
 * Currently known compressions are:                                          *
 * - Adaptive Huffman-based compression                                       *
 * - Gorilla compression                                                      *
 *                                                                            *
 * \param pDecISF      structure used to decode the ISF file.                 *
 * \param packetNumber number of packets to read                              *
 * \param arr          array where we store the decoded integers              *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int decodePacketData(decodeISF_t * pDecISF, INT64 packetNumber, INT64 * arr)
{
    int err = OK; /* the error code */
    unsigned char flags,
                  buffer,
                  offset,
                  sixthbit;

    readByte (pDecISF, &flags);
    LOG(stdout,"Flags=0x%X\n", flags);

    if ((flags & 0xC0) == 0x80)
    {
        /* Adaptive Huffman-based compression */
        LOG(stdout,"Adaptive Huffman-based compression (not fully implemented)\n");
        sixthbit = flags & 0x20;
        LOG(stdout,"6th bit = %.1X \n", sixthbit);
        flags &= 0x1F;
        LOG(stdout,"Index = %X\n", flags);
        offset = 0;
        err = decodeHuffman(
                pDecISF,
                packetNumber,
                (int) flags,
                arr,
                &buffer,
                &offset);
        if (err == OK)
        {
            /* Apply deltaDelta transform */
            err = transformInverseDeltaDelta (packetNumber, arr);
        }

    } else {
        if ((flags & 0xC0) == 0)
        {
            /* Gorilla compression */
            LOG(stdout,"Gorilla compression (not fully implemented)\n");
            sixthbit = flags & 0x20;
            LOG(stdout,"6th bit = %.1X \n", sixthbit);
            flags &= 0x1F;
            LOG(stdout,"Block size = %d\n", flags);
            if (sixthbit)
                LOG(stderr,"/!\\ TODO : need to do the transformation before decoding as gorilla.\n");

            offset = 0;
            err = decodeGorilla(
                    pDecISF,
                    packetNumber,
                    (int) flags,
                    arr,
                    &buffer,
                    &offset);
        } else {
            /* Unknown compression */
            err = UNKNOWN_COMPRESSION;
            LOG(stderr, "Unknown Compression,\n Flags = 0x%X\n", flags);
        }
    }

    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * Decode a list of MBUINT encoded with adaptive Huffman compression          *
 *                                                                            *
 * \param pDecISF      structure used to decode the ISF file.                 *
 * \param packetNumber number of packets to read                              *
 * \param index        index in array BitAmounts, so we know the codec used   *
 * \param arr          array where we store the decoded integers              *
 * \param buffer       pointer to a buffer we store the current Byte read     *
 * \param offset       offset of the current bit to be read in #buffer.       *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int decodeHuffman (
        decodeISF_t * pDecISF,
        INT64 packetNumber,
        int index,
        INT64 * arr,
        unsigned char * buffer,
        unsigned char * offset)
{
    int err = OK, /* the error code */
    n; /* length of huffBases array */
    INT64   i=0, /* current number of packets decoded */
            * huffBases;

    generateHuffBases (index, &n, &huffBases);

    while (err == OK && i < packetNumber)
    {
        err = extractValueHuffman (
                pDecISF,
                index,
                n,
                buffer,
                offset,
                arr+i,
                huffBases);
        i++;
    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Generate the Bases array used in Huffman decompression.             *
 *                                                                            *
 * \param index     index in array BitAmounts, so we know the codec used      *
 * \param n         where we store the length of huffBases array              *
 * \param huffBases array where we store the Bases. We allocate the array     *
 *                  here.                                                     *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int generateHuffBases (int index, int * n, INT64 ** huffBases)
{
    int err = OK, /* the error code */
        i = 1;
    INT64 base = 1;

    /**
     * \b Algorithm:
     * 1. Set the first entry to 0
     * 2. We'll need a temporary variable called base, initialized to the
     *    value 1.
     * 3. For each of the entries from 1 to n, i as the current index and n
     *    being the highest index of BitAmounts, do:
     *  3.1. Set HuffBases[i] to base.
     *  3.2. Calculate 2 to the power of [BitAmounts[i] minus 1], and add it to
     *       base.
     */

    /* HuffBases are maximum 10 integers long, but may change */
    *huffBases = (INT64 *) malloc(10 * sizeof(INT64));
    if (*huffBases)
    {
        (*huffBases)[0] = 0;
        while ( BitAmounts[index][i] != -1)
        {
            (*huffBases)[i] = base;
            base += 1 << (BitAmounts[index][i]-1);
            i++;
        }
        *n = i;
    } else {
        err = OUT_OF_MEMORY;
    }
    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Extract one value from the stream, using Huffman decompression      *
 *                                                                            *
 * \param pDecISF   structure used to decode the ISF file.                    *
 * \param index     index in array BitAmounts, so we know the codec used      *
 * \param n         length of huffBases array                                 *
 * \param buffer    pointer to a buffer we store the current Byte read        *
 * \param offset    offset of the current bit to be read in #buffer.          *
 * \param value     pointer where we store the decoded value                  *
 * \param huffBases array of the Huffman Bases integers                       *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int extractValueHuffman (
        decodeISF_t * pDecISF,
        int index,
        int n,
        unsigned char * buffer,
        unsigned char * offset,
        INT64 * value,
        INT64 * huffBases)
{
    int err = OK, /* the error code */
    setBitsRead = 0;
    unsigned char bit;

    *value = 0;
    /**
     * \b Algorithm:
     * -# Extract bit by bit from the compressed data until you read a 0. For
     *    each 1, increment the counter n.
     * -# If n equals zero, you've decoded the value 0, and you're done.
     * -# If n is less than the length of the codec's BitAmounts array, do:
     * 		-# Read BitAmounts[n] number of bits from the stream into the value
     * 		   offset.\n
     * 		   This is a signed value having the sign-bit as the LSB, just like
     * 		   signed multi-byte integers.
     * 		-# Set value to HuffBases[n] plus offset shifted to the right by one
     * 		   bit (thus not copying the sign-bit).
     * 		-# If offset's sign-bit (bit 1) is set, negate value.
     * 		-# The decoded value is now in value, and we're done.
     * -# If n is equal to the length of the codec's BitAmounts array, it means
     *    we're decoding a 64-bit value, and in this case we repeat the
     *    decompression twice, starting from step 1. The first result becomes
     *    the upper 32 bits, while the second result becomes the lower 32 bits.
     *    The first result has the sign-bit in bit 1, so this is used to negate
     *    the combined value if it's set.
     */
    do
    {
        if (*offset == 0)
        {
            err = readByte(pDecISF, buffer);
            *offset = 8;
        }
        (*offset)--;
        bit = (*buffer >> *offset) & 1;
    } while (err == OK && bit && ++setBitsRead);

    if (err == OK && setBitsRead)
    {
        if (setBitsRead < n)
        {
            err = readNBits (
                    pDecISF,
                    BitAmounts[index][setBitsRead],
                    buffer,
                    offset,
                    value);
            bit = (unsigned char) *value & 1;
            *value = huffBases[setBitsRead] + (*value >> 1);
            if (bit)
                *value = - *value;
        } else {
            LOG(stderr,"/!\\ TODO: bit_reads >= n in extractValueHuffman.\n");
            /* bit_reads >= n */
            /* TODO */
            /* 4. If n is equal to the length of the codec's BitAmounts array,
             *    it means we're decoding a 64-bit value, and in this case we
             *    repeat the decompression twice, starting from step 1.
             *    The first result becomes the upper 32 bits, while the second
             *    result becomes the lower 32 bits. The first result has the
             *    sign-bit in bit 1, so this is used to negate the combined
             *    value if it's set.
             */
        }
    }

    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Transform an array using the DeltaDelta Inverse transform           *
 * This array comes from #decodeHuffman.                                      *
 *                                                                            *
 * \param packetNumber number of packets to manage                            *
 * \param value        array where decoded values are stored                  *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int transformInverseDeltaDelta (INT64 packetNumber, INT64 * value)
{
    INT64 curDelta = 0,
          prevDelta = 0,
          i;

    /**
     * \b Algorithm:
     * For each decoded block of data, the transform state needs to be reset. \n
     * We will need two variables to store the current state, and we will call
     * these CurDelta and PrevDelta.\n
     * Both will be set to zero in a vanilla state.\n\n
     *
     * For each value decoded, hereby called Value, the inverse transform goes
     * like this:
     * -# Calculate NewDelta as CurDelta multiplied by 2, subtract PrevDelta and
     *    add Value.
     * -# Set PrevDelta to CurDelta.
     * -# Set CurDelta to NewDelta.
     * -# The resulting value is now in NewDelta (and CurDelta).
     */
    for (i=0; i<packetNumber; i++)
    {
        *(value+i) += (curDelta << 1) - prevDelta;
        prevDelta = curDelta;
        curDelta = *(value+i);
    }

    return OK;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * Decode a list of MBUINT encoded with Gorilla compression                   *
 *                                                                            *
 * \param pDecISF      structure used to decode the ISF file.                 *
 * \param packetNumber number of packets to read                              *
 * \param blockSize    size of each data block                                *
 * \param arr array    where we store the decoded integers                    *
 * \param buffer       pointer to a buffer we store the current Byte read     *
 * \param offset       offset of the current bit to be read in #buffer.       *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int decodeGorilla (
        decodeISF_t * pDecISF,
        INT64 packetNumber,
        int blockSize,
        INT64 * arr,
        unsigned char * buffer,
        unsigned char * offset)
{
    int err = OK; /* the error code */
    INT64 i=0,
          tmp,
          signMask;
    /**
     * \b Algorithm:
     * -# Read width bits from the stream into value.
     * -# Construct a sign-mask by taking the value 0xFFFFFFFFFFFFFFFF and 
     *    left-shift it by width - 1.
     * -# If value ANDed with the mask is non-zero, OR the value with the mask.
     * What this means is that if the mask matched, the sign bit is set, and by
     * ORing the value with the mask we effectively fill all the bits to the 
     * left of the sign bit with 1s, turning it into a true 64-bit signed integer.
     */

    signMask = 0XFFFFFFFFFFFFFFFF << (blockSize-1);

    while (err == OK && i < packetNumber)
    {
        err = readNBits (pDecISF, blockSize, buffer, offset, &tmp);
        *(arr+i) = (tmp & signMask)?tmp|signMask:tmp;
        i++;
    }
    return err;
}

