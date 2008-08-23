/**
 * \file src/plugins/oss/aio_oss.c
 * \brief OSS plugin 
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
 *\defgroup oss OSS plugin
 *\{
 *
 * Open Sound System driver for Linux and various Unix-lie systems.
 * This driver borrows some code from the Mplayer libao2 <http://mplayer.hq>, 
 * XIPHE libao <http://xiphe.org> and aplay wich is included with the alsa-util distibution
 * Option keys : 
 * <UL>
 *
 * <LI>dsp -> Path to the dsp device to use (default /dev/dsp)
 * <LI>rec_src -> mic or line (if the device is in record mode)
 *
 * </UL>
 * \}*/
#include <stdio.h>
#include <stdlib.h>

#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#include "config.h"

#ifdef HAVE_SYS_SOUNDCARD_H
#include <sys/soundcard.h>
#else
#ifdef HAVE_SOUNDCARD_H
#include <soundcard.h>

#endif
#endif

#include "af_format.h"
#include "aio/aio.h"
#include "aio/aio_plugin.h"

static aio_option_info_t aio_oss_options[] = {
  {"dsp", "Path to the dsp device to use."},
  {"rec_src","mic or line (if the device is in record mode)"},
   {} };
aio_info_t info = 
{
	"OSS/ioctl audio output",
	"oss",
	"",
	"",
	AIO_FMT_NATIVE,
	20,
	aio_oss_options,
	1
};
typedef struct aio_oss_internal_s {
	char *dsp; /*the device path*/
	aio_sample_format_t s_format; /* sample format we're using*/
	int frag_size; /*audio fragment  size*/
	audio_buf_info a_buf_info;
	int audio_fd;
	int prepause_space;
	int oss_playback_mixer_channel;
	int oss_rec_mixer_channel;
	size_t buffersize;
	int open_mode;

} aio_oss_internal_t;

static int _open_default_oss_device(char ** dsp_path ,int blocking);


static int _open_default_oss_device (char ** dsp_path, int open_mode){
	int fd;
	/* default: first try the devfs path */
	*dsp_path = strdup("/dev/sound/dsp");
#ifdef BROKEN_OSS 
/*apprently a bug in alsa oss emulation
as follow : 
The OSS emulation in ALSA deviates from the OSS spec by not returning 
immediately from an open() call if the OSS device is already in use. 
Instead, it makes the application wait until the device is available. 
This is not desirable during the autodetection phase of libao, so a 
workaround has been included in the source.  Since the workaround 
itself violates the OSS spec and causes other problems on some 
platforms, it is only enabled when ALSA is detected.  The workaround 
can be turned on or off by passing the --enable-broken-oss or 
--disable-broken-oss flag to the configure script. */
	fd = open(*dsp_path, open_mode | O_NONBLOCK);
#else
	fd = open(*dsp_path, open_mode);
#endif /* BROKEN_OSS */
	
	if(fd < 0){
		/* no? then try the traditional path */
		free(*dsp_path);
		*dsp_path = strdup("/dev/dsp");
#ifdef BROKEN_OSS_tt
		fd = open(*dsp_path, open_mode | O_NONBLOCK);
#else
		fd = open(*dsp_path, open_mode);
#endif /* BROKEN_OSS */
	}
#ifdef BROKEN_OSS_tt
	/* Now have to remove the O_NONBLOCK . */
	if (fd >= 0 ) {
		if (fcntl(fd, F_SETFL, 0) < 0) { 
			/* Remove O_NONBLOCK 
			If we can't go to blocking mode, we can't use
			this device */
		  	close(fd);
			fd = -1;
		}
	}
#endif /* BROKEN_OSS */
	
	/* Deal with error cases */
	if(fd < 0){
		free(*dsp_path);
		*dsp_path = NULL;
	}

	return fd;
}

