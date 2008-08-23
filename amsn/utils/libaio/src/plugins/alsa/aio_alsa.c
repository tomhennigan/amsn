/**
 * \file src/plugins/alsa/aio_alsa.c
 * \brief Alsa plugin 
 * \author Mohamed Abderaouf Bencheraiet <kenshin@cerberus.endoftheinternet.org>
 * \date 2008
 *
 * Alsa plugin 
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
 *\defgroup alsa Alsa plugin
 *\{
 *
 *Advanced Linux Sound Architecture. This driver borrows some code from  the Mplayer libao2  
 *<http://mplayer.hq>, XIPHE libao <http://xiphe.org> and aplay wich is included with the alsa-util distribution. 
 *It defaults to "default" device. 
 *
 *Option keys: 
 *<UL>
 *	<LI>card -> The audio device to use.
 *  	<LI>ibuffer_time -> input buffer time value
 *	<LI>ibuffer_size -> input buffer size value
 *	<LI>iperiod_time -> input period time value
 *	<LI>iperiod_size -> input period size value
 *	<LI>obuffer_time -> output buffer time value
 *	<LI>obeffer_size -> output buffer_size value
 *	<LI>operiod_time -> output period time value
 *	<LI>operiod_size -> output period size value
 *	<LI>oavail_min -> output min avail space for wakup in us
 *	<LI>iavail_min -> input min avail space for wakup in us
 *	<LI>ostart_delay -> outut start delay in us
 *	<LI>istart_delay -> input start delay in us
 *	<LI>ostop_delay -> output automatic stop from xrun delay in us
 *	<LI>istop_delay -> input automatic stop from xrun delay in us
 *	<LI>use_mmap ->  Yes or No to enable/disable mmio
 *	<LI>async -> Yes or No to use or not the async mode offered by alsalib(Not implemented yet)
 *<UL>
 * 
 * \}*/
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include "config.h"

#include <alsa/asoundlib.h>

#include "af_format.h"
#include "aio/aio.h"
#include "aio/aio_plugin.h"

#define ALSA_PCM_NEW_HW_PARAMS_API
#define ALSA_PCM_NEW_SW_PARAMS_API


/* default 500 millisecond buffer */
#define AIO_ALSA_BUFFER_TIME 500000

/* the period time is calculated if not given as an option */
#define AIO_ALSA_PERIOD_TIME 0

/* number of samples between interrupts
 * supplying a period_time to ao overrides the use of this  */
#define AIO_ALSA_SAMPLE_XFER 256

/* set mmap to default if enabled at compile time, otherwise, mmap isn't
   the default */
#ifdef USE_ALSA_MMIO
#define AIO_ALSA_WRITEI snd_pcm_mmap_writei
#define AIO_ALSA_ACCESS_MASK SND_PCM_ACCESS_MMAP_INTERLEAVED
#define AIO_ALSA_READI snd_pcm_mmap_readi
#else
#define AIO_ALSA_READI snd_pcm_readi
#define AIO_ALSA_WRITEI snd_pcm_writei
#define AIO_ALSA_ACCESS_MASK SND_PCM_ACCESS_RW_INTERLEAVED
#endif
typedef snd_pcm_sframes_t ao_alsa_writei_t(snd_pcm_t *pcm, void *buffer,
						snd_pcm_uframes_t size);

typedef snd_pcm_sframes_t ao_alsa_readi_t(snd_pcm_t *pcm, void *buffer,
						snd_pcm_uframes_t size);


/*index of the streams in the arrays*/
#define ALSA_CAPTURE_STREAM_IDX 0
#define ALSA_PLAYBACK_STREAM_IDX 1
#define ALSA_STREAMS 2
static aio_option_info_t aio_alsa_options[] = {
	{"card", "The audio device to use."},
	{"ibuffer_time","buffer time value"},
	{"ibuffer_size","buffer size value"},
	{"iperiod_time","period time value"},
	{"iperiod_size","period size value"},

	{"obuffer_time","buffer time value"},
	{"obeffer_size","buffer_size value"},
	{"operiod_time","period time value"},
	{"operiod_size","period size value"},
	{"oavail_min","output min avail space for wakup in us"},
	{"iavail_min","input min avail space for wakup in us"},
	{"ostart_delay","outut start delay in us"},
	{"istart_delay","input start delay in us"},
	{"ostop_delay","output automatic stop from xrun delay in us"},
	{"istop_delay","input automatic stop from xrun delay in us"},
	{"use_mmap"," Yes or No"},
	{"async", "Yes or No (Not implemented yet)"},
	{}
    };
static aio_info_t info = 
{
	"ALSA-1.x audio output",
	"alsa",
	"",
	"",
	AIO_FMT_NATIVE,
	30,
	aio_alsa_options,
	17	
};
typedef struct alsa_mixer_s {
	char              *name;
 	char		  *card;
	snd_mixer_t       *handle;
	snd_mixer_elem_t  *elem;
	long               min;
	long               max;
	int		disabled;
	float f_multi;

} alsa_mixer_t;

typedef struct aio_alsa_internal_s {
	snd_pcm_t *handles[2];
	
	unsigned int buffer_time[2];
	snd_pcm_uframes_t buffer_size[2];

	unsigned int period_time [2];
	snd_pcm_uframes_t period_size[2];
	int avail_min[2];
	int start_delay[2];
	int stop_delay[2];
	ao_alsa_readi_t *readi;
	ao_alsa_writei_t * writei;
	snd_pcm_access_t access_mask;

	
	char *card;
	char *rec_src;
	char *cmd;
	snd_pcm_uframes_t chunk_size ;
	int pcm_open_mode;
	int open_mode;
	int alsa_can_pause ;
	aio_sample_format_t s_format;
	alsa_mixer_t *mixers[2];
} aio_alsa_internal_t;

/*stream names */
static char  *streams_names[] = {
	"capture stream",
	"playback stream"
};


