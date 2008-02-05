#include	<stdio.h>

#include	"libISF.h"
#include	"DecodeISF.h"
#include	"misc.h"

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read a Multi Bytes Unsigned Integer                                 *
 *                                                                            *
 * A MBUINT can be at max 64 bits long. \n                                    *
 * Since we don't know how large this MBUINT can be,                          *
 * we put it in a 64 bits long structure.\n                                   *
 * The number of bytes read is increased by #getUChar.                        *
 *                                                                            *
 * \param pDecISF structure used to call #getUChar.                           *
 * \param mbuint  pointer where we store the decoded MBUINT                   *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int readMBUINT (decodeISF_t * pDecISF, INT64 * mbuint)
{
    int err = OK; /* the error code */
    unsigned char buffer; /* buffer where we store the current byte to proceed*/
    unsigned char flag; /* flag used to know whether the value is decoded */
    int bitcounter = 0; /* number of bits read so far */

    *mbuint=0;
    /**
     * \b Algorithm:
     * -# Set #mbuint to 0. This will be used to build the decoded value.
     * -# Set #bitcounter to 0. This will be incremented by 7 for each byte
     *    read.
     * -# Read one byte from the stream with #getUChar into #buffer.
     * -# Set the flag as the most significant bit of #buffer.
     * -# AND #buffer by 0x7F to get the 7 right-most bits, and left-shift it by
     *    the number of bits read so far : #bitcounter. Finally, OR #mbuint with
     *    this.
     * -# Increment the bit-counter by 7.
     * -# If the flag is set, we're done. Elsewise, we need to read one more
     *    byte at least : go to step 3.
     */
    do
    {
        err = (*(pDecISF->getUChar))(
                pDecISF->streamInfo,
                &pDecISF->bytesRead,
                &buffer);
        if(err == OK)
        {
            flag = buffer & 0X80;
            *mbuint |= (buffer & 0X7F) << bitcounter;
            bitcounter +=7;
        }
    }
    while (err == OK && flag);

    return err;
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read a Multi Bytes Signed Integer                                   *
 *                                                                            *
 * A MBSINT can be at max 64 bits long. \n                                    *
 * Since we don't know how large this MBSINT can be,                          *
 * we put it in a 64 bits long structure.\n                                   *
 * The number of bytes read is increased by #getUChar.                        *
 *                                                                            *
 * \param pDecISF structure used to call #getUChar.                           *
 * \param mbsint  pointer where we store the decoded MBSINT                   *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int readMBSINT (decodeISF_t * pDecISF, INT64 * mbsint)
{
    int err = OK; /* the error code */
    unsigned char sign_flag; /* flag used to know whether the mbuint is >=0 */

    /**
     * \b Algorithm:
     * -# Read a MBUINT64 from the stream.
     * -# Set the sign flag to the least significant bit by doing a binary AND
     *    between the value read and '1'.
     * -# Shift right from 1 bit the value.
     * -# If the sign flag is set to 1, then multiply the value with -1.
     */
    err = readMBUINT (pDecISF, mbsint);

    sign_flag = *mbsint & 1;
    *mbsint = *mbsint >> 1;
    if (sign_flag)
        *mbsint = - *mbsint;

    return err;
}




/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read a Float                                                        *
 *                                                                            *
 * Read a float from the stream.\n                                            *
 * The float is coded in the stream as little endian.\n                       *
 * The number of bytes read is increased (by 4) by #getUChar.                 *
 *                                                                            *
 * \param pDecISF structure used to call #getUChar.                           *
 * \param f       pointer where we store the decoded Float                    *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int readFloat (decodeISF_t * pDecISF, float * f)
{
    int err = OK, /* the error code */
        i; /* loop index */
    union {
        float f;
        unsigned char b[4];
    } f1; /* union where we decode the float */

    /** the float is coded in the stream as little endian. */
#ifdef BIG_ENDIAN
    i = 3;
    do
    {
        err = (*(pDecISF->getUChar))(
                pDecISF->streamInfo,
                &pDecISF->bytesRead,
                &(f1.b[i]));
        i--;
    }
    while (err == OK && i>=0);
    *f = f1.f;
#else
    i = 0;
    do
    {
        err = (*(pDecISF->getUChar))(
                pDecISF->streamInfo,
                &pDecISF->bytesRead,
                &(f1.b[i]));
        i++;
    }
    while (err == OK && i<=3);
    *f = f1.f;
#endif
    return err;
}




/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read a Byte                                                         *
 *                                                                            *
 * Read a byte from the ISF file and put it in an unsigned char. \n           *
 * The number of bytes read is increased (by 1) by #getUChar.                 *
 *                                                                            *
 * \param pDecISF structure used to call #getUChar.                           *
 * \param c       pointer we store the decoded Byte.                          *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int readByte(decodeISF_t * pDecISF, unsigned char * c)
{
    return (*(pDecISF->getUChar))(pDecISF->streamInfo,&pDecISF->bytesRead,c);
}




/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read N bits                                                         *
 *                                                                            *
 * Read N bits from the ISF stream and put it in a 64 bits long structure     *
 * (we assume "INT64" is). \n                                                 *
 * If N > 64, we use N = N mod 64. That may cause issues.\n                   *
 * The number of bytes read is increased by #getUChar.                        *
 *                                                                            *
 * \param pDecISF structure used to call #getUChar                            *
 * \param n       number of bits to read                                      *
 * \param buffer  buffer where we store the current Byte read                 *
 * \param offset  offset of the current bit to be read in #buffer             *
 * \param value   pointer where we store the decoded value                    *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int readNBits (
        decodeISF_t * pDecISF,
        int n,
        unsigned char * buffer,
        unsigned char * offset,
        INT64 * value)
{
    int err = OK, /* the error code */
    i; /* loop index */

    *value = 0;

    /* just to be sure */
    n %= 64;

    /* Read bit by bit */
    for (i=0; i<n; i++)
    {
        if (*offset == 0)
        {
            /* we need to get an other byte from the stream */
            err = readByte(pDecISF, buffer);
            *offset = 8;
        }
        (*offset)--;
        /* get the bit, and add it to value */
        *value = (*value << 1) | ((*buffer >> *offset) & 1);
    }
    return err;
}
