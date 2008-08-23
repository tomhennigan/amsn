/**
 * \file include/aio/aio_plugin.h
 * \brief Plugin Application interface for libaio
 * \author Mohamed Abderaouf Bencheraiet <kenshin@cerberus.endoftheinternet.org>
 * \date 2008
 *
 * Plugin Application interface libaio
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
#ifndef AIO_PLUGIN_H
#define AIO_PLUGIN_H
/** \defgroup plugin_api Plugin API 
 * \{
 *	libaio plugin referece each lugin must implement all of these functions. 
 *	which the code library is juste a wrapes (see \ref LIBAIO_API "api ref" for functions descriptions) :
 *	<UL>
 *	<LI>static aio_info_t * driver_info(void);
 *	<LI>static int control(aio_device_t *device,int cmd, void *arg);
 *	<LI>static int init(aio_device_t * device,aio_sample_format_t *sample_format, aio_option_t **ptions, int flags);
 *	<LI>static int uninit(aio_device_t *device, int immed);
 *	<LI>static int reset(aio_device_t *device);
 *	<LI>static int get_space(aio_device_t *device,int dir);
 *	<LI>static int play(aio_device_t *device,int8_t* data,size_t len,int last_chunck);
 *	<LI>static float get_delay(aio_device_t *device);
 *	<LI>static int audio_pause(aio_device_t *device);
 *	<LI>static int audio_resume(aio_device_t *device);
 *	<LI>static int record(aio_device_t *device, int8_t *buffer,size_t len, int flags);
 *	</UL>
 **/

static aio_info_t * driver_info(void);
static int control(aio_device_t *device,int cmd, void *arg);
static int init(aio_device_t * device,aio_sample_format_t *sample_format, aio_option_t **ptions, int flags);
static int uninit(aio_device_t *device, int immed);
static int reset(aio_device_t *device);
static int get_space(aio_device_t *device,int dir);
static int play(aio_device_t *device,int8_t* data,size_t len,int last_chunck);
static float get_delay(aio_device_t *device);
static int audio_pause(aio_device_t *device);
static int audio_resume(aio_device_t *device);
static int record(aio_device_t *device, int8_t *buffer,size_t len, int flags);


/** defines a #aio_functions_t structure as \c audio_driver to be exported in a dynamic driver (.so)*/
#define LIBAIO_EXTERN_DYNAMIC() aio_functions_t audio_driver =\
{\
	driver_info,\
	control,\
	init,\
        uninit,\
	reset,\
	get_space,\
	play,\
	record,\
	get_delay,\
	audio_pause,\
	audio_resume\
};
/**defines an #aio_functions_t structure by the name audio_x (where x is the plugin name) to be exported as a static driver */
#define LIBAIO_EXTERN_STATIC(x) aio_functions_t audio_##x =\
{\
	driver_info,\
	control,\
	init,\
        uninit,\
	reset,\
	get_space,\
	play,\
	record,\
	get_delay,\
	audio_pause,\
	audio_resume\
};

/**\}*/
#endif /* AIO_INTERNAL_H */
