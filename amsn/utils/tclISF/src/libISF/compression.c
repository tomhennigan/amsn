#include	<stdlib.h>
#include	<stdio.h>
#include	<string.h>

#include	"libISF.h"
#include	"createISF.h"
#include	"misc.h"


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Create Packet Data                                                  *
 *                                                                            *
 * Create a payload structure containing data encoded as Packet Data.         *
 * It's mainly use for strokes coordinates.                                   *
 *                                                                            *
 * \param lastPayload_ptr pointer on the last element where we should put     *
 *                        that data                                           *
 * \param nPoints         number of points the data has                       *
 * \param arr             array of points we're going to encode               *
 * \param payloadSize     integer we're going to increase by the size of the  *
 *                        payload of this packet data                         *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int createPacketData(
        payload_t ** lastPayload_ptr,
        INT64 nPoints,
        INT64 * arr,
        INT64 * payloadSize)
{
    int err = OK;
    int blockSize;
    INT64 allocatedSize = 0;

    /*TODO: /!\ We only use gorilla compression for the moment */

    blockSize = getBlockSize(nPoints, arr);
    LOG(stdout,"BLOCK_SIZE = %d\n", blockSize);

    /* 1 : one bytes specifying the encoding used ( and block size for Gorilla)
     * + number of bytes (blocksize is in bits) needed to put all the points
     */
    allocatedSize = 1 + ((nPoints*blockSize+7) >> 3);


    err = createPayload(&((*lastPayload_ptr)->next), allocatedSize, NULL);
    if (err != OK) return err;

    *lastPayload_ptr = (*lastPayload_ptr)->next;


    /* create the flags */
    if (blockSize > 31)
        /*TODO*/
        blockSize = 31;

    (*lastPayload_ptr)->data[(*lastPayload_ptr)->cur_length] = blockSize | GORILLA;
    (*lastPayload_ptr)->cur_length++;

    encodeGorilla ((*lastPayload_ptr)->data+1, arr, nPoints, blockSize);
    /* that payload structure is filled up */
    (*lastPayload_ptr)->cur_length = allocatedSize;
    
    /* increase the global payload size */
    *payloadSize += (*lastPayload_ptr)->cur_length;

    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * Get the best block size ( as in the Gorilla algorithm) for the specified   *
 * array                                                                      *
 *                                                                            *
 * \param points_nb size of the array                                         *
 * \param arr       array we're going to search                               *
 *                                                                            *
 * \returns the best block size found                                         *
 ** ------------------------------------------------------------------------ **/
int getBlockSize( int points_nb, INT64 * arr)
{
    int blockSize = 0;
    INT64 tmp,
          num,
          i;

    for (i = 0; i< points_nb; i++)
    {
        num = arr[i];
        /* use only positive values */
        if (num < 0) num = -num-1;
        tmp = num >> blockSize;
        while (tmp)
        {
            blockSize++;
            tmp >>= 1;
        }
    }

    /* for the sign bit */
    blockSize++;

    return blockSize;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Encode using the Gorilla algorithm an array of integers             *
 *                                                                            *
 * Encode an array of integers using the Gorilla algorithm. The best block    *
 * size has already been found, and an already allocated array where to put   *
 * the encoded values is provided to the function.                            *
 * That's why no error code is returned since there is no allocation here.    *
 *                                                                            *
 * \param uchar_arr    array where the encoded data is put                    *
 * \param int_arr      array describing the integers to encode                *
 * \param packetNumber size of the integer array = number of integers to      *
 *                     encode                                                 *
 * \param blockSize    size in bits of a block where every integer for        *
 *                     #int_arr fits in                                       *
 *                                                                            *
 * \returns nothing                                                           *
 ** ------------------------------------------------------------------------ **/
void encodeGorilla (
        unsigned char * uchar_arr,
        INT64 * int_arr,
        int packetNumber,
        int blockSize)
{
    int i,
        blockSizeTmp,/* size in bits of what remains to be encoded ofthe current int */
        mask,signMask,
        bitsFree = 8;/* number of free bits (LSB) in the current byte */
    INT64 iTmp;/* current integer being encoded */

    *uchar_arr = 0;
    signMask = 1 << (blockSize-1);

    for (i = 0; i < packetNumber; i++)
    {
        iTmp = int_arr[i];
        /* apply the sign mask to encode it the right way */
        if(iTmp<0)
            iTmp |= signMask;
        
        blockSizeTmp = blockSize;

        if ( bitsFree  >= blockSize)
        {
            /* that int fits in the current char */
            bitsFree -= blockSizeTmp;
            *uchar_arr |= (iTmp << bitsFree);
            if (bitsFree == 0)
            {
                uchar_arr++;
                bitsFree = 8;
            }
        } else {
            /* fill the current byte */
            mask = 0xFFFFFFFF >> (32 - blockSizeTmp);
            *uchar_arr |= iTmp >> (blockSizeTmp - bitsFree);
            uchar_arr++;
            blockSizeTmp -= bitsFree;
            mask >>= bitsFree;
            iTmp &= mask;
            
            /* fill all the bytes we can */
            while (blockSizeTmp > 8)
            {
                blockSizeTmp -= 8;
                *uchar_arr = iTmp >> blockSizeTmp;
                mask >>= 8;
                iTmp &= mask;
                uchar_arr++;
            }
            /* new byte, put the last part of the int as MSB */
            bitsFree = 8 - blockSizeTmp;
            *uchar_arr = iTmp << bitsFree;
        }
    }
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * Apply the DeltaDelta transformation                                        *
 *                                                                            *
 * \param inArr        array of integers to apply the transformation          *
 * \param outArr       array where the result of the transformation is put    *
 * \param packetNumber size of the integer array = number of integers to      *
 *                     encode                                                 *
 *                                                                            *
 * \returns nothing                                                           *
 ** ------------------------------------------------------------------------ **/
void transformDeltaDelta (int * inArr, int * outArr, int packetNumber)
{
	int curDelta = 0,
        prevDelta = 0,
        i, tmp;

	for (i=0; i<packetNumber; i++)
	{
		outArr[i] = inArr[i] + prevDelta - (curDelta << 1);
		prevDelta = curDelta;
		curDelta = inArr[i];
	}
}


