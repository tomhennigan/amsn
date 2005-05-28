#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>

#define ALSA_PCM_NEW_HW_PARAMS_API
#define ALSA_PCM_NEW_SW_PARAMS_API
#include <alsa/asoundlib.h>

#include "grab-ng.h"

/* -------------------------------------------------------------------- */

static const char silence[4*1024];

struct alsa_handle {
    char                 *device;
    snd_pcm_stream_t     stream;

    snd_pcm_t            *pcm;
    snd_pcm_hw_params_t  *hwparams;
    snd_pcm_sw_params_t  *swparams;

    unsigned int         btime, ptime, rate, fmtid, mul;
    snd_pcm_sframes_t    bsize;
    snd_pcm_sframes_t    psize;
};

static int
ng_alsa_fd(void *handle)
{
    struct alsa_handle *h = handle;
    struct pollfd ufd;
    int count;

    count = snd_pcm_poll_descriptors_count(h->pcm);
    BUG_ON(count != 1, "#fd != 1 -- can't handle that");
    snd_pcm_poll_descriptors(h->pcm, &ufd, count);
    return ufd.fd;
}

static int
ng_alsa_open(void *handle)
{
    struct alsa_handle *h = handle;
    int err, fd;

    if (ng_debug)
	fprintf(stderr,"alsa: open\n");
    BUG_ON(h->pcm,"stream already open");
    err = snd_pcm_open(&h->pcm, h->device, h->stream, SND_PCM_NONBLOCK);
    if (err < 0) {
	fprintf(stderr, "alsa: open %s: %s\n", h->device, snd_strerror(err));
	return -1;
    }
    snd_pcm_hw_params_malloc(&h->hwparams);
    snd_pcm_sw_params_malloc(&h->swparams);
    fd = ng_alsa_fd(handle);
    fcntl(fd,F_SETFD,FD_CLOEXEC);
    return 0;
}

static int
ng_alsa_close(void *handle)
{
    struct alsa_handle *h = handle;

    if (ng_debug)
	fprintf(stderr,"alsa: close\n");
    BUG_ON(!h->pcm,"stream not open");
    snd_pcm_close(h->pcm);
    h->pcm = 0;
    snd_pcm_hw_params_free(h->hwparams);
    h->hwparams = 0;
    snd_pcm_sw_params_free(h->swparams);
    h->swparams = 0;
    return 0;
}

static void*
ng_alsa_init(char *device, int record)
{
    struct alsa_handle *h;

    if (device && 0 == strncmp(device,"/dev/",5))
	return NULL;
    if (record)
	return NULL;

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));

    h->device = strdup(device ? device : "plughw");
    h->stream = record ? SND_PCM_STREAM_CAPTURE : SND_PCM_STREAM_PLAYBACK;
    if (ng_debug)
	fprintf(stderr,"alsa: init dev=\"%s\" record=%s\n",
		h->device, record ? "yes" : "no");
    if (0 != ng_alsa_open(h)) {
	free(h->device);
	free(h);
	return NULL;
    }
    ng_alsa_close(h);
    return h;
}

static int
ng_alsa_fini(void *handle)
{
    struct alsa_handle *h = handle;

    if (ng_debug)
	fprintf(stderr,"alsa: fini\n");
    BUG_ON(h->pcm,"stream still open");
    free(h->device);
    free(h);
    return 0;
}

static char*
ng_alsa_devname(void *handle)
{
    struct alsa_handle *h = handle;

    return h->device;
}

/* -------------------------------------------------------------------- */

static const snd_pcm_format_t afmt_to_alsa[AUDIO_FMT_COUNT] = {
    0,
    SND_PCM_FORMAT_U8,
    SND_PCM_FORMAT_U8,
    SND_PCM_FORMAT_S16_LE,
    SND_PCM_FORMAT_S16_LE,
    SND_PCM_FORMAT_S16_BE,
    SND_PCM_FORMAT_S16_BE
};