static int _format2alsa(int format) {
	switch(format) {
		case AF_FORMAT_U8: return SND_PCM_FORMAT_U8;
		case AF_FORMAT_S8: return SND_PCM_FORMAT_S8;
		case AF_FORMAT_U16_LE: return SND_PCM_FORMAT_U16_LE;
		case AF_FORMAT_U16_BE: return SND_PCM_FORMAT_U16_BE;
		case AF_FORMAT_S16_LE: return SND_PCM_FORMAT_S16_LE;
		case AF_FORMAT_S16_BE: return SND_PCM_FORMAT_S16_BE;
		case AF_FORMAT_U24_LE: return SND_PCM_FORMAT_U24_LE;
		case AF_FORMAT_U24_BE: return SND_PCM_FORMAT_U24_BE;
		case AF_FORMAT_S24_LE: return SND_PCM_FORMAT_S24_LE;
		case AF_FORMAT_S24_BE: return SND_PCM_FORMAT_S24_BE;
		case AF_FORMAT_U32_LE: return SND_PCM_FORMAT_U32_LE;
		case AF_FORMAT_U32_BE: return SND_PCM_FORMAT_U32_BE;
		case AF_FORMAT_S32_LE: return SND_PCM_FORMAT_S32_LE;
		case AF_FORMAT_S32_BE: return SND_PCM_FORMAT_S32_BE;
		case AF_FORMAT_FLOAT_NE: return SND_PCM_FORMAT_FLOAT;
    /* SPECIALS */
		case AF_FORMAT_MU_LAW: return SND_PCM_FORMAT_MU_LAW;
		case AF_FORMAT_A_LAW: return SND_PCM_FORMAT_A_LAW;
		case AF_FORMAT_IMA_ADPCM: return SND_PCM_FORMAT_IMA_ADPCM;
		case AF_FORMAT_MPEG2: return SND_PCM_FORMAT_MPEG;
		/*case AF_FORMAT_AC3: return SND_PCM_FORMAT_AC3;*/

	}
	return AF_FORMAT_UNKNOWN;
}
/*static int _alsa2format(int format) {
	return 0 ;
}*/


	
static int _alsa_init_mixer(alsa_mixer_t *mixer){
	
	
	
	
	/* init mixer support */
	snd_mixer_selem_id_t *sid;
	int err;

	if(mixer == NULL){

		return -1;
	}


	snd_mixer_selem_id_malloc(&sid);	
	
	if(sid == NULL){
		aio_msg(AIO_WARN,"AIO_ALSA -> _init_mixer : could not allocate memory for snd_mixer_selem_id ignoring mixer setup");
		return -1;
	}

	aio_msg(AIO_DEBUG,"AIO_ALSA -> _alsa_init_mixer: setting up mixer");


	err = snd_mixer_open(&(mixer->handle),0);

	if(err < 0){
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_init_mixer: error opening mixer: %s ignoring mixer setup  ",snd_strerror(err));
		return -1;
	}
	err = snd_mixer_attach(mixer->handle,mixer->card);

	if(err < 0 ){
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_init_mixer: error attaching mixer to device(%s): %s",mixer->card,snd_strerror(err));
		goto mixer_init_fail;
	
	}
	
	err = snd_mixer_selem_register (mixer->handle, NULL, NULL);
	if(err <0) {
		aio_msg(AIO_WARN,"AIO_ALSA -> init: error in snd_mixer_selem_register: %s ignoring mixer setup",snd_strerror(err));
		goto mixer_init_fail;
	}	


	err = snd_mixer_load(mixer->handle);
	if(err <0) {
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_init_mixer: error in snd_mixer_load: %s ignoring mixer setup",snd_strerror(err));
		goto mixer_init_fail;
	}

	aio_msg(AIO_DEBUG,"AIO_ALSA -> _alsa_init_mixer : trying %s mixer",(mixer->name));
	
	snd_mixer_selem_id_set_index(sid,0);
      	snd_mixer_selem_id_set_name(sid,mixer->name);
	mixer->elem = snd_mixer_find_selem(mixer->handle,sid);
	
	if(mixer->elem == NULL){
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_init_mixer : unable to find control %s, %d disabeling mixer",snd_mixer_selem_id_get_name(sid),snd_mixer_selem_id_get_index(sid) );

		snd_mixer_selem_id_free (sid);
		goto mixer_init_fail;
	}
	

	snd_mixer_selem_id_free (sid);
	


	return 0;

mixer_init_fail:
	snd_mixer_close(mixer->handle);
	mixer->handle=NULL;
	return -1;

}