/* Support for >2 output channels added 2001-11-25 - Steve Davies <steve@daviesfam.org> */
static int format2oss(int format)
{
    switch(format)
    {
    case AF_FORMAT_U8: return AFMT_U8;
    case AF_FORMAT_S8: return AFMT_S8;
    case AF_FORMAT_U16_LE: return AFMT_U16_LE;
    case AF_FORMAT_U16_BE: return AFMT_U16_BE;
    case AF_FORMAT_S16_LE: return AFMT_S16_LE;
    case AF_FORMAT_S16_BE: return AFMT_S16_BE;
#ifdef AFMT_U24_LE
    case AF_FORMAT_U24_LE: return AFMT_U24_LE;
#endif
#ifdef AFMT_U24_BE
    case AF_FORMAT_U24_BE: return AFMT_U24_BE;
#endif
#ifdef AFMT_S24_LE
    case AF_FORMAT_S24_LE: return AFMT_S24_LE;
#endif
#ifdef AFMT_S24_BE
    case AF_FORMAT_S24_BE: return AFMT_S24_BE;
#endif
#ifdef AFMT_U32_LE
    case AF_FORMAT_U32_LE: return AFMT_U32_LE;
#endif
#ifdef AFMT_U32_BE
    case AF_FORMAT_U32_BE: return AFMT_U32_BE;
#endif
#ifdef AFMT_S32_LE
    case AF_FORMAT_S32_LE: return AFMT_S32_LE;
#endif
#ifdef AFMT_S32_BE
    case AF_FORMAT_S32_BE: return AFMT_S32_BE;
#endif
#ifdef AFMT_FLOAT
    case AF_FORMAT_FLOAT_NE: return AFMT_FLOAT;
#endif
    // SPECIALS
    case AF_FORMAT_MU_LAW: return AFMT_MU_LAW;
    case AF_FORMAT_A_LAW: return AFMT_A_LAW;
    case AF_FORMAT_IMA_ADPCM: return AFMT_IMA_ADPCM;
#ifdef AFMT_MPEG
    case AF_FORMAT_MPEG2: return AFMT_MPEG;
#endif
#ifdef AFMT_AC3
    case AF_FORMAT_AC3: return AFMT_AC3;
#endif
    }
    return -1;
}
/*
static int oss2format(int format)
{
    switch(format)
    {
    case AFMT_U8: return AF_FORMAT_U8;
    case AFMT_S8: return AF_FORMAT_S8;
    case AFMT_U16_LE: return AF_FORMAT_U16_LE;
    case AFMT_U16_BE: return AF_FORMAT_U16_BE;
    case AFMT_S16_LE: return AF_FORMAT_S16_LE;
    case AFMT_S16_BE: return AF_FORMAT_S16_BE;
#ifdef AFMT_U24_LE
    case AFMT_U24_LE: return AF_FORMAT_U24_LE;
#endif
#ifdef AFMT_U24_BE
    case AFMT_U24_BE: return AF_FORMAT_U24_BE;
#endif
#ifdef AFMT_S24_LE
    case AFMT_S24_LE: return AF_FORMAT_S24_LE;
#endif
#ifdef AFMT_S24_BE
    case AFMT_S24_BE: return AF_FORMAT_S24_BE;
#endif
#ifdef AFMT_U32_LE
    case AFMT_U32_LE: return AF_FORMAT_U32_LE;
#endif
#ifdef AFMT_U32_BE
    case AFMT_U32_BE: return AF_FORMAT_U32_BE;
#endif
#ifdef AFMT_S32_LE
    case AFMT_S32_LE: return AF_FORMAT_S32_LE;
#endif
#ifdef AFMT_S32_BE
    case AFMT_S32_BE: return AF_FORMAT_S32_BE;
#endif
#ifdef AFMT_FLOAT
    case AFMT_FLOAT: return AF_FORMAT_FLOAT_NE;
#endif
    // SPECIALS
    case AFMT_MU_LAW: return AF_FORMAT_MU_LAW;
    case AFMT_A_LAW: return AF_FORMAT_A_LAW;
    case AFMT_IMA_ADPCM: return AF_FORMAT_IMA_ADPCM;
#ifdef AFMT_MPEG
    case AFMT_MPEG: return AF_FORMAT_MPEG2;
#endif
#ifdef AFMT_AC3
    case AFMT_AC3: return AF_FORMAT_AC3;
#endif
    }
    return -1;
}*/