static int
ng_alsa_setformat(void *handle, struct ng_audio_fmt *fmt)
{
    int err, dir;
    char *fun;
    struct alsa_handle *h = handle;

    BUG_ON(!h->pcm,"stream not open");

    if (0 == ng_afmt_to_bits[fmt->fmtid])
	/* some invalid or compressed format */
	return -1;
    if (0 == afmt_to_alsa[fmt->fmtid])
	return -1;

    h->rate  = fmt->rate;
    h->fmtid = fmt->fmtid;
    h->mul   = ng_afmt_to_channels[fmt->fmtid] *
	ng_afmt_to_bits[fmt->fmtid] / 8;
    h->btime = 500000; /* 0.50 sec */
    h->ptime =  30000; /* 0.03 sec */
    if (ng_debug)
	fprintf(stderr,"alsa: setformat %s @ %d\n",
		ng_afmt_to_desc[fmt->fmtid], fmt->rate);
    
    /* choose all parameters */
    fun = "snd_pcm_hw_params_any";
    err = snd_pcm_hw_params_any(h->pcm, h->hwparams);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_set_access";
    err = snd_pcm_hw_params_set_access(h->pcm, h->hwparams,
				       SND_PCM_ACCESS_RW_INTERLEAVED);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_set_format";
    err = snd_pcm_hw_params_set_format(h->pcm, h->hwparams,
				       afmt_to_alsa[fmt->fmtid]);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_set_channels";
    err = snd_pcm_hw_params_set_channels(h->pcm, h->hwparams,
					 ng_afmt_to_channels[fmt->fmtid]);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_set_rate_near";
    err = snd_pcm_hw_params_set_rate_near(h->pcm, h->hwparams, &h->rate, 0);
    if (err < 0)
	goto oops;

    if (h->rate != fmt->rate) {
	fprintf(stderr, "alsa: warning: got sample rate %d (asked for %d)\n",
		h->rate, fmt->rate);
	if (h->rate < fmt->rate * 1001 / 1000 &&
	    h->rate > fmt->rate *  999 / 1000) {
	    /* ignore very small differences ... */
	    h->rate = fmt->rate;
	}
    }

    fun = "snd_pcm_hw_params_set_buffer_time_near";
    err = snd_pcm_hw_params_set_buffer_time_near(h->pcm, h->hwparams,
						 &h->btime, &dir);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_get_buffer_size";
    err = snd_pcm_hw_params_get_buffer_size(h->hwparams, &h->bsize);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_set_period_time_near";
    err = snd_pcm_hw_params_set_period_time_near(h->pcm, h->hwparams, &h->ptime, &dir);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params_get_period_size";
    err = snd_pcm_hw_params_get_period_size(h->hwparams, &h->psize, &dir);
    if (err < 0)
	goto oops;

    fun = "snd_pcm_hw_params";
    err = snd_pcm_hw_params(h->pcm, h->hwparams);
    if (err < 0)
	goto oops;


    /* get the current swparams */
    fun = "snd_pcm_sw_params_current";
    err = snd_pcm_sw_params_current(h->pcm, h->swparams);
    if (err < 0)
	goto oops;

    /* start the transfer when the buffer is close to full */
    fun = "snd_pcm_sw_params_set_start_threshold";
    err = snd_pcm_sw_params_set_start_threshold(h->pcm, h->swparams,
						h->bsize - h->psize);
    if (err < 0)
	goto oops;

    /* allow the transfer when at least period_size samples can be processed */
    fun = "snd_pcm_sw_params_set_avail_min";
    err = snd_pcm_sw_params_set_avail_min(h->pcm, h->swparams, h->psize);
    if (err < 0)
	goto oops;

#if 0
    /* explicit starts */
    fun = "snd_pcm_sw_params_set_start_mode";
    err = snd_pcm_sw_params_set_start_mode(h->pcm, h->swparams,
					   SND_PCM_START_EXPLICIT);
    if (err < 0)
	goto oops;
#endif

    fun = "snd_pcm_sw_params";
    err = snd_pcm_sw_params(h->pcm, h->swparams);
    if (err < 0)
	goto oops;

    if (ng_debug)
	fprintf(stderr,"alsa: setformat: rate=%d btime=%d buf=%ld/%ld\n",
		h->rate, h->btime, h->psize, h->bsize);
    fmt->rate = h->rate;
    return 0;

 oops:
    fprintf(stderr,"alsa: %s: %s\n", fun, snd_strerror(err));
    return -1;
}

static int
ng_alsa_startplay(void *handle)
{
    struct alsa_handle *h = handle;

    if (ng_debug)
	fprintf(stderr,"alsa: startplay\n");
    BUG_ON(!h->pcm,"stream not open");
    return 0;
}