/* set's the capture to the desired source  Mic or Line */
static void _alsa_set_capture_source(aio_alsa_internal_t  *internal,char *source){
	alsa_mixer_t mixer;
	mixer.card = strdup(internal->card);
	mixer.name = strdup(source);
	
	/* if init_mixer can't find the mixer element it will set the mixer to NULL*/
	if(_alsa_init_mixer(&mixer) == 0){
		if(snd_mixer_selem_has_capture_switch(mixer.elem)) {
			int sw;
       			if (snd_mixer_selem_has_capture_switch_joined(mixer.elem)) {
       				snd_mixer_selem_get_capture_switch(mixer.elem,SND_MIXER_SCHN_FRONT_LEFT , &sw);
				snd_mixer_selem_set_capture_switch_all(mixer.elem, !sw);
			}else {
	
				if (snd_mixer_selem_has_capture_channel(mixer.elem,SND_MIXER_SCHN_FRONT_LEFT)) {
					snd_mixer_selem_get_capture_switch(mixer.elem, SND_MIXER_SCHN_FRONT_LEFT, &sw);
					snd_mixer_selem_set_capture_switch(mixer.elem, SND_MIXER_SCHN_FRONT_LEFT, !sw);
				}		
				
				if (snd_mixer_selem_has_capture_channel(mixer.elem,SND_MIXER_SCHN_FRONT_RIGHT)){
					snd_mixer_selem_get_capture_switch(mixer.elem,SND_MIXER_SCHN_FRONT_RIGHT , &sw);
					snd_mixer_selem_set_capture_switch(mixer.elem, SND_MIXER_SCHN_FRONT_RIGHT, !sw);
				}
	
			}

	
	
		}
		free(mixer.name);
		free(mixer.card);
		snd_mixer_close(mixer.handle);
	}
}
static int _alsa_set_get_capture_volume(aio_alsa_internal_t *internal, aio_control_vol_t *vol,int set ){

	alsa_mixer_t mixer;
	long set_vol;
	int err;
		
	if(internal->open_mode & AIO_RECONLY){
		mixer.name=strdup("Capture");
		mixer.card = strdup(internal->card);
		
		if(_alsa_init_mixer(&mixer) == -1){
			return CONTROL_ERROR;
		}
		
		if(!(snd_mixer_selem_has_capture_volume (mixer.elem))){
			
			aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_set_get_capture_volume : ixer element doesn't have volume controle");
			snd_mixer_close(mixer.handle);
			return CONTROL_NA;
		}
	
		snd_mixer_selem_get_capture_volume_range(mixer.elem,&(mixer.min),&(mixer.max));

		mixer.f_multi = (100 / (float)(mixer.max - mixer.min));
		if(set)	{

			/*if the capture volume is not joined (ie one control per channel) set the right channel*/
			if(!snd_mixer_selem_has_capture_volume_joined(mixer.elem)){
								
				if (snd_mixer_selem_has_capture_channel(mixer.elem,SND_MIXER_SCHN_FRONT_RIGHT)){

					set_vol = vol->right / mixer.f_multi + mixer.min + 0.5;
					err = snd_mixer_selem_set_capture_volume(mixer.elem, SND_MIXER_SCHN_FRONT_RIGHT, set_vol);
					if(err < 0)
						goto _set_get_cap_error;
				}
			}
			/* set the left channel volume */
			set_vol = vol->left / mixer.f_multi + mixer.min + 0.5;
			err = snd_mixer_selem_set_capture_volume(mixer.elem, SND_MIXER_SCHN_FRONT_LEFT, set_vol);
			if(err < 0 )
				goto _set_get_cap_error;			
			
		}else {
			
			if(!snd_mixer_selem_has_capture_volume_joined(mixer.elem)){
				err = snd_mixer_selem_get_capture_volume(mixer.elem, SND_MIXER_SCHN_FRONT_RIGHT, &set_vol);
				if(err < 0)
					goto _set_get_cap_error;
				
				vol->right = (set_vol  - mixer.min) * mixer.f_multi; 
			}
			err = snd_mixer_selem_get_capture_volume(mixer.elem,SND_MIXER_SCHN_FRONT_LEFT , &set_vol);
			if(err < 0) 
				goto _set_get_cap_error;
			vol->left = (set_vol  - mixer.min) * mixer.f_multi; 

		}
		snd_mixer_close(mixer.handle);

		
	}else {
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_set_get_capture_volume : trying to set capture volume for non capture device");
		return CONTROL_ERROR;
	}
	
	
	return CONTROL_OK;

_set_get_cap_error:
	if(mixer.handle){
		snd_mixer_close(mixer.handle);
	}
	aio_msg(AIO_ERROR,"AIO_ALSA _alsa_set_get_capture_volume erro: %s",snd_strerror(err));
	return CONTROL_ERROR;

	
	/*unmute the mixer if the set volume != 0*/
	/*int swl = 0, swr = 0;
	if(snd_mixer_selem_has_capture_switch(mixer->elem)){
				swl = (vol->left == 0.0);
				swr = (vol->right == 0.0);
				if (snd_mixer_selem_has_playback_switch_joined(mixer->elem)) {
					swl = swr = swr && swr;
				}else{
					snd_mixer_selem_set_capture_switch(mixer->elem, SND_MIXER_SCHN_FRONT_RIGHT, !swr);
				}
				snd_mixer_selem_set_capture_switch(mixer->elem, SND_MIXER_SCHN_FRONT_LEFT, !swl);

			}*/
}
static int _alsa_set_get_playback_volume(aio_alsa_internal_t *internal, aio_control_vol_t *vol,int set ){

	alsa_mixer_t mixer;
	long set_vol;
	int err;
		
	if(internal->open_mode & AIO_PLAYONLY){
		mixer.name=strdup("PCM");
		mixer.card = strdup(internal->card);
		
		if(_alsa_init_mixer(&mixer) == -1){
			return CONTROL_ERROR;
		}
		
		if(!(snd_mixer_selem_has_playback_volume (mixer.elem))){
			
			aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_set_get_playback_volume : mixer element doesn't have volume controle");
			snd_mixer_close(mixer.handle);
			return CONTROL_NA;
		}
	
		snd_mixer_selem_get_playback_volume_range(mixer.elem,&(mixer.min),&(mixer.max));

		mixer.f_multi = (100 / (float)(mixer.max - mixer.min));
		if(set)	{

			/*if the playback volume is not joined (ie one control per channel) set the right channel*/
			if(!snd_mixer_selem_has_playback_volume_joined(mixer.elem)){
								
				if (snd_mixer_selem_has_playback_channel(mixer.elem,SND_MIXER_SCHN_FRONT_RIGHT)){

					set_vol = vol->right / mixer.f_multi + mixer.min + 0.5;
					err = snd_mixer_selem_set_playback_volume(mixer.elem, SND_MIXER_SCHN_FRONT_RIGHT, set_vol);
					if(err < 0)
						goto _set_get_play_error;
				}
			}
			/* set the left channel volume */
			set_vol = vol->left / mixer.f_multi + mixer.min + 0.5;
			err = snd_mixer_selem_set_playback_volume(mixer.elem, SND_MIXER_SCHN_FRONT_LEFT, set_vol);
			if(err < 0 )
				goto _set_get_play_error;			
			
		}else {
			
			if(!snd_mixer_selem_has_playback_volume_joined(mixer.elem)){
				err = snd_mixer_selem_get_playback_volume(mixer.elem, SND_MIXER_SCHN_FRONT_RIGHT, &set_vol);
				if(err < 0)
					goto _set_get_play_error;
				
				vol->right = (set_vol  - mixer.min) * mixer.f_multi; 
			}
			err = snd_mixer_selem_get_playback_volume(mixer.elem,SND_MIXER_SCHN_FRONT_LEFT , &set_vol);
			if(err < 0) 
				goto _set_get_play_error;
			vol->left = (set_vol  - mixer.min) * mixer.f_multi; 

		}
		snd_mixer_close(mixer.handle);

		
	}else {
		aio_msg(AIO_WARN,"AIO_ALSA -> _alsa_set_get_playback_volume  :trying to set capture volume for non capture device");
		return CONTROL_ERROR;
	}
	
	
	return CONTROL_OK;

_set_get_play_error:
	if(mixer.handle){
		snd_mixer_close(mixer.handle);
	}
	aio_msg(AIO_ERROR,"AIO_ALSA _alsa_set_get_playback_volume erro: %s",snd_strerror(err));
	return CONTROL_ERROR;

	
}