// to set/get/query special features/parameters
static int control(aio_device_t *device, int cmd,void *arg){

	aio_oss_internal_t * internal = (aio_oss_internal_t *)device->internal;
	switch(cmd){
		case AIOCONTROL_SET_DEVICE:
			if(internal->dsp != NULL)
				free(internal->dsp);
			internal->dsp=strdup((char*)arg);
			if(reset(device) < 0)
				return CONTROL_ERROR;

			return CONTROL_OK;
		case AIOCONTROL_GET_DEVICE:
	    		*(char**)arg = internal->dsp;
	    		return CONTROL_OK;
		case AIOCONTROL_SET_MODE: 
		{
			int *t= (int *)arg;
			internal->open_mode = *t;
			if(reset(device) < 0)
				return CONTROL_ERROR;
			return CONTROL_OK;
		}
		case AIOCONTROL_QUERY_FORMAT:
		{
	    		int format;
	    		if (!ioctl(internal->audio_fd, SNDCTL_DSP_GETFMTS, &format))
				if (format & (int)arg)
	    	    			return CONTROL_TRUE;
	   			 return CONTROL_FALSE;
		}	
		case AIOCONTROL_GET_PLAYBACK_VOLUME:
		case AIOCONTROL_SET_PLAYBACK_VOLUME:
		
		{
	    		aio_control_vol_t *vol = (aio_control_vol_t *)arg;
			int v;
			if(internal->oss_playback_mixer_channel == -1)
				return CONTROL_NA;
			else {
				if (cmd == AIOCONTROL_GET_PLAYBACK_VOLUME){

					ioctl(internal->audio_fd, MIXER_READ(internal->oss_playback_mixer_channel), &v);
					vol->right = (v & 0xFF00) >> 8;
					vol->left = (v&0x00FF);
				}else {	
					v = ((int)(vol->right) << 8) | (int) vol->left;
				

					ioctl(internal->audio_fd, MIXER_WRITE(internal->oss_playback_mixer_channel), &v);
		    		}


			}
	
		    	return CONTROL_OK;
	    
		}
		case AIOCONTROL_GET_RECORD_VOLUME:
		case AIOCONTROL_SET_RECORD_VOLUME:

		
		{
	    		aio_control_vol_t *vol = (aio_control_vol_t *)arg;
			int v;
			
			if(internal->oss_rec_mixer_channel == -1)
				return CONTROL_NA;
			else {
				if (cmd == AIOCONTROL_GET_RECORD_VOLUME){

					ioctl(internal->audio_fd, MIXER_READ(internal->oss_rec_mixer_channel), &v);
					vol->right = (v & 0xFF00) >> 8;
					vol->left = (v&0x00FF);
				}else {
					v = ((int)(vol->right) << 8) | (int) vol->left;
					ioctl(internal->audio_fd, MIXER_WRITE(internal->oss_playback_mixer_channel), &v);
		    		}


			}
	
		    	return CONTROL_OK;
	    

		}


				    
	    }
    return CONTROL_UNKNOWN;
}
static inline int _play2mode(int mode) {

		switch(mode) {
			case AIO_PLAYONLY:
				return  O_WRONLY;
			case AIO_RECONLY:
				return  O_RDONLY;
			case AIO_RECPLAY:
				return O_RDWR;
			default :
				return -1 ;
		}


}
/* 
 * open & setup audio device
 * return: 0=success -1=fail
*/
static int init(aio_device_t *device,aio_sample_format_t *sample_format ,const aio_option_t **options, int open_mode) {
	
	aio_oss_internal_t * internal;
	char *labels[] = SOUND_DEVICE_LABELS;

	
	int oss_format ; 	
	int tmp; /* to hold tempor the arg to ictl */
	
	aio_option_t ** opt = options;	
	
	aio_msg(AIO_DEBUG,"AIO_OSS -> init : initializing device %s",device->funcs->driver_info()->short_name);
	
	if(device == NULL)
		goto ERR;

	/* first time */
	if(device->internal == NULL){
		internal = (aio_oss_internal_t *) malloc (sizeof(aio_oss_internal_t));
		
		if(internal == NULL) { 
			goto ERR;
	
		}
		internal->dsp = NULL;	
		/*save the sample format structure in case we close the device  (to pause playback for instance)*/
	
		internal->s_format.byte_format = sample_format->byte_format;
		internal->s_format.format = sample_format->format;
		internal->s_format.channels = sample_format->channels;
		internal->s_format.samplerate = sample_format->samplerate;
	

		internal->s_format.bits = af_fmt2bits(sample_format->format);
		internal->s_format.bytes_per_sample = (internal->s_format.bits / 8) *internal->s_format.channels;
		internal->s_format.bps =  internal->s_format.bytes_per_sample * internal->s_format.samplerate;
		
		
		internal->open_mode = open_mode;

		/*default capture device mic */
		internal->oss_rec_mixer_channel = SOUND_MIXER_MIC;

		internal->oss_playback_mixer_channel = -1;
		
		device->internal = internal;	
	}else {
		/* not the first time that we call init 
		 * we already have all the info we need */
		internal = (aio_oss_internal_t *) device->internal;
	}
	
	
		
	
	
	

	/*Parse options */
	if(opt != NULL) {	
		while((*opt)){
			aio_msg(AIO_DEBUG,"AIO_OSS -> init setting option %s to %s",(*opt)->key,(*opt)->value);

			if(strcmp((*opt)->key,"dsp") == 0){
				if(internal->dsp != NULL)
					free(internal->dsp);
				internal->dsp = strdup((*opt)->value);
			}			
			else if(strcmp((*opt)->key,"rec_src") == 0){
				if(internal->open_mode == AIO_RECONLY || internal->open_mode == AIO_RECPLAY){
					if(strcmp(((*opt)->value),"line") == 0){
						internal->oss_rec_mixer_channel = SOUND_MIXER_LINE;
					}else {
						internal->oss_rec_mixer_channel = SOUND_MIXER_MIC;
					}
						

				}
				else
					aio_msg(AIO_WARN,"AIO_OSS -> init : trying to set rec_src while not recording ignoring");

			}
			 else {
				aio_msg(AIO_WARN,"AIO_OSS -> init invalide options %s ignoring",(*opt)->key);
			}

			opt++;
		}
	}
	


	/* user didn't set the DSP device via the options*/
	int mode = _play2mode(internal->open_mode);

	if(mode  == -1){
		aio_msg(AIO_ERROR,"AIO_OSS -> init:  unknow open mode");
		goto ERR;
	}
	if(internal->dsp == NULL) {
		
		internal->audio_fd = _open_default_oss_device(&internal->dsp,mode);
		if(internal->audio_fd  < 0){
			aio_msg(AIO_ERROR,"AIO_OSS -> init: could not open default oss device %s",strerror(errno));
			goto ERR;
		}
	}else {
	/*user provided DSP device*/
		aio_msg(AIO_DEBUG,"AIO_OSS -> init :opening user provided dsp device %s",internal->dsp);

		if((internal->audio_fd = open(internal->dsp,mode)) < 0){
			aio_msg(AIO_ERROR,"AIO_OSS -> init : error opening DSP: %s",strerror(errno));
			goto ERR;
		}
	}

	/*check the audio device for full dup caps*/

	if(internal->open_mode  == AIO_RECPLAY){
		aio_msg(AIO_DEBUG,"AIO_OSS -> init : checking the audio device for full duplex caps");
		int devcaps;
		if(ioctl(internal->audio_fd,SNDCTL_DSP_GETCAPS,&devcaps) ==-1){
			aio_msg (AIO_ERROR,"could not get caps %s",strerror(errno));
			goto ERR;
		}
	
		if (!(devcaps & DSP_CAP_DUPLEX)) {
			aio_msg(AIO_ERROR,"AIO_OSS -> init : Full duplex not supported please open the device for playback or recording only.");
			goto ERR;
		}
		aio_msg(AIO_DEBUG,"AIO_OSS -> init : enabling full duplex ..");
	

		if (ioctl (internal->audio_fd, SNDCTL_DSP_SETDUPLEX, NULL) == -1){
			aio_msg(AIO_ERROR,"AIO_OSS -> init : could not set full duplex mode : %s",strerror(errno));
			goto ERR;
			
		}
		aio_msg(AIO_DEBUG,"AIO_OSS -> init : full duplex enabled..");

	}
	oss_format = format2oss(internal->s_format.format);

	/*now that we have a device open lets set up the sample size 
	 * (8 16  ... bits) the number of channels ( mono stereo ... )  and the sampling rate*/
	aio_msg(AIO_DEBUG,"AIO_OSS ->  init : setting sample format for %s to %d: ", device->funcs->driver_info()->short_name, oss_format);
	
	/*set the format */
	tmp = oss_format;
	if((ioctl(internal->audio_fd, SNDCTL_DSP_SETFMT, &tmp) == -1)){ 
		aio_msg(AIO_ERROR,"AIO_OSS -> init :could not set the format to %d :%s",oss_format, strerror(errno));
		goto ERR;
	}
	
	if (tmp != oss_format){
		aio_msg(AIO_ERROR,"AIO_OSS -> init :unsupported requested (%d) sample format received \'%d\' instead ", oss_format,tmp);
		goto ERR;
	}
	
	/* set the number of channels*/
	aio_msg(AIO_DEBUG,"AIO_OSS -> init : setting number of channels  for %s to %d", device->funcs->driver_info()->short_name, internal->s_format.channels);
	
	
	tmp = internal->s_format.channels;
	
	if(ioctl(internal->audio_fd, SNDCTL_DSP_CHANNELS, &tmp) == -1){
	      	aio_msg(AIO_ERROR,"AIO_OSS -> init : could not set the channel's number to %d %s",internal->s_format.channels,strerror(errno));
		goto ERR;
		
	}
	if(tmp != internal->s_format.channels){
		aio_msg(AIO_ERROR,"AIO_OSS -> init : unsupported number of channels %d  received  %d instead", internal->s_format.channels, tmp);
		goto ERR;
	}
	

	/*audio buffer  fragment size*/
	internal->frag_size = -1;
	
	if(ioctl(internal->audio_fd, SNDCTL_DSP_GETBLKSIZE,&(internal->frag_size)) == -1)	
		goto ERR;
	
	aio_msg(AIO_DEBUG,"AIO_OSS -> init : fragment size for %s is %d", device->funcs->driver_info()->short_name,internal->frag_size );
	
	/*set the sample rate*/
	aio_msg(AIO_DEBUG,"AIO_OSS -> init : setting sample rate for %s to %d", device->funcs->driver_info()->short_name, internal->s_format.samplerate);
	
	tmp = internal->s_format.samplerate;
	if(ioctl(internal->audio_fd,SNDCTL_DSP_SPEED,&tmp) == -1){
		aio_msg(AIO_ERROR,"AIO_OSS -> init : could not set rate to %d : %s ",internal->s_format.samplerate,strerror(errno));
		goto ERR;
	}

	if(tmp > 1.02 *internal->s_format.samplerate || tmp < 0.98 * internal->s_format.samplerate) {
		aio_msg(AIO_ERROR,"AIO_OSS -> init : unsupported sample rate %d  go %d instead",internal->s_format.samplerate,tmp);
		goto ERR;
	}
		
	/*get the device buffer size*/
	if(ioctl(internal->audio_fd, SNDCTL_DSP_GETOSPACE, &(internal->a_buf_info))==-1){

	} else {
			internal->buffersize=internal->a_buf_info.bytes;
	}

	if(internal->open_mode ==  AIO_RECPLAY){
		
		int mask = 0;
		
		if(ioctl(internal->audio_fd,SOUND_MIXER_READ_RECMASK,&mask) == -1){
				aio_msg(AIO_ERROR,"AIO_OSS -> init : error reading RECMASK %s",strerror(errno));
				goto ERR;
		}

		if(mask & (1<<internal->oss_rec_mixer_channel)){
			aio_msg(AIO_DEBUG,"AIO_OSS -> init : setting recoding source to : %s",labels[internal->oss_rec_mixer_channel]);
		}else {
			aio_msg(AIO_ERROR,"AIO_OSS -> init : error no suitable recording channel found (line or mic) reading ");

			goto ERR;
		}

	}
		/* if we get this far everything went smooth, the device is open and ready */ 
	
	int devs = 0;
	aio_msg(AIO_DEBUG,"AIO_OSS -> init : trying mixer support");

	if(ioctl(internal->audio_fd, SOUND_MIXER_READ_DEVMASK, &devs)){
		aio_msg(AIO_WARN,"AIO_OSS_INIT-> could not get mixers %s",strerror(errno));
	
	}

	/* attemp to user the PCM channel*/
	if(devs& (1<<SOUND_MIXER_PCM)){
		internal->oss_playback_mixer_channel = SOUND_MIXER_PCM;
	}
	/* if PSM not available try to use the master volume*/
	else if (devs & (1<<SOUND_MIXER_VOLUME))
		internal->oss_playback_mixer_channel = SOUND_MIXER_VOLUME;
	
	else {	
		aio_msg(AIO_WARN,"AIO_OSS -> init : no usable mixer channel found disabling mixer support");
		internal->oss_playback_mixer_channel = -1;
	}
	if(internal->oss_playback_mixer_channel != -1){
		
		aio_msg(AIO_DEBUG,"AIO_OSS -> init : mixer channel set to: %s",labels[internal->oss_playback_mixer_channel]);
	}

	
	return 0;

ERR:
	/*somthing fishy happend above, try to close the device and tell the caller no */
	if(internal->audio_fd > 0 )
		close(internal->audio_fd);

	if(internal != NULL){
		if(internal->dsp != NULL)
			free(internal->dsp);
		internal->dsp = NULL;
		free(internal);
		internal = NULL;
		device->internal = NULL;
	}

	return -1;


}
static inline int _oss_close_device(aio_device_t *device,int immed) {
	
	aio_oss_internal_t *internal =  NULL;
	int r = -1;	
	if(device == NULL){
		return -1;
	}
	internal = (aio_oss_internal_t *) device->internal;
	if(internal == NULL){
		return -1;
	}

	if (immed)
		/*if imm drop and rest the device*/
		ioctl(internal->audio_fd, SNDCTL_DSP_RESET, NULL);
	else {
		/*otherwise wait for the playback to finish*/
		ioctl(internal->audio_fd, SNDCTL_DSP_SYNC, NULL);
	}
	if(internal->audio_fd != -1 ){
		r = close(internal->audio_fd);
		internal->audio_fd = -1;
	}
	return r;
}