static struct ng_audio_buf*
ng_alsa_write(void *handle, struct ng_audio_buf *buf)
{
    struct alsa_handle *h = handle;
    int rc, restart = 0;

    BUG_ON(!h->pcm,"stream not open");

    if (buf->info.slowdown) {
	if (ng_log_resync)
	    fprintf(stderr,"alsa: sync: slowdown hack\n");
	snd_pcm_writei(h->pcm, silence, sizeof(silence) / h->mul);
	buf->info.slowdown = 0;
	return buf;
    }

 again:
    rc = snd_pcm_writei(h->pcm, buf->data + buf->written,
			(buf->size - buf->written) / h->mul);
    if ((-EPIPE == rc || -ESTRPIPE == rc) && !restart) {
	if (ng_log_resync)
	    fprintf(stderr,"alsa: write: buffer underun, restarting playback ...\n");
	snd_pcm_prepare(h->pcm);
	restart = 1;
	goto again;
    }

    if (0 == rc) {
	if (ng_debug)
	    fprintf(stderr,"alsa: write: Huh? no data written?\n");
	ng_free_audio_buf(buf);
	buf = NULL;
    } else if (rc < 0) {
	fprintf(stderr,"alsa: write: %s (rc=%d)\n", snd_strerror(rc), rc);
	ng_free_audio_buf(buf);
	buf = NULL;
    } else {
	buf->written += rc * h->mul;
	if (buf->written == buf->size) {
	    ng_free_audio_buf(buf);
	    buf = NULL;
	}
    }
    return buf;
}

static int64_t
ng_alsa_latency(void *handle)
{
    struct alsa_handle *h = handle;
    uint64_t latency = 0;

    BUG_ON(!h->pcm,"stream not open");
    latency  = h->btime;
    latency *= 1000;
    return latency;
}

static struct ng_devinfo* ng_alsa_probe(int record, int verbose)
{
    snd_ctl_t            *ctl;
    snd_ctl_card_info_t  *cardinfo;
    snd_pcm_info_t       *pcminfo;
    char                 name[32];
    struct ng_devinfo    *info = NULL;
    int                  card, dev, n, err;

    if (record)
	return NULL;

    snd_ctl_card_info_alloca(&cardinfo);
    snd_pcm_info_alloca(&pcminfo);

    n = 0;
    for (card = -1;;) {
	snd_card_next(&card);
	if (card < 0)
	    break;
	sprintf(name,"hw:%d",card);
	if (0 != (err = snd_ctl_open(&ctl,name,SND_CTL_NONBLOCK))) {
	    if (verbose)
		fprintf(stderr,"alsa: [%s]: %s\n", name, snd_strerror(err));
	    continue;
	}
	snd_ctl_card_info(ctl,cardinfo);
	for (dev = -1;;) {
	    snd_ctl_pcm_next_device(ctl, &dev);
	    if (dev < 0)
		break;
	    snd_pcm_info_set_device(pcminfo, dev);
	    snd_pcm_info_set_subdevice(pcminfo, 0);
	    snd_pcm_info_set_stream(pcminfo, record
				    ? SND_PCM_STREAM_CAPTURE
				    : SND_PCM_STREAM_PLAYBACK);
	    if (0 != snd_ctl_pcm_info(ctl, pcminfo))
		continue;

	    info = realloc(info,sizeof(*info) * (n+2));
	    memset(info+n,0,sizeof(*info)*2);
	    snprintf(info[n].device, sizeof(info[n].device), "plughw:%s,%d",
		     snd_ctl_card_info_get_id(cardinfo), dev);
	    snprintf(info[n].name, sizeof(info[n].name), "%s / %s",
		     snd_ctl_card_info_get_name(cardinfo),
		     snd_pcm_info_get_name(pcminfo));
	    n++;
	}
	snd_ctl_close(ctl);
    }
    return info;
}

/* ------------------------------------------------------------------- */

static int mixer_read_attr(struct ng_attribute *attr);
static void mixer_write_attr(struct ng_attribute *attr, int val);

struct mixer_handle {
    char                 *device;
    snd_mixer_t          *mixer;
    snd_mixer_elem_t     *elem;
    struct ng_attribute  *attrs;
};