/* to set/get/query special features/parameters */
static int control(aio_device_t *device,int cmd, void *arg)
{
	aio_alsa_internal_t *internal = NULL;

	if(device == NULL) {
		return CONTROL_ERROR;
	}
	internal = (aio_alsa_internal_t *) device->internal;

	if(internal == NULL){
		return CONTROL_ERROR;
	}
	switch(cmd) {
	case AIOCONTROL_SET_MODE: 
		{
			int *t= (int *)arg;
			internal->open_mode = *t;
			if(reset(device) < 0)
				return CONTROL_ERROR;
			return CONTROL_OK;
		}

	case AIOCONTROL_GET_RECORD_VOLUME:	
	case AIOCONTROL_SET_RECORD_VOLUME:
		{	
		aio_control_vol_t *vol = (aio_control_vol_t *)arg;
		if(cmd == AIOCONTROL_SET_RECORD_VOLUME)
       			return _alsa_set_get_capture_volume(internal,vol,1);
		else
			return _alsa_set_get_capture_volume(internal,vol,0);
		break;
		}
	case AIOCONTROL_GET_PLAYBACK_VOLUME:

	case AIOCONTROL_SET_PLAYBACK_VOLUME:
		{
		aio_control_vol_t *vol = (aio_control_vol_t *)arg;
		if(cmd == AIOCONTROL_SET_PLAYBACK_VOLUME)
       			return _alsa_set_get_playback_volume(internal,vol,1);
		else
			return _alsa_set_get_playback_volume(internal,vol,0);
		break;

		}
	}
  return(CONTROL_UNKNOWN);
}

static int alsa_set_sw_params(aio_alsa_internal_t * internal) {
	int err;
	snd_pcm_sw_params_t   *params;

	snd_pcm_uframes_t start_threshold, stop_threshold;
	int n;
	int i = 0;
	for (i = 0; i< ALSA_STREAMS ;i++) {
		if(internal->handles[i]) {	
			aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_sw_params : setting alsa sw params for %s handler",streams_names[i]);

	
	
			/* allocate the software parameter structure */
			snd_pcm_sw_params_malloc(&params);
		
			/* fetch the current software parameters */
			internal->cmd = "snd_pcm_sw_params_current";
			err = snd_pcm_sw_params_current(internal->handles[i], params);
			if (err < 0)
				goto sw_failed;
			
			
			if (internal->avail_min[i] < 0)
		                n = internal->period_size[i];
        		else
                		n = (double) internal->s_format.samplerate * internal->avail_min[i] / 1000000;
			
			internal->cmd = "snd_pcm_sw_params_set_avail_min";
			err = snd_pcm_sw_params_set_avail_min(internal->handles[i], params, n);
			if(err < 0)
				goto sw_failed;
			
			if(internal->start_delay[i] <=0 ){
				start_threshold = n + (double) internal->s_format.samplerate * internal->start_delay[i] /1000000;

			}else
				start_threshold = (double) internal->s_format.samplerate * internal->start_delay[i] / 1000000;

			if (start_threshold < 1)
				start_threshold = 1;
			if (start_threshold > n)
				start_threshold = n;
			internal->cmd = " snd_pcm_sw_params_set_start_threshold";
			err = snd_pcm_sw_params_set_start_threshold(internal->handles[i], params, start_threshold);
			if (err < 0)
				goto sw_failed;
			
			if (internal->stop_delay[i] <= 0){

					
				stop_threshold = internal->buffer_size[i] + (double) internal->s_format.samplerate * internal->stop_delay[i] / 1000000;
			}
			else
				stop_threshold = (double) internal->s_format.samplerate * internal->stop_delay[i] / 1000000;

			err = snd_pcm_sw_params_set_stop_threshold(internal->handles[i], params, stop_threshold);
			if(err<0)
				goto sw_failed;
		
		

			/* commit the params structure to ALSA */
			internal->cmd = "snd_pcm_sw_params";
			err = snd_pcm_sw_params(internal->handles[i], params);
			if (err < 0)
				goto sw_failed;

			snd_pcm_sw_params_free(params);
			params = NULL;
	
		}
	}
	
	return 0;

sw_failed:
	if(params)
		snd_pcm_sw_params_free(params);
	aio_msg(AIO_ERROR,"AIO_ALSA -> alsa_set_sw_params : set sw_params failed : %s",snd_strerror(err));
	return err;
}