// close audio device
static int  uninit(aio_device_t *device, int immed){
	
	aio_oss_internal_t *internal = NULL;
	
	if(device == NULL) {
		
		goto err;
	}
	
	internal = device->internal;

	if(internal == NULL ) {
		goto err;
	}
	
	if(internal->audio_fd == -1) 
		goto err;
    

	_oss_close_device(device,immed);

	if(internal->dsp != NULL);
		free(internal->dsp);
	free(internal);
	return 0; 

err :
	aio_msg(AIO_ERROR,"AIO_OSS -> uninit : called uninit with an uninitilized device");
	return -1;
}

// stop playing and empty buffers (for seeking/pause)
static int  reset(aio_device_t *device ){
  	
	
	aio_oss_internal_t * internal = NULL ;
    	int r;
	if(device == NULL){

		goto err;
	}
	internal = (aio_oss_internal_t *)device->internal;
	if(internal == NULL){
		goto err;
	}
	internal = (aio_oss_internal_t *) device->internal; 
    	
	_oss_close_device(device,1);
	
	if( (r=init(device,NULL,NULL,internal->open_mode)) < 0 ){
		aio_msg(AIO_ERROR,"AIO_OSS -> reset : could not reinit the device");
	}
	return r;

err:
	aio_msg(AIO_ERROR,"AIO_OSS -> reset : called  with an uninitlized device");
	return -1;

}

