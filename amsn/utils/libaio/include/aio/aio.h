/**
 * \file include/aio/aio.h
 * \brief Application interface for libaio
 * \author Mohamed Abderaouf Bencheraiet <kenshin@cerberus.endoftheinternet.org>
 * \date 2008
 *
 * Application interface libaio
 */
/*
 *   This library is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as
 *   published by the Free Software Foundation; either version 2.1 of
 *   the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 */
#ifndef AIO_H
#define AIO_H

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <sys/types.h> 
#include "af_format.h"

/**
 *\defgroup LIBAIO_API Libaio API
 *\{
 *Libaio Api reference 
 */
/**
 * \defgroup Log Log management
 * Log messages to the consol using #aio_msg()\n  
 * using these levels \n
 * AIO_DEBUG for debug messages\n
 * AIO_WAN  for warning\n
 * AIO_ERROR for error\n
 *\n
 * the behavio of #aio_msg() is dictacted by the global variable #aio_verbosity if set to :
 *
 * AIO_VERBOSITY_DEBUG all the messages are printed\n
 * AIO_VERBOSITY_WARN erro messages and warning are printed \n
 * AIO_VERBOSITY_ERROR only error messages are printer \n
 * AIO_VERBOSITY_NON no messages\n
 * \{*/

#define AIO_MSGSIZE_MAX		2048 
/**< Maximum log message size*/

#define AIO_DEBUG		(1<<0) /*00000001*/
/**< Debug log facility */
#define AIO_WARN 		(1<<1) /*00000010*/
/**< Warning log facility*/
#define AIO_ERROR 		(1<<2) /*00000100*/
/**< Error log facility*/
#define AIO_VERBOSITY_DEBUG 	(AIO_DEBUG|AIO_WARN|AIO_ERROR)	/*00000111*/ 
/**< debug verbobosity level : all the messages will be displayed*/
#define AIO_VERBOSITY_WARN 	(AIO_WARN|AIO_ERROR) 		/*00000110*/
/**< warnin verbobosity level : only warning and error messages will be displayed*/
#define AIO_VERBOSITY_ERROR 	(AIO_ERROR) 			/*00000100*/
/**< error verbobosity level only : error messages will be displayed*/
#define AIO_VERBOSITY_NONE	(0)				/*00000000*/
/**< non verbobosity level only : no messages will be displayed*/

/** \} */


#define AIO_SPACE_IN 		0 /**<instructs #aio_getspace() to get available input space */
#define AIO_SPACE_OUT 		1 /**<instructs #aio_getspace() to get available output space*/


#define AIO_IMMED_NOW 		1/**< instructs #aio_close()/#aio_reset() to close immediatly (drop thhe frames in buffer)*/
#define AIO_IMMED_LATER 	0/**< instructs #aio_close()/#aio_reset() to wait for the playback to finish and the close */


#define AIO_FMT_LITTLE 		1 /**< endianness to see the prefered format of the driver the user can check and swap the buffer if necessary*/
#define AIO_FMT_BIG    		2 /**< endianness to see the prefered format of the driver the user can check and swap the buffer if necessary*/

#define AIO_FMT_NATIVE 		4 /**< endianness to see the prefered format of the driver the user can check and swap the buffer if necessary*/



/** see #aio_functions_s*/

typedef struct aio_functions_s aio_functions_t;

/** Options information structure */

typedef struct aio_option_info_s {
	/** Options name */
	char *option;
	/** Option description*/
	char *description ;

} aio_option_info_t; 
/**< see#aio_option_info_s*/