static int alsa_set_hw_params(aio_alsa_internal_t * internal) {
	snd_pcm_hw_params_t   *params;

	int err;
	unsigned int rate ;
	int i;

	snd_pcm_format_t alsa_format; 
	for(i = 0; i< ALSA_STREAMS ;i++) { 
		if(internal->handles[i]) {
			aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: setting alsa hw params for %",streams_names[i]);
			
			/* allocate the hardware parameter structure */
			snd_pcm_hw_params_malloc(&params);
	
			/* fetch all possible hardware parameters */
			internal->cmd = "snd_pcm_hw_params_any";
			err = snd_pcm_hw_params_any(internal->handles[i], params);
			if(err < 0)
				goto hw_failed;
		
		
	
			/* unset hardware resampling */
			err = snd_pcm_hw_params_set_rate_resample(internal->handles[i], params, 0);
			if (err < 0) {
				goto hw_failed;
			}
		
			/* set the access type */
			internal->cmd = "snd_pcm_hw_params_set_access"; 
			err = snd_pcm_hw_params_set_access(internal->handles[i],
				params, internal->access_mask);
			if (err < 0)
				goto hw_failed;
		
			/*set the sample bitformat*/
			aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: setting sample format to :%d ",internal->s_format.format);
			internal->cmd = "nd_pcm_hw_params_set_format" ;
			alsa_format = _format2alsa(internal->s_format.format);
			err = snd_pcm_hw_params_set_format(internal->handles[i],params,alsa_format );
			if(err < 0 )
				goto hw_failed;
			
			/* set the number of channels */
			aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: setting number of channels to :%d ",internal->s_format.channels);
			internal->cmd = "snd_pcm_hw_params_set_channels";
			err = snd_pcm_hw_params_set_channels(internal->handles[i],
					params, (unsigned int)internal->s_format.channels);
			if (err < 0)
				goto hw_failed;

			/* save the sample size in bytes for posterity */
			internal->s_format.bits = snd_pcm_format_physical_width(alsa_format);
			internal->s_format.bytes_per_sample =  (internal->s_format.bits/8) * internal->s_format.channels;

			/* set the sample rate */
			aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: setting the sample rate to :%d ",internal->s_format.samplerate);
			rate = internal->s_format.samplerate;
			internal->cmd = "snd_pcm_hw_params_set_rate_near";
			err = snd_pcm_hw_params_set_rate_near(internal->handles[i],
					params, &rate, 0);
			if (err < 0)
				goto hw_failed;
			if (rate > 1.05 * internal->s_format.samplerate || rate < 0.95 * internal->s_format.samplerate) {
				aio_msg(AIO_WARN, "AIO_ALSA -> alsa_set_hw_params: warning: sample rate %i not supported "
					"by the hardware, using %u", internal->s_format.samplerate, rate);
			}

			internal->s_format.bps = internal->s_format.bytes_per_sample * rate;
		
			if (internal->buffer_time[i] == 0 && internal->buffer_size[i] == 0) {
				internal->cmd = "snd_pcm_hw_params_get_buffer_time_max";
				err = snd_pcm_hw_params_get_buffer_time_max(params,&(internal->buffer_time[i]), 0);
					if(err < 0)
						goto hw_failed;
			if (internal->buffer_time[i] > AIO_ALSA_BUFFER_TIME)
				internal->buffer_time[i] = AIO_ALSA_BUFFER_TIME;
			}
			if (internal->period_time[i] == 0 && internal->period_size[i] == 0) {
				if (internal->buffer_time[i] > 0)
					internal->period_time[i] = internal->buffer_time[i] / 4;
				else
					internal->period_size[i] = internal->buffer_size[i] / 4;
			}
	
			
			internal->cmd = "snd_pcm_hw_params_set_period_time_near";
	
			if (internal->period_time[i] > 0)
				err = snd_pcm_hw_params_set_period_time_near(internal->handles[i], params,
			   						&(internal->period_time[i]), 0);
			else
				err = snd_pcm_hw_params_set_period_size_near(internal->handles[i], params,
				       				&(internal->period_size[i]), 0);
			
			if(err < 0)
				goto hw_failed;
	
			internal->cmd = "snd_pcm_hw_params_set_buffer_time_near" ;
			if (internal->buffer_time[i] > 0) {
				err = snd_pcm_hw_params_set_buffer_time_near(internal->handles[i], params,
				   				&(internal->buffer_time[i]), 0);
			} else {
				err = snd_pcm_hw_params_set_buffer_size_near(internal->handles[i], params,
					   			&(internal->buffer_size[i]));
			}
			if(err<0)
				goto hw_failed;
	
			
			/* commit the params structure to the hardware via ALSA */
			internal->cmd = "snd_pcm_hw_params";
			err = snd_pcm_hw_params(internal->handles[i], params);
			if (err < 0)
				goto hw_failed;
		
			/* save the period size in frames for posterity */
			internal->cmd = "snd_pcm_hw_get_period_size";
			err = snd_pcm_hw_params_get_period_size(params, 
								&(internal->period_size[i]), 0);
			if (err < 0)
				goto hw_failed;
		
			/* save the buffer size in frames for posterity */
			internal->cmd = "snd_pcm_hw_get_buffer_size";
			err = snd_pcm_hw_params_get_buffer_size(params, 
								&((internal->buffer_size[i])));
			if (err < 0)
				goto hw_failed;

				
			if(internal->buffer_size[i] == internal->period_size[i]){
				aio_msg(AIO_ERROR,"AIO_ALSA -> alsa_set_hw_params: cant have buffer_size = peiord_size (%lu,%lu)",internal->buffer_size[i],internal->period_size[i]);
				if(params)
					snd_pcm_hw_params_free(params);
	
				return -1;
			}
				
			/*check if the hardware supports pause */
			if (i == ALSA_PLAYBACK_STREAM_IDX){
				aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: Checking if hardware supports pause  - > ");
				internal->cmd = "snd_pcm_hw_params_can_ause";
				internal->alsa_can_pause = snd_pcm_hw_params_can_pause(params);
				aio_msg(AIO_DEBUG,"AIO_ALSA -> alsa_set_hw_params: %s", internal->alsa_can_pause ? "Yes": "No");
			}
			
			snd_pcm_hw_params_free(params);
			params = NULL;
		}
	}
	return 0;
	

hw_failed :
	if(params)
		snd_pcm_hw_params_free(params);
	aio_msg(AIO_ERROR,"AIO_ALSA -> alsa_set_hw_params: failed \"%s\" error : %s",internal->cmd,snd_strerror(err));
	return err;
}

