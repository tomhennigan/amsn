/**
 * \file src/aio_null.c
 * \brief NULL plugin 
 * \author Mohamed Abderaouf Bencheraiet <kenshin@cerberus.endoftheinternet.org>
 * \date 2008
 *
 * OSS plugin 
 *
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

/**
 *\defgroup null NULL plugin
 *\{
 * This plugin does nothing 
 * \}*/

#include "aio/aio.h"
#include "aio/aio_plugin.h"



static aio_info_t info = 
{
	"Null/Dummy out plugin",
	"null",
	"",
	"",
	AIO_FMT_NATIVE,
	0,
	NULL,
	0
};

static aio_info_t * driver_info(void) {

	return &info;
}

static int control(aio_device_t *device,int cmd, void *arg) {

	return CONTROL_NA;
}

static int init(aio_device_t * device,aio_sample_format_t *sample_format, aio_option_t **ptions, int flags){
	return 0;
}
static int uninit(aio_device_t *device, int immed){
	return 0;
}

static int reset(aio_device_t *device){
	return 0;
}
static int get_space(aio_device_t *device,int dir){

	return 0;
}
static int play(aio_device_t *device,int8_t* data,size_t len,int last_chunck){

	return 0;
}
static float get_delay(aio_device_t *device){
	
	return 0;

}
static int audio_pause(aio_device_t *device) {

	return 0;
}
static int audio_resume(aio_device_t *device){
	return 0;
}
static int record(aio_device_t *device, int8_t *buffer,size_t len, int flags){

	return 0;
}




LIBAIO_EXTERN_STATIC(null);