/** Driver info structure */
typedef struct aio_info_s
{
	/** driver  full name (eg. ALSA output Driver ) */
        const char *name;
        /** short name (for config strings) ("alsa") */
        const char *short_name;
        /** author ("somebody <sombody@somehwere.com>") */
        const char *author;
        /** any additional comments */
        const char *comment;
	/** prefered endienness #AIO_FMT_LITTLE #AIO_FMT_BIG #AIO_FMT_NATIVE*/
	int prefered_byte_format;
	/** priority */
	const int priority;

	/** Driver's options information (#aio_option_info_t)*/
	aio_option_info_t *option;
	/** Number of options the driver have*/
	int option_count;
} aio_info_t;
/**< see #aio_info_s*/
/** The device structure  that abstracts the hardware/libraries specifics. it is through this strcture that all I/O is done*/
typedef struct aio_device_s {
	/** device driver id*/
	int driver_id;
	/** pointer to functions to use the device (play/record ...etc)*/
	aio_functions_t *funcs;
	/** a file structure to holde an eventual output/input file (not implemnted yet)*/
	FILE *file; 
	/** the client byte order #AIO_FMT_LITTLE, #AIO_FMT_BIG, #AIO_FMT_NATIVE */
	int client_byte_format;
	/** the host byte order #AIO_FMT_LITTLE, #AIO_FMT_BIG, #AIO_FMT_NATIVE */
	int machine_byte_format;
	/** the driver's byte order #AIO_FMT_LITTLE, #AIO_FMT_BIG, #AIO_FMT_NATIVE */
	int driver_byte_format;
	/** Bytes allocated to swap_buffer */
	int8_t *swap_buffer; 
	/** the swap buffer size (for now no swap operations)*/
	int swap_buffer_size;
	/** Pointer to driver-specific data */
	void *internal; 
} aio_device_t;
/**< see #aio_device_s*/

/** Structure holding sample format specific informations and data */
typedef struct aio_sample_format_s
{
	/** endianess of the samples see #aio_device_s.client_byte_format,  #AIO_FMT_LITTLE, #AIO_FMT_BIG, #AIO_FMT_NATIVE **/
	int byte_format; 	
	/** sample format  8 16  S/U .....*/ 
	int format; 	
	/** number of channels */ 
	int channels; 
	/** sample rate */
	int samplerate;
	/**bits per sample*/	
	int bits;	
	/**bytes per sec*/
	int bps; 
	/**sample size */
	int bytes_per_sample;

} aio_sample_format_t;
/**< see #aio_sample_format_s*/

/** Option structure : holds a key value paire */
typedef struct aio_option_s {
	/** name or key unique to the option ("rec_src"*/
        char *key;
	/** the value ("Mic") */
	char *value;
} aio_option_t;
/**< see #aio_option_s*/


/** Functions structur : plugins interface with the core of libaio every plugin/driver must implement these*/
struct aio_functions_s
{	
	/** pointer to plugin driver_info function see #aio_getinfo()*/
	aio_info_t *(* driver_info)(void);
	/** pointer to plugin the control function see #aio_control() (every plugin offer et set of controls)*/
	int (*control)(aio_device_t *device,int cmd,void *arg);
	/** pointer to the plugin init function see #aio_open()*/
        int (*init)(aio_device_t *device, aio_sample_format_t *sample_format,aio_option_t **options,int flags);
	/** pointer the plugin uninit function see #aio_close()*/
        int (*uninit)(aio_device_t *device,int immed);
	/** pointer to the plugin reset function see #aio_reset()*/
        int (*reset)(aio_device_t *device);
	/** pointer to the plugin get_space function see #aio_getspace()*/
        int (*get_space)(aio_device_t *device,int dir);
	/** pointer to the plugin play function see aio_play*/
        int (*play)(aio_device_t *device,int8_t* data,size_t len,int flags);
	/** pointer to the plugin record function see #aio_record() */
        int (*record)(aio_device_t *device, int8_t *data, size_t len, int flags);
	/** pointer to the plugin get_delay function see #aio_getdelay() */
	float (*get_delay)(aio_device_t *device);
	/** pointer to the plugin pause function see #aio_pause*/
        int (*pause)(aio_device_t *device);
	/** pointer to the plugin  resume function see #aio_pause()*/
        int (*resume)(aio_device_t *device);
	
}; 