/*
    open & setup audio device
    return: 0=success -1=fail
*/
static int init(aio_device_t *device, aio_sample_format_t *sample_format, const aio_option_t **opt, int open_mode)
{
	aio_alsa_internal_t *internal = NULL;
	
	int err = 0;
	aio_msg(AIO_DEBUG,"AIO_ALSA -> init : initializing device %s",device->funcs->driver_info()->short_name);
	
	if(device == NULL)
		return -1;
	
	
	if(device->internal == NULL) {

		internal = (aio_alsa_internal_t *) malloc(sizeof(aio_alsa_internal_t));

		if(internal == NULL)
			return -1;
		
		/* initial setup*/			
		internal->handles[ALSA_CAPTURE_STREAM_IDX]  = NULL;
		internal->handles[ALSA_PLAYBACK_STREAM_IDX] = NULL;

		internal->buffer_time[ALSA_CAPTURE_STREAM_IDX] = 0;
		internal->buffer_time[ALSA_PLAYBACK_STREAM_IDX] = 0;


		internal->period_time [ALSA_CAPTURE_STREAM_IDX] = 0;
		internal->period_time [ALSA_PLAYBACK_STREAM_IDX] = 0;


		internal->stop_delay[ALSA_PLAYBACK_STREAM_IDX]  = 0;
		internal->stop_delay[ALSA_CAPTURE_STREAM_IDX]  = 0;
		internal->avail_min[ALSA_CAPTURE_STREAM_IDX]  = -1;
		internal->avail_min[ALSA_PLAYBACK_STREAM_IDX] = -1;
		internal->start_delay[ALSA_PLAYBACK_STREAM_IDX] = 0; 
		internal->start_delay[ALSA_CAPTURE_STREAM_IDX] = 1;


		internal->writei = AIO_ALSA_WRITEI;
		internal->readi = AIO_ALSA_READI;
		internal->access_mask = AIO_ALSA_ACCESS_MASK;
		internal->pcm_open_mode = 0;
		internal->s_format.byte_format = sample_format->byte_format;
		internal->s_format.channels = sample_format->channels;
		internal->s_format.format = sample_format->format;	
		internal->s_format.samplerate = sample_format->samplerate;
		internal->open_mode = open_mode;	
		
		internal->card = NULL;
		internal->rec_src = strdup("Mic");
		
		device->internal = internal;


	}else {
		internal = (aio_alsa_internal_t *) device->internal;
	}


	/*Parse options */
	if(opt != NULL) {	
		while((*opt)){
			aio_msg(AIO_DEBUG,"AIO_ALSA -> init : setting option %s to %s",(*opt)->key,(*opt)->value);
			if(strcmp((*opt)->key,"card") == 0){
				
				internal->card = strdup((*opt)->value);

			}else if((strcmp((*opt)->key,"ibuffer_time") == 0) && (internal->open_mode & AIO_RECONLY)){
			
				internal->buffer_time[ALSA_CAPTURE_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"ibuffer_size") == 0) && (internal->open_mode & AIO_RECONLY)){
				
				internal->buffer_size[ALSA_CAPTURE_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"iperiode_time") == 0) && (internal->open_mode && AIO_RECONLY)){
				
				internal->period_time[ALSA_CAPTURE_STREAM_IDX] = atoi((*opt)->value);

			}else if((strcmp((*opt)->key,"iperiode_size") == 0) && (internal->open_mode && AIO_RECONLY)){
				
				internal->period_size[ALSA_CAPTURE_STREAM_IDX] = atoi((*opt)->value);

			}else if((strcmp((*opt)->key,"obuffer_time") == 0) && (internal->open_mode & AIO_PLAYONLY)){
				
				internal->buffer_time[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);

			}else if((strcmp((*opt)->key,"obuffer_size") == 0) && (internal->open_mode & AIO_PLAYONLY)){
				
				internal->buffer_size[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);

			}else if(((strcmp((*opt)->key,"operiod_time") == 0) && (internal->open_mode & AIO_PLAYONLY))){
			
				internal->period_time[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);
				
			}else if(((strcmp((*opt)->key,"operiod_size") == 0) && (internal->open_mode & AIO_PLAYONLY)) ){

				internal->period_size[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"iavail_min") == 0) && (internal->open_mode & AIO_RECONLY)){
				
				internal->avail_min[ALSA_CAPTURE_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"oavail_min") == 0) && (internal->open_mode & AIO_PLAYONLY)){
				
				internal->avail_min[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"ostart_delay") == 0) && (internal->open_mode & AIO_RECONLY)){
				
				internal->start_delay[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"istart_delay") == 0) && (internal->open_mode & AIO_RECONLY)){
				
				internal->start_delay[ALSA_CAPTURE_STREAM_IDX]  = atoi((*opt)->value);

			}else if((strcmp((*opt)->key,"ostop_delay") == 0) && (internal->open_mode & AIO_RECONLY)){
			
				internal->stop_delay[ALSA_PLAYBACK_STREAM_IDX] = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"istop_delay") == 0) && (internal->open_mode & AIO_RECONLY)){
				
				internal->stop_delay[ALSA_CAPTURE_STREAM_IDX]  = atoi((*opt)->value);
			
			}else if((strcmp((*opt)->key,"async") == 0)){
				if(strcmp((*opt)->value,"yes") == 0 ||
					strcmp((*opt)->value,"1") == 0 ||
					strcmp((*opt)->value,"true") == 0) {
					
					aio_msg(AIO_WARN,"AIO_ALSA -> init : async mode not supported yet ignoring");
					//internal->pcm_open_mode = SND_PCM_ASYNC;
					
				}
			}
			else if(strcmp((*opt)->key,"use_mmap") == 0){
				if(strcmp((*opt)->value,"yes") == 0 ||
					strcmp((*opt)->value,"1") == 0 ||
					strcmp((*opt)->value,"true")== 0) {
				
						internal->readi = snd_pcm_mmap_readi;
						internal->writei = snd_pcm_mmap_writei;
						internal->access_mask = SND_PCM_ACCESS_MMAP_INTERLEAVED;
					
				}else {
					internal->writei = snd_pcm_writei;
					internal->readi = snd_pcm_readi;
					internal->access_mask = SND_PCM_ACCESS_RW_INTERLEAVED;
				}

			}else if((strcmp((*opt)->key,"rec_src") == 0) && (internal->open_mode & AIO_RECONLY)){
				if(internal->rec_src)
					free(internal->rec_src);
				if(strcmp((*opt)->value,"line") == 0)
					
					internal->rec_src = strdup("Line");
				else
					internal->rec_src = strdup("Mic");

			}
			else{
				aio_msg(AIO_WARN,"AIO_ALSA -> init : invalide options %s ignoring",(*opt)->key);
			}

			opt++;
		}
	}
	

	internal->cmd = strdup("snd_pcm_open");
	/* user didn't provide a device, use the default */
	
	if(internal->card == NULL){
		aio_msg(AIO_DEBUG,"AIO_ALSA -> init : dev not set using default");
		internal->card =strdup("default");
	}
	/* if the PLAY bit is set*/
	if(internal->open_mode & AIO_RECONLY){
		
			err = snd_pcm_open(&(internal->handles[ALSA_CAPTURE_STREAM_IDX]),internal->card,SND_PCM_STREAM_CAPTURE,internal->pcm_open_mode);
			if (err < 0){
				internal->handles[ALSA_PLAYBACK_STREAM_IDX] = NULL ;
				goto init_err;
			}
					
	}
	
	/*if the REC bit is set*/
	if(internal->open_mode & AIO_PLAYONLY) {
		err = snd_pcm_open(&(internal->handles[ALSA_PLAYBACK_STREAM_IDX]),internal->card,SND_PCM_STREAM_PLAYBACK,internal->pcm_open_mode);
		if (err < 0){
			internal->handles[ALSA_CAPTURE_STREAM_IDX]= NULL ;
			goto init_err;
		}
	}

	/*if neither  error */
	if(!(internal->open_mode & AIO_RECPLAY)){	
			aio_msg(AIO_ERROR,"AIO_ALSA -> init : invalide open mode supplied");
			goto init_err;
	}
		
	
	/*set hw parameters*/
	err = alsa_set_hw_params(internal);
	if(err < 0)
		goto init_err;
	/*set sw parameters*/
	err = alsa_set_sw_params(internal);
	if(err < 0)
		goto init_err;
	
	
	if((internal->open_mode & AIO_RECONLY))
		_alsa_set_capture_source(internal,internal->rec_src);
			


			
	return 0;