static struct ng_attribute mixer_attrs[] = {
    {
	.id       = ATTR_ID_MUTE,
	.name     = "mute",
	.priority = 1,
	.type     = ATTR_TYPE_BOOL,
	.read     = mixer_read_attr,
	.write    = mixer_write_attr,
    },{
	.id       = ATTR_ID_VOLUME,
	.name     = "volume",
	.priority = 1,
	.type     = ATTR_TYPE_INTEGER,
	.min      = 0,
	.max      = 100,
	.read     = mixer_read_attr,
	.write    = mixer_write_attr,
    },{
	/* end of list */
    }
};

static struct ng_devinfo* mixer_probe(int verbose)
{
    snd_ctl_t            *ctl;
    snd_ctl_card_info_t  *cardinfo;
    char                 name[32];
    struct ng_devinfo    *info = NULL;
    int                  card, n, err;

    snd_ctl_card_info_alloca(&cardinfo);

    n = 0;
    for (card = -1;;) {
	snd_card_next(&card);
	if (card < 0)
	    break;
	sprintf(name,"hw:%d",card);
	if (0 != (err = snd_ctl_open(&ctl,name,SND_CTL_NONBLOCK))) {
	    if (verbose)
		fprintf(stderr,"alsa: [%s]: %s\n", name, snd_strerror(err));
	    continue;
	}
	snd_ctl_card_info(ctl,cardinfo);

	info = realloc(info,sizeof(*info) * (n+2));
	memset(info+n,0,sizeof(*info)*2);
	snprintf(info[n].device, sizeof(info[n].device), "hw:%s",
		 snd_ctl_card_info_get_id(cardinfo));
	snprintf(info[n].name, sizeof(info[n].name), "%s / %s",
		 snd_ctl_card_info_get_name(cardinfo),
		 snd_ctl_card_info_get_mixername(cardinfo));
	n++;

	snd_ctl_close(ctl);
    }
    return info;
}

static struct ng_devinfo*
mixer_channels(char *device)
{
    snd_mixer_t          *mixer = NULL;
    snd_mixer_elem_t     *elem;
    snd_mixer_selem_id_t *sid;
    struct ng_devinfo    *info = NULL;
    int                  n;

    snd_mixer_selem_id_alloca(&sid);
    
    if (0 != snd_mixer_open(&mixer,0))
	goto err;
    if (0 != snd_mixer_attach(mixer, device))
	goto err;
    if (0 != snd_mixer_selem_register(mixer, NULL, NULL))
	goto err;
    if (0 != snd_mixer_load(mixer))
	goto err;

    n = 0;
    for (elem = snd_mixer_first_elem(mixer); NULL != elem;
	 elem = snd_mixer_elem_next(elem)) {
	if (!snd_mixer_selem_is_active(elem))
	    continue;
	if (snd_mixer_selem_is_enumerated(elem))
	    continue;
	if (!snd_mixer_selem_has_playback_volume(elem) &&
	    !snd_mixer_selem_has_capture_volume(elem))
	    continue;

	snd_mixer_selem_get_id(elem,sid);
	info = realloc(info,sizeof(*info) * (n+2));
	memset(info+n,0,sizeof(*info)*2);
	snprintf(info[n].device, sizeof(info[n].device), "%s",
		 snd_mixer_selem_id_get_name(sid));
	snprintf(info[n].name, sizeof(info[n].name), "%s [%s%s]",
		 snd_mixer_selem_id_get_name(sid),
		 snd_mixer_selem_has_playback_volume(elem) ? "play" : "",
		 snd_mixer_selem_has_capture_volume(elem)  ? "rec"  : "");
	n++;
    }
    
    return info;

 err:
    if (mixer)
	snd_mixer_close(mixer);
    return NULL;
}