// stop playing, keep buffers (for pause)
static int audio_pause(aio_device_t *device)
{	aio_oss_internal_t * internal =  NULL;
	if(device == NULL){
		goto err;
	}
	internal = (aio_oss_internal_t *)device->internal;
	if(internal == NULL){
		goto err;
	}
	internal = (aio_oss_internal_t *) device->internal; 



	internal->prepause_space = get_space(device,AIO_SPACE_OUT);
	return _oss_close_device(device,1);

err:
	aio_msg(AIO_ERROR,"AIO_OSS -> audio_pause : called  with an uninitlized device");
	return -1;
	
}

// resume playing, after audio_pause()
static int audio_resume(aio_device_t* device)
{	
	aio_oss_internal_t * internal = NULL;

    	int8_t fillcnt;
   	
	if(reset(device) < 0){
		aio_msg(AIO_ERROR,"AIO_OSS -> audio_resume : error reseting the device");
		return -1;
	}
	
	internal = (aio_oss_internal_t *) device->internal; 
	
	fillcnt = get_space(device,AIO_SPACE_OUT) - internal->prepause_space;
    	
	if (fillcnt > 0) {
      		int8_t * silence = (int8_t *)calloc(fillcnt, 1);
		if(silence == NULL){
			aio_msg(AIO_ERROR,"AIO_OSS -> audio_resume : could not allocate repause silence memory");
			return -1;
		}
     		play(device,silence, fillcnt, 0);
      		free(silence);
    	}
	
	return 0;

}