init_err :	
	aio_msg(AIO_ERROR,"AIO_ALSA -> init : error initializing alsa device : %s : %s",internal->cmd,snd_strerror(err));
	int i;	
	for(i = 0 ; i < ALSA_STREAMS ; i++){
		if(internal->handles[i]!= NULL){
			snd_pcm_close(internal->handles[i]);
			internal->handles[i] = NULL;
		}
	}
	return -1;

}
static int audio_pause(aio_device_t * device)
{
	int err;
	aio_alsa_internal_t * internal = NULL ;
	
	
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_pause : called pause with uninitilized device");
		return -1;
	}
	internal = (aio_alsa_internal_t *) device->internal;
    	if(internal == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_pause : called pause with uninitilized device internal");
		return 1;
	}
	if(internal->handles[ALSA_PLAYBACK_STREAM_IDX]) {
		if (internal->alsa_can_pause) {
			if ((err = snd_pcm_pause(internal->handles[ALSA_PLAYBACK_STREAM_IDX], 1)) < 0){

				aio_msg(AIO_ERROR,"AIO_ALSA -> audio_pause:  snd_pcm_pause error :  %s", snd_strerror(err));
				return -1;
			}

		} else {

			if ((err = snd_pcm_drop(internal->handles[ALSA_PLAYBACK_STREAM_IDX])) < 0){

				aio_msg(AIO_ERROR,"AIO_ALSA audio_pause : pcm_drop error : %s", snd_strerror(err));

				return -1;
			}
		}
	}else {
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_pause : called with a non playback stream");
		return -1;
	}

	return 0;
}

static int audio_resume(aio_device_t *device)
{
	int err;
	aio_alsa_internal_t * internal = NULL ;
	
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_resume : called pause with uninitilized device");
		return -1;
	}
	
	internal = (aio_alsa_internal_t *) device->internal;
    	
	if(internal == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_resume :  called pause with uninitilized device internal");
		return -1;
	}
	if(internal->handles[ALSA_PLAYBACK_STREAM_IDX]) {

	
		if (internal->alsa_can_pause) {
			if ((err = snd_pcm_pause(internal->handles[ALSA_PLAYBACK_STREAM_IDX], 0)) < 0){

				aio_msg(AIO_ERROR,"AIO_ALSA -> audio_resume : snd_pcm_pause error : %s", snd_strerror(err));

				return -1;
			}
		} else {

			if ((err = snd_pcm_prepare(internal->handles[ALSA_PLAYBACK_STREAM_IDX])) < 0){
				aio_msg(AIO_ERROR,"AIO_ALSA -> audio_resume : snd_pcm_prepare error : %s", snd_strerror(err));
				return -1;
			}
		}
	}else {
		aio_msg(AIO_ERROR,"AIO_ALSA -> audio_resume : called with a non playback stream");
		return -1;
	}


	return 0;
}
int _alsa_close(aio_alsa_internal_t *internal, int immed){
	int i;	
	
	if(internal == NULL){
		return -1;
	}
	for(i  = 0 ; i < ALSA_STREAMS; i++){
		if(internal->handles[i] != NULL ){

			if (immed && (i == ALSA_PLAYBACK_STREAM_IDX))
				/*if imm drop and rest the device*/
				snd_pcm_drain(internal->handles[i]);
			else {
				/*otherwise wait for the playback to finish*/
				snd_pcm_drop(internal->handles[i]);
			}
			
			snd_pcm_close(internal->handles[i]);
			internal->handles[i] = NULL;
		}
	}
	return 0;

}
/* close unint the audio device  */
static int uninit(aio_device_t *device,int immed)
{
	aio_alsa_internal_t * internal = NULL;

	if(device == NULL) {
		aio_msg(AIO_ERROR,"AIO_ALSA -> uninit : called with an uninitilized device");
		return -1 ;
	}
	internal = (aio_alsa_internal_t*) device->internal;

	if(internal == NULL) {
		aio_msg(AIO_ERROR,"AIO_ALSA -> uninit : called with an uninitilized device internal");
		return -1;
	}
	_alsa_close(internal,immed);
	if(internal->card)
		free(internal->card);
	if(internal->rec_src)
		free(internal->rec_src);
	free(internal);

	return 0;
}


/* stop playing and empty buffers (for seeking/pause) */
static int  reset(aio_device_t * device )
{
	aio_alsa_internal_t *internal = NULL ;
	
	int err  = 0;
	
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> reset : called  with an uninitlized device");
		return -1;
	}

	
	internal = (aio_alsa_internal_t *)device->internal;
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> reset : called  with an uninitlized device internal");
		return -1;
	}
	
	_alsa_close(internal,1);

	if((err = init(device,NULL,NULL,internal->open_mode))<0){
		aio_msg(AIO_ERROR,"AIO_ALSA -> reset : could not reinit the device");
	}
	return err;
}

	


static inline int alsa_error_recovery( snd_pcm_t *handle, int err,char *dir){

	if (err == -EPIPE) {    /* under-run */
		aio_msg(AIO_WARN,"AIO_ALSA recovery recovery for %s",dir);
		err = snd_pcm_prepare(handle);
		if (err < 0)
			aio_msg(AIO_ERROR,"AIO_ALSA -> alsa_error_ recovery : Can't recovery from underrun, prepare failed: %s", snd_strerror(err));
		return 0;
	}else if (err == -ESTRPIPE) {
		aio_msg(AIO_WARN,"AIO_ALSA recovery ESTR");
		while ((err = snd_pcm_resume(handle)) == -EAGAIN)
			sleep(1);       /* wait until the suspend flag is released */
		if (err < 0) {
			err = snd_pcm_prepare(handle);
			if (err < 0)
				aio_msg(AIO_ERROR,"AIO_ALSA -> alsa_error_recovery: Can't recovery from suspend, prepare failed: %s", snd_strerror(err));
		}
		
		return 0;
	}
	return err;
}
/*
    plays 'len' bytes of 'data'
    returns: number of bytes played
    modified last at 29.06.02 by jp
    thanxs for marius <marius@rospot.com> for giving us the light ;)
*/

