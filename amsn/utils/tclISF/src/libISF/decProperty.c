#include	<stdlib.h>
#include	<stdio.h>

#include	"libISF.h"
#include	"DecodeISF.h"
#include	"misc.h"

/*******************************************************************************
 * \brief Get Property data associated with a GUID
 *
 * \param pDecISF structure used to decode the ISF file.
 * \param guidId  number of the GUID to proceed
 *
 * \returns the error code given while processing
 ******************************************************************************/
int getProperty (decodeISF_t * pDecISF, INT64 guidId)
{
    int err = OK; /* the error code */
    INT64 endPayload,
          value;
    unsigned char flags,
                  c;

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value)
    {
        LOG(stdout,"(GUID_%lld) payload size = %ld\n", guidId, (long) value);
        endPayload = pDecISF->bytesRead + (long) value + 1;
        /* The "+1" is needed here, weird */

        err = readByte (pDecISF, &flags);
        LOG(stdout,"(GUID_%lld) Flags = %#X\n", guidId, flags);

        do
        {
            err = readByte (pDecISF, &c);
            LOG(stdout," %#X", c);
        } while (err == OK && pDecISF->bytesRead < endPayload);
        LOG(stdout,"\n");
    }
    return err;
}