// return: how many bytes can be played without blocking
// or -1 if the device is null or uninitialized 
static int get_space(aio_device_t *device,int dir){
	
	aio_oss_internal_t * internal;
	int space;
	int req;
	char * str_dir = NULL;
	
	/*we don't have a device */ 
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_OSS -> get_space : called  with an uninitlized device structure");

		return -1;
	}
	internal = device->internal;
	
	if(internal == NULL){
		aio_msg(AIO_ERROR,"AIO_OSS -> get_space : called  with an uninitlized device internal structure");
		return -1;
	}	
	
	if(dir == AIO_SPACE_OUT){
		req = SNDCTL_DSP_GETOSPACE;
		str_dir = "output";
	}else if (dir == AIO_SPACE_IN){
		req = SNDCTL_DSP_GETISPACE;
		str_dir = "input";
	}else {
		aio_msg(AIO_ERROR,"AIO_OSS -> get_space unknown direction");
		return -1;
	}

	if((space = ioctl(internal->audio_fd, req, &(internal->a_buf_info))) !=-1){
		
		space = internal->a_buf_info.fragments*internal->a_buf_info.fragsize;
		aio_msg(AIO_DEBUG,"AIO_OSS -> get_space : available non blocking space for %s: %d bytes",str_dir,space);
	}else {
		
		aio_msg(AIO_ERROR,"AIO_OSS -> get_space : error getting %s buffer infos : %s",str_dir,strerror(errno));
	}

	return space;
	
}