static int play(aio_device_t * device, int8_t *data, size_t len, int flags){

	aio_alsa_internal_t * internal ;

  	int  count;
	int err=0, played = 0;
	int8_t *ptr = data;

	if(device == NULL) {
		aio_msg(AIO_ERROR,"AIO_ALSA -> play : called play with uninitialized device");
		return -1 ;
	}

	internal = device->internal;
	if(internal == NULL) {
		aio_msg(AIO_ERROR,"AIO_ALSA -> play : called play with uninitialized device");
		return -1 ;
	}
	if(internal->handles[ALSA_PLAYBACK_STREAM_IDX] == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> play : called play with uninitialized handle (maybe the device is opened for recording only");
		return -1;
	}	
	count  = len / internal->s_format.bytes_per_sample;

		

	while(count > 0 ) {	
		/*try to write the entire buffer at once*/
		err = internal->writei(internal->handles[ALSA_PLAYBACK_STREAM_IDX] , ptr, count);
		if(err == -EAGAIN || err == -EINTR) {
			continue;

		}
		if(err < 0){
			err = alsa_error_recovery(internal->handles[ALSA_PLAYBACK_STREAM_IDX] ,err,"output");
			if(err < 0){
				aio_msg(AIO_ERROR,"AIO_ALSA -> play : ALSA write error : %s",snd_strerror(err));
				return -1;
			}
			/*abandon the rest of the buffer*/
			//break;
		}

		played += err;
		ptr += err * internal->s_format.bytes_per_sample;
		count  -= err;
	}
  	return played * internal->s_format.bytes_per_sample;
}
static int  record(aio_device_t *device, int8_t * buffer, size_t len, int flags ){

	aio_alsa_internal_t *internal = (aio_alsa_internal_t *) device->internal;
	int count =  len / internal->s_format.bytes_per_sample;
	int8_t * buff = buffer;
	int r;
	int result = 0;
	if(internal->handles[ALSA_CAPTURE_STREAM_IDX]  == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> record : called record with uninitialized handle (maybe the device is opened for playback only");
		return -1;
	}
	if (count != internal->period_size[ALSA_CAPTURE_STREAM_IDX] )
		count = internal->period_size[ALSA_CAPTURE_STREAM_IDX] ;
	while(count > 0){
		r = internal->readi(internal->handles[ALSA_CAPTURE_STREAM_IDX] , buff,count);
		if(r  == -EAGAIN || (r >= 0 && (size_t)r < count)){
			snd_pcm_wait(internal->handles[ALSA_CAPTURE_STREAM_IDX] , 1000);
		}
		if(r < 0){
			r = alsa_error_recovery(internal->handles[ALSA_CAPTURE_STREAM_IDX] ,r,"input");
		}

		if(r >0)
			count -= r;
			buff += r * internal->s_format.bytes_per_sample;
			result += r;
	}
	result *= internal->s_format.bytes_per_sample;
	return result;
}
/* how many byes are free in the buffer */
static int get_space(aio_device_t * device,int dir)

{
	aio_alsa_internal_t * internal = NULL;
	snd_pcm_status_t *status;
	int ret;
	int buf_size;
	char *str_dir = NULL;
	snd_pcm_t *handle = NULL;
	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> get_space : called with an uninitliazed device structure");
		return -1;
	}
	internal = (aio_alsa_internal_t *)device->internal ;

	if(internal == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> get_space : called with an uninitiliazed device internal structure");
		return -1;

	}
	switch(dir) {
	case AIO_SPACE_IN:
		handle = internal->handles[ALSA_CAPTURE_STREAM_IDX];;
		str_dir =strdup("input");
		buf_size = internal->buffer_size[ALSA_CAPTURE_STREAM_IDX];
		break;
	case AIO_SPACE_OUT:
		str_dir = strdup("output");
		buf_size = internal->buffer_size[ALSA_PLAYBACK_STREAM_IDX];
		handle = internal->handles[ALSA_PLAYBACK_STREAM_IDX];
		break;
	default:
		return -1;
		
	}
	if(handle == NULL)
		return -1;
    	snd_pcm_status_alloca(&status);
    
    	if ((ret = snd_pcm_status(handle, status)) < 0) {
		aio_msg(AIO_ERROR,"AIO_ALASA -> get_space : can not get PcmStatus %s", snd_strerror(ret));
		return -1;
	}
    
    	ret = snd_pcm_status_get_avail(status) * internal->s_format.bytes_per_sample;
	aio_msg(AIO_DEBUG,"AIO_ALSA -> get_space availabale space for %s is %d",str_dir,ret);
	
	if(str_dir)
		free(str_dir);
	return(ret);
}

/* delay in seconds between first and last sample in buffer */
static float get_delay(aio_device_t *device)
{
	aio_alsa_internal_t * internal = NULL;

	if(device == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> get_space : called with an uninitliazed device structure");

		return -1;
	}
	internal = (aio_alsa_internal_t *)device->internal;

	if(internal == NULL){
		aio_msg(AIO_ERROR,"AIO_ALSA -> get_space : called with an uninitiliazed device internal structure");

		return -1;
	}
	
  	if (internal->handles[ALSA_PLAYBACK_STREAM_IDX]) {
    		snd_pcm_sframes_t delay;
    
		if (snd_pcm_delay(internal->handles[ALSA_PLAYBACK_STREAM_IDX], &delay) < 0)
			return 0;
    
		if (delay < 0) {
			/* underrun - move the application pointer forward to catch up */
			snd_pcm_forward(internal->handles[ALSA_PLAYBACK_STREAM_IDX], -delay);
			delay = 0;
		}

		snd_pcm_avail_update(internal->handles[ALSA_PLAYBACK_STREAM_IDX]);

		return (float)delay / (float)internal->s_format.samplerate;
	} else {
			return(-1);
	}


}



static aio_info_t * driver_info(void) {

	return &info;
}
LIBAIO_EXTERN_DYNAMIC()