static void*
mixer_init(char *device, char *control)
{
    struct mixer_handle *h;
    snd_mixer_selem_id_t *sid;
    int i,c;

    if (device && 0 == strncmp(device,"/dev/",5))
	return NULL;
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->device = strdup(device ? device : "hw");

    snd_mixer_selem_id_alloca(&sid);

    if (0 != snd_mixer_open(&h->mixer,0))
	goto err;
    if (0 != snd_mixer_attach(h->mixer, h->device))
	goto err;
    if (0 != snd_mixer_selem_register(h->mixer, NULL, NULL))
	goto err;
    if (0 != snd_mixer_load(h->mixer))
	goto err;

    c = atoi(control);
    for (h->elem = snd_mixer_first_elem(h->mixer); NULL != h->elem;
	 h->elem = snd_mixer_elem_next(h->elem)) {
	if (!snd_mixer_selem_is_active(h->elem))
	    continue;
	if (snd_mixer_selem_is_enumerated(h->elem))
	    continue;
	if (!snd_mixer_selem_has_playback_volume(h->elem) &&
	    !snd_mixer_selem_has_capture_volume(h->elem))
	    continue;

	snd_mixer_selem_get_id(h->elem,sid);
	if (0 == strcasecmp(snd_mixer_selem_id_get_name(sid),control))
	    break;
    }
    if (NULL == h->elem)
	goto err;

    h->attrs = malloc(sizeof(mixer_attrs));
    memcpy(h->attrs,mixer_attrs,sizeof(mixer_attrs));
    for (i = 0; h->attrs[i].name != NULL; i++) {
	h->attrs[i].handle = h;
	if (h->attrs[i].id == ATTR_ID_VOLUME) {
	    long min,max;
	    snd_mixer_selem_get_playback_volume_range(h->elem, 
						      &min,&max);
	    h->attrs[i].min = min;
	    h->attrs[i].max = max;
	}
    }
    return h;

 err:
    if (h->mixer)
	snd_mixer_close(h->mixer);
    free(h->device);
    free(h);
    return NULL;
}

static int
mixer_fini(void *handle)
{
    struct mixer_handle *h = handle;

    snd_mixer_close(h->mixer);
    free(h->device);
    free(h);
    return 0;
}

static int
mixer_read_attr(struct ng_attribute *attr)
{
    struct mixer_handle *h = attr->handle;
    long vol;
    int enabled;

    switch (attr->id) {
    case ATTR_ID_VOLUME:
	snd_mixer_selem_get_playback_volume(h->elem, SND_MIXER_SCHN_MONO, &vol);
	return vol;
    case ATTR_ID_MUTE:
	snd_mixer_selem_get_playback_switch(h->elem, SND_MIXER_SCHN_MONO, &enabled);
	return !enabled;
    default:
	return -1;
    }
}

static void
mixer_write_attr(struct ng_attribute *attr, int val)
{
    struct mixer_handle *h = attr->handle;

    switch (attr->id) {
    case ATTR_ID_VOLUME:
	snd_mixer_selem_set_playback_volume_all(h->elem, val);
	break;
    case ATTR_ID_MUTE:
	snd_mixer_selem_set_playback_switch_all(h->elem, !val);
	break;
    }
}

static int mixer_open(void *handle)
{
    return 0;
}

static int mixer_close(void *handle)
{
    return 0;
}

static char*
mixer_devname(void *handle)
{
    struct mixer_handle *h = handle;

    return h->device;
}

static struct ng_attribute* mixer_list_attrs(void *handle)
{
    struct mixer_handle *h = handle;
    
    return h->attrs;
}

struct ng_mix_driver alsa_mixer = {
    .name       = "alsa",
    .priority   = 2,

    .probe      = mixer_probe,
    .channels   = mixer_channels,
    .init       = mixer_init,
    .open       = mixer_open,
    .close      = mixer_close,
    .fini       = mixer_fini,
    .devname    = mixer_devname,
    .list_attrs = mixer_list_attrs,
};

static struct ng_dsp_driver alsa_dsp = {
    .name      = "alsa",
    .priority  = 2,

    .probe     = ng_alsa_probe,
    .init      = ng_alsa_init,
    .open      = ng_alsa_open,
    .close     = ng_alsa_close,
    .fini      = ng_alsa_fini,
    .devname   = ng_alsa_devname,
    
    .fd        = ng_alsa_fd,
    .setformat = ng_alsa_setformat,
    .startplay = ng_alsa_startplay,
    .write     = ng_alsa_write,
    .latency   = ng_alsa_latency,
};

/* ------------------------------------------------------------------- */

static void __init plugin_init(void)
{
    ng_dsp_driver_register(NG_PLUGIN_MAGIC,__FILE__,&alsa_dsp);
    ng_mix_driver_register(NG_PLUGIN_MAGIC,__FILE__,&alsa_mixer);
}