// plays 'len' bytes of 'data'
// return: number of bytes played
// 	-1 if errors
static int play(aio_device_t* device,int8_t * data,size_t len, int last_chunk){
	
	aio_oss_internal_t * internal;
	if(device == NULL) {
		aio_msg(AIO_ERROR,"AIO_OSS -> play : called play with uninitialized device");
		return -1 ;
	}


	internal = device->internal;

	if(internal == NULL){

		aio_msg(AIO_ERROR,"AIO_OSS -> play : called play with uninitialized device");
		return -1 ;
	}
		
	if(len == 0)
		return 0;
	 /* 
	  * round the length down to * frag_size unless it's the final chunk.
	 */
	if(len > internal->frag_size || !last_chunk){
		len /=  internal->frag_size;
		len *= internal->frag_size;
	}
	return write(internal->audio_fd,data,len);
		
}
static int record(aio_device_t *device, int8_t *buffer,size_t len, int flags){
	aio_oss_internal_t * internal;

	if(device == NULL) {
		aio_msg(AIO_ERROR,"AIO_OSS -> record : called play with uninitialized device");
		return -1 ;
	}


	internal = device->internal;

	if(internal == NULL){

		aio_msg(AIO_ERROR,"AIO_OSS -> record : called play with uninitialized device");
		return -1 ;
	}



	
	/* round down to a multiple of  frag_size
	 * and since fragment are sets of samples we're readinf full frames */
	len /= internal->frag_size;
	len *= internal->frag_size;

	/* we should read somthing (a fragment is good) otherwise get_space will 
	 * always report 0 bytes for reading*/	
	if (len == 0)
		len = internal->frag_size;
	return read(internal->audio_fd,buffer,len);

}

// return: delay in seconds between first and last sample in buffer

static float get_delay(aio_device_t *device){
	aio_oss_internal_t *internal = NULL;
	
	if(device == NULL){
		goto err;
	}
	internal = (aio_oss_internal_t *)device->internal;
	if(internal == NULL){
		goto err;
	}
	internal = (aio_oss_internal_t *) device->internal; 
	
	
	if(!(internal->open_mode & AIO_PLAYONLY)){
		aio_msg(AIO_WARN,"AIO_OSS ->  get_delay  not available if open in capture mode");
		return -1;
	}
  /* Calculate how many bytes/second is sent out */
	int r=0;
	if(ioctl(internal->audio_fd, SNDCTL_DSP_GETODELAY, &r)!=-1)
		return ((float)r)/(float)internal->s_format.bps;
	else 
		return -1;

err:	
	aio_msg(AIO_ERROR,"AIO_OSS -> get_delay : called  with an uninitlized device");
	return -1;
}

static aio_info_t * driver_info(){
	return &info;
}

LIBAIO_EXTERN_DYNAMIC();