/* API funcs */
void aio_initialize(void);
int aio_default_driver_id(char **prefered_list);
aio_device_t *aio_open(int driver_id,
		       aio_sample_format_t *sample_format,
		       aio_option_t **options, int open_mode);
int aio_play(aio_device_t *device, int8_t * output_samples,
	     size_t num_bytes, int flags);
int aio_close(aio_device_t *devicei, int immed);
void aio_shutdown();
int aio_getspace(aio_device_t *device, int dir);
float aio_getdelay(aio_device_t *device);
int aio_pause(aio_device_t *device); 
int aio_resume(aio_device_t *device);
int aio_reset(aio_device_t * device, int immed);
/**
 * \addtogroup Control 
 * \{
 */

int aio_control(aio_device_t *device, int cmd, void *arg);
/**\}*/
int aio_record(aio_device_t *device, int8_t * buffer, size_t count, int flags);
aio_info_t * aio_getinfo(aio_device_t *device);
/* miscellaneous */
int aio_is_big_endian(void);



int aio_driver_id(char *short_name);
/*! \addtogroup Log 
   *  Additional documentation for group `Log'
   * \{
   */
int aio_msg(int level,char *fmt, ...);
/** \} */




/**
 * \defgroup Control Control interface 
 * control the device behavior
 *\{
 * the volume is set get in a #aio_control_vol_t * structure
 * get set device is done with a string 
 * query format ois done with a format macro defined in include/aio/af_format.h 
 */
/** To indicate that a control has succeded*/
#define CONTROL_OK 1
/** To indicate that a control is supported and possible*/
#define CONTROL_TRUE 1
/** To indicate that a control is supported but impossible*/
#define CONTROL_FALSE 0
/** To indicate that an unknown control ahse beed attemped on adevice*/
#define CONTROL_UNKNOWN -1
/** To indicate that a control error has occured*/
#define CONTROL_ERROR -2
/** To indicate that the control is not availlable*/
#define CONTROL_NA -3
/** Request a device change */
#define AIOCONTROL_SET_DEVICE 1
/** Request the hardware device/card used */
#define AIOCONTROL_GET_DEVICE 2
/** Test for availabilty of a format */
#define AIOCONTROL_QUERY_FORMAT 3
/** Resquest the playback volume*/
#define AIOCONTROL_GET_PLAYBACK_VOLUME 4
/** Resquest the playback volume*/
#define AIOCONTROL_SET_PLAYBACK_VOLUME 5
/** Resquest the capture volume*/

#define AIOCONTROL_GET_RECORD_VOLUME 6
/** Resquest the capture volume set in */

#define AIOCONTROL_SET_RECORD_VOLUME 7
/** Request to change the openeing mode (playback / capture /both)*/
#define AIOCONTROL_SET_MODE 8 


/** Volume struture : hold the volume (range 0-100) used with aio_control*/
typedef struct aio_control_vol_s {
	/** left/mono channel left */
	float left;
	/**  right channel volume */
	float right;
} aio_control_vol_t;
/**< see aio_control_vol_s*/

/*\}*/
/*instruct the play function that this is th final chunk we're playing
 * (for oss mainly)*
 */

/** instructs the driver that it is the final chuck so no round up ar done (OSS only alsa does not take it into account)*/
#define AIOPLAY_FINAL_CHUNK 1


/** Open the devie in Playback mode*/
#define AIO_PLAYONLY	(1>>0) /*00000001*/
/** Open the device in record mode */
#define AIO_RECONLY 	(1<<1) /*00000010*/
/** Open the device for playback and capture simultaniously*/
#define AIO_RECPLAY 	(AIO_PLAYONLY|AIO_RECONLY ) /*00000011*/



/* --------------Internal Structures------------*/
/** 
 * --- Driver Table structure --- *
 **/
/** \cond dummy */
typedef struct driver_list {
	aio_functions_t *functions;
	void *handle;
	struct driver_list *next;
} driver_list;
/** \endcond */
/*-------------------------------*/
/**\}*/
#endif /* AIO_H */ 
