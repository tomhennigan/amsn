#include	<stdio.h>

#include	"libISF.h"
#include	"createISF.h"



/*******************************************************************************
 * \brief Encode an INT64 into a MBUINT
 *
 * Given a payload structure WITH ENOUGH FREE SPACE (needs at max 10 bytes),
 * convert an INT64 into a MBUINT and put it in the given payloaf structure.
 *
 * \param i INT64 to turn into MBUINT
 * \param p payload structure where the encoded INT64 is put.
 *
 * \returns nothing
 ******************************************************************************/
void encodeMBUINT ( INT64 i, payload_t * p)
{
    unsigned char tmp = 0,
                  flag = 0;

    /* we don't check the size here as it MUST be good */

    do
    {
        tmp = i & 0x7F;
        i >>= 7;
        flag = (i == 0) ? 0 : 0x80;
        p->data[p->cur_length++] = tmp | flag;
    }
    while (flag);
}



/*******************************************************************************
 * \brief Put a Float in a payload structure
 *
 * Given a payload structure WITH ENOUGH FREE SPACE (needs 4 bytes),
 * put a float into that structure.
 *
 * \param f the float
 * \param p payload structure where the float is put.
 *
 * \returns nothing
 ******************************************************************************/
void putFloat (float f, payload_t * p)
{
    union {
        float f;
        unsigned char b[4];
    } f1; /* union where we code the float */

    f1.f = f;

    /* we don't check the size here as it must be good */

#ifdef BIG_ENDIAN
    p->data[p->cur_length++] = f1.b[3];
    p->data[p->cur_length++] = f1.b[2];
    p->data[p->cur_length++] = f1.b[1];
    p->data[p->cur_length++] = f1.b[0];
#else
    p->data[p->cur_length++] = f1.b[0];
    p->data[p->cur_length++] = f1.b[1];
    p->data[p->cur_length++] = f1.b[2];
    p->data[p->cur_length++] = f1.b[3];
#endif
}

