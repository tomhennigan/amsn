/**
 * \file src/aio.c
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdarg.h>
#include "config.h"
#include <sys/types.h>
#include <sys/stat.h>


#ifndef _MSC_VER
#include <unistd.h>
#endif
#include <dirent.h>


#include "aio/aio.h"
#include "config.h"


#if defined HAVE_DLFCN_H && defined HAVE_DLOPEN
#include <dlfcn.h>
#else
static void *dlopen(const char *filename,int flag){return 0;}
static char *dlerror(void){return "dlopen: unsupported";}
static void *dlsym(void *handle, const char *symbol) { return 0; }
static int dlclose(void *handle) { return 0; }
/**\cond dummy*/
#undef DLOPEN_FLAG
#define DLOPEN_FLAG 0
#undef DLOPEN_FLAG
#define DLOPEN_FLAG 0
#endif
/**\endcond*/


/* 
  OpenBSD systems with a.out binaries require dlsym()ed symbols to be
  prepended with an underscore, so we need the following nasty #ifdef
  hack.
*/

#if defined(__OpenBSD__) && !defined(__ELF__)
#define dlsym(h,s) dlsym(h, "_" s)
#endif

/* RTLD_NOW is the preferred symbol resolution behavior, but
 * some platforms do not support it.  The autoconf script will have
 * already defined DLOPEN_FLAG if the default is unacceptable on the
 * current platform.
 *
 * ALSA requires RTLD_GLOBAL.
 */
#if !defined(DLOPEN_FLAG)
#define DLOPEN_FLAG (RTLD_NOW | RTLD_GLOBAL)
#endif
/** \cond dummy */
/* These should have been set by the Makefile */
#ifndef AO_PLUGIN_PATH
#define AO_PLUGIN_PATH "/usr/local/lib/aio"
#endif
#ifndef SHARED_LIB_EXT
#define SHARED_LIB_EXT ".so"
#endif


/**\endcond*/
/* --- Other constants --- */
/** defaul swap buffer size)*/
#define DEF_SWAP_BUF_SIZE  1024


/* Internal functions */

/*gets a driver from it's id*/
static driver_list *_get_driver(int driver_id);

/*gathers the table of info for all the avail plugins*/
static aio_info_t ** _make_info_table( driver_list **, int *);

/*creats a device structure*/
static aio_device_t* _create_device(int driver_id, driver_list *driver, aio_sample_format_t *format);
/* helper function to convert a byte_format of AO_FMT_NATIVE to the
   actual byte format of the machine, otherwise just return
   byte_format */
static int _real_byte_format(int byte_format);

/*compare function for qsort*/
static int _compar_driver_priority ( const void *a, const void *b);

/* Load a plugin from disk and put the function table into a driver_list struct. */
static driver_list *_get_plugin(char *plugin_file);

/* Convert the static drivers table into a linked list of drivers. */

static driver_list* _load_static_drivers(driver_list **end); 

/*finds the default driver id provided a preferred drivers list or pick the first in the list */
static int _find_default_driver_id(char ** prefs);

/*appends the dynamic plugins found in dir "*path" to the already prepared drivers list*/
static void _append_dynamic_drivers_dir(driver_list *driver, char *path);

/*appends the default plugin path to the slite of drivers*/
static void _append_dynamic_drivers(driver_list *end);

/*--------------------------------------------------------------*/




/*Global variables*/

/**
 * \addtogroup Log
 * \{*/


/** Verbosity of aio_msg defaults to errors.\n 
 * To set just declare it a an extern var and set it to any of (#AIO_VERBOSITY_DEBUG, #AIO_VERBOSITY_WARN, #AIO_VERBOSITY_ERROR,#AIO_VERBOSITY_NONE)*/
int aio_verbosity = AIO_VERBOSITY_ERROR;

/**\}*/

/** \cond static drivers list declared as extern as each is declared in it's source file */

extern aio_functions_t audio_null;

const aio_functions_t* static_audio_drivers[] =
{
        &audio_null,
	NULL
};



/*The list of  drivers we have*/
static driver_list *driver_head = NULL;
/*array containing the information on loaded drivers */
static aio_info_t **info_table = NULL;
/*the number of drivers we have*/
static int driver_count = 0;

/**\endcond*/






/* Load a plugin from disk and put the function table into a driver_list
   struct. */
static driver_list *_get_plugin(char *plugin_file)
{
	driver_list *dt;
	void *handle;

	/*clear errors*/
	dlerror();


	handle = dlopen(plugin_file, DLOPEN_FLAG);

	if (handle) {
		dt = (driver_list *)malloc(sizeof(driver_list));
		if (!dt) return NULL;

		dt->handle = handle;
		

		dt->functions = dlsym(dt->handle,"audio_driver");
		if(!dt->functions) 
			goto failed; 
		/* Make sure not to have any duplicate */
		if (aio_driver_id(dt->functions->driver_info()->short_name) != -1)
		  goto failed;
	} else {
		return NULL;
	}

	return dt;
 failed:
 	if(aio_driver_id(dt->functions->driver_info()->short_name) != -1){
		aio_msg(AIO_ERROR,"error loading dynamic driver : a driver already loaded with the same name");
	}else {

 		aio_msg(AIO_ERROR,"error loading dynamic driver dlerror() : %s", dlerror());
	}
	free(dt->functions);
	free(dt);
	return NULL;
}




/* compare function for qsort*/
static int _compar_driver_priority ( const void *a, const void *b){

      	const driver_list **driver1 = (const driver_list **) a;
	const driver_list **driver2 = (const driver_list **) b;
	int ret;
	ret = memcmp(&((*driver2)->functions->driver_info()->priority),
			&((*driver1)->functions->driver_info()->priority),
			sizeof(int));
	return ret;
}

/*gathers the tables of info about evvery avail plugin*/
static aio_info_t ** _make_info_table (driver_list ** head, int *driver_count){

	driver_list *list;
	int i;
	aio_info_t **table;

	driver_list **drivers_table;
	*driver_count = 0;

	list = *head;

	/* count drivers */

	i = 0;
	while (list != NULL){
		i++;
		list = list->next;
	}
	
	/* Sort driver_list*/
	drivers_table = (driver_list **) calloc(i,sizeof(driver_list*));
	if(drivers_table == NULL)
		return NULL;

	list = *head;
	*driver_count = i;
	
	for(i = 0; i<*driver_count; i++,list = list->next)
		drivers_table[i] = list;
	qsort(drivers_table,i,sizeof(driver_list*), (__compar_fn_t)_compar_driver_priority);
	*head = drivers_table[0];
	for(i = 1; i < *driver_count; i++)
		drivers_table[i-1]->next = drivers_table[i];
	drivers_table[i-1]->next = NULL;
	
	table = (aio_info_t ** ) calloc(i, sizeof(aio_info_t *));

	if(table != NULL) {
		for(i = 0; i < *driver_count; i++)
			table[i] =  drivers_table[i]->functions->driver_info();

	}
	free(drivers_table);
	return table;
}

/* Convert the static drivers table into a linked list of drivers. */

static driver_list* _load_static_drivers(driver_list **end) {
	
	driver_list *head;
	driver_list *driver;
	int i;
	/*insert first driver*/

	head = driver = malloc(sizeof(driver_list));
	if(driver != NULL){
		driver->functions = static_audio_drivers[0];
		driver->handle = NULL;
		driver->next = NULL;
		
		i = 1;
		while(static_audio_drivers[i] != NULL){
			driver->next = malloc(sizeof(driver_list));
			if(driver->next == NULL)
				break;
			driver->next->functions = static_audio_drivers[i];
			driver->next->handle = NULL;
			driver = driver->next;
			i++;
		}
	}
	if(end != NULL)
		*end =driver;
	return head;
}
/*finds the default driver id provided a preferred drivers list or pick the first */
static int _find_default_driver_id(char ** prefs){
	
	int def_id = -1;
	int id;
	driver_list *driver = driver_head;
	if(prefs) {
		id =0;
		while(prefs[id] != NULL){
			def_id = aio_driver_id(prefs[id]);
			if(def_id >= 0){
				driver = _get_driver(def_id);
				if(driver){
					break;
				}
			}
			id ++;
			def_id = -1;
		}
	}

	if( def_id < 0) {
		/*No default Driver specified, itake th first in the list */
		aio_msg(AIO_DEBUG,"===== Preferd driver not found/specified default is the first in the list====");
		if(driver != NULL){
			def_id = 0;
		}

	}
	return def_id;
}

static driver_list * _get_driver(int driver_id){

	driver_list *driver = driver_head;
	int i = 0;
	if(driver_id < 0 ) return NULL;

	while(driver && (i < driver_id)){
		i++;
		driver = driver->next;
	}

	if(i == driver_id ) 
		return driver ;
	return NULL;
}	
/*appends the dynamic plugins found in dir *path  to the already prepared drivers list*/
static void _append_dynamic_drivers_dir(driver_list *driver, char *path) {
#ifdef HAVE_DLOPEN
	struct dirent *plugin_dirent;
	char *ext;
	struct stat statbuf;
	char fullpath[PATH_MAX];
	driver_list *plugin;
	DIR *plugindir = NULL;

	plugindir = opendir(path);
	if (plugindir != NULL) {
		while ((plugin_dirent = readdir(plugindir)) != NULL) {
			snprintf(fullpath, PATH_MAX, "%s/%s", 
			path, plugin_dirent->d_name);
			if (!stat(fullpath, &statbuf) && 
				S_ISREG(statbuf.st_mode) && 
				(ext = strrchr(plugin_dirent->d_name, '.')) != NULL) {

				if (strcmp(ext, SHARED_LIB_EXT) == 0) {
					plugin = _get_plugin(fullpath);
					if (plugin) {
						driver->next = plugin;
						plugin->next = NULL;
						driver = driver->next;
					}
				}
			}
		}
		closedir(plugindir);
	}
#endif
}

/*appends the default plugin path to the slite of drivers*/
static void _append_dynamic_drivers(driver_list *end){
  	_append_dynamic_drivers_dir(end,AIO_PLUGIN_PATH);
}
static aio_device_t* _create_device(int driver_id, driver_list *driver, aio_sample_format_t*format){
	
	aio_device_t *device;
	
	device  = malloc(sizeof(aio_device_t));

	memset(device, 0, sizeof(aio_device_t));

	if(device != NULL){
		device->driver_id = driver_id;
		device->funcs = driver->functions;
		device->machine_byte_format = aio_is_big_endian()? AIO_FMT_BIG : AIO_FMT_LITTLE;
		device->client_byte_format = _real_byte_format(format->byte_format);
		device->swap_buffer = NULL;
		device->swap_buffer_size = 0;
		device->internal = NULL;
	}

	return device;
}

static int _real_byte_format(int byte_format) {

	if (byte_format == AIO_FMT_NATIVE) {
		if (aio_is_big_endian())
			return AIO_FMT_BIG;
		else
			return AIO_FMT_LITTLE;
	} else
		return byte_format;
}

static int _realloc_swap_buffer(aio_device_t *device, int min_size){
	void *temp;
	if(min_size > device->swap_buffer_size){
		temp = realloc(device->swap_buffer,min_size);
		if(temp != NULL){
			device->swap_buffer = temp;
			device->swap_buffer_size = min_size;
			return 1;
		}else
			return 0;
	}else
		return 1;
}
static void _swap_samples(int8_t *target_buffer, int8_t *source_buffer, int num_bytes){
	int i;
	for (i = 0 ; i < num_bytes ; i +=2){
		target_buffer[i] = source_buffer[i+1];
		target_buffer[i+1] = source_buffer[i];
	}

}

/**
 *\brief Init the internal data structures and load all available plgins from disk.\n
 * The library must be initilized before any call to the other functions
 * \note
 * This function should never be called more that once before calling #aio_shutdown
 */

void aio_initialize(void) {
	driver_list *end;
	aio_msg(AIO_DEBUG,"aio_initialize: initializing ...\n");
	if(driver_head == NULL ){
		aio_msg(AIO_DEBUG,"aio_initialize: Loading static drivers\n");
		driver_head = _load_static_drivers(&end);
		aio_msg(AIO_DEBUG,"aio_initialize: appending dynamic drivers\n");
		_append_dynamic_drivers(end);

	}
	/*create info tables of drivers*/
	aio_msg(AIO_DEBUG,"aio_initialize: making info table\n");
	info_table = _make_info_table(&driver_head, &driver_count);
	aio_msg(AIO_DEBUG,"aio_initialize: finished initializing ...\n");
}
/**
 * \brief Returns the ID number of the default ouput/input driver
 * \param prefered_list a list of prefered driver to try in order if null it picks the first in the liste
 * \returns the positive id number of the found driver or -1 if none found
 *
 * */
int aio_default_driver_id(char **prefered_list){
	int id;
	aio_msg(AIO_DEBUG,"aio_default_driver_id: looking for the default driver ID\n");
	id = _find_default_driver_id(prefered_list);
	aio_msg(AIO_DEBUG,"aio_default_driver_id: found ID %d\n",id);
	return id;
}
/**
 * \brief Returns the ID number of a driver given a name 
 * \param short_name short name of the driver ("oss")
 * \returns the positive id number of the found driver or -1 if not found
 *
 * */

int aio_driver_id(char *short_name){
	int i;
	driver_list *driver = driver_head;

	i = 0;

	while(driver){
		if(strcmp(short_name,driver->functions->driver_info()->short_name) == 0)
			return i;
		i++;
		driver = driver->next;
	}

	return -1; /*no driver found */
}

/**
 *\brief Open a device for playback capture 
 *\param driver_id theid of the wanted driver (returned by #aio_default_driver_id() or #aio_driver_id())
 *\param format a sample format struct containing info about the data w're about play ou record - rate, number of channels, and the format - 
 *\param options options we pertaining to the driver we want set
 *\param open_mode open for play for capture or both (#AIO_PLAYONLY, #AIO_RECONLY, #AIO_RECPLAY)
 *\returns an initilized device structure or \c NULL if am error occured
 *\note 
 * Do not attemp to \c free() the returned pointer yourself #aio_close() will do it.
 * */
aio_device_t *  aio_open(int driver_id, aio_sample_format_t*format, aio_option_t **options,int open_mode){
	aio_functions_t *funcs;
	driver_list *driver;
	aio_device_t *device;
	/* Get the driver id */
	if(driver_id < 0) {
		aio_msg(AIO_ERROR, "aio_open: invalide driver id %d",driver_id);
		return NULL;
	}
	aio_msg(AIO_DEBUG,"aio_open: opening device for driver ID %d\n",driver_id);
	if( (driver = _get_driver(driver_id)) == NULL) {
		return NULL;
	}

	funcs = driver->functions;
	aio_msg(AIO_DEBUG,"aio_open: creating device for driver \'%s\' with ID %d\n",funcs->driver_info()->name,driver_id);
	if( (device = _create_device(driver_id,driver,format)) == NULL) {
		
		return NULL;
	}

	
	
	aio_msg(AIO_DEBUG,"aio_open: initilizing Device  for \'%s\' with ID %d\n",funcs->driver_info()->name,driver_id);
	if(funcs->init(device,format,options,open_mode) < 0){
		free(device);
		return NULL;
	}
	aio_msg(AIO_DEBUG,"aio_open: Device  for \'%s\' with ID %d opened sucessfully\n",funcs->driver_info()->name,driver_id);
		
	return device;
}
/**
 *\brief Plays back a block of data to an open device  
 *\param device the device to playto (returned by #aio_open())
 *\param out_samples the samples to play 
 *\param num_bytes the number of bytes to play
 *\param flags only for oss (#AIOPLAY_FINAL_CHUNK)
 *\returns the number of bytes played or -1 if an error occured (the device should be reopened)
 *\note 
 * Alway check the number of bytes returned and compare to the number of bytes requested to update the play position\n
 * (some drivers for efficiency truncates the number of bytes to play)
 * */

int aio_play(aio_device_t *device, int8_t * out_samples, size_t  num_bytes, int flags){
	
	int8_t *playback_buffer;

	if (device == NULL)
		return 0;
	/* juste in case we have to swap the samples (file out mainly, preceisly wav)
	 * the other drivers should be able to handle the swap process if there's any 
	 * (the sample format tells the driver) 
	 * for now it stays here ... should*/
	/*TODO : make the actual swap work, for now no swap the buffer is written as it is */
	if (device->swap_buffer != NULL) {
		if (_realloc_swap_buffer(device, num_bytes)) {
			_swap_samples(device->swap_buffer,out_samples, num_bytes);
			playback_buffer = device->swap_buffer;
		} else {
			return 0; /* Could not expand swap buffer */
		}
	}else { 
		playback_buffer = out_samples;
	}

	/* we're redeay .. send to the device */
	return device->funcs->play(device,playback_buffer,num_bytes,flags);
}
/**
 *\brief record a block of data from an open device  
 *\param device the device record from (returned by #aio_open())
 *\param in_samples the buffer to hold recorded samples 
 *\param num_bytes the number of bytes to record
 *\param flags (not used for the moment)
 *\returns the number of bytes record or -1 if an error occured (the device should be reopened)
 *\note 
 * Alway check the number of bytes returned and compare to the number of bytes requested 
 * */

int aio_record(aio_device_t *device, int8_t * in_samples, size_t num_bytes, int flags){
	
	int8_t *record_buffer = NULL;

	if (device == NULL)
		return -1;
	/* juste in case we have to swap th samples (the sond hardware and the host CPU differ in endianness) 
	 *
	 * TODO: make the actual swap work : for now the read buffer is handed as it is the caller 
	 */
	int read =  device->funcs->record(device,in_samples,num_bytes,flags);
	
	if (device->swap_buffer != NULL) {
		if (_realloc_swap_buffer(device, read)) {
			_swap_samples(device->swap_buffer,in_samples, read);
			record_buffer = device->swap_buffer;
		} else {
			return 0;  /*Could not expand swap buffer */
		}
	}else { 
		record_buffer = in_samples;
	}

	/* we're redeay .. send to the device */
	return read;
}
/**
 * \brief send a commande to the device 
 * \param device  the device to control (returned by #aio_open())
 * \param cmd the command to send
 * \param arg a pointer to comommand arg 
 * \returns the control resul from the device 
 * */
int aio_control(aio_device_t *device, int cmd, void * arg) {
	
	if (device == NULL)
		return CONTROL_ERROR;
	if(device->funcs == NULL)
		return CONTROL_ERROR;
	

	return device->funcs->control(device, cmd, arg);
}
/**
 *\brief Close an open device and free its memory
 *\param device the device to close (returned by #aio_open())
 *\param immed now and drop the rest of the frames or wait the playback/capture to finish  (#AIO_IMMED_NOW, #AIO_IMMED_LATER)

 *\returns 0 for success -1 if the device is \c NULL
 * */

int aio_close(aio_device_t *device, int immed){
	int result ;

	if(device == NULL){
		return -1;
	} else {
		result = device->funcs->uninit(device,immed);
		if(device->file) {
			fclose(device->file);
			device->file = NULL;
		}
		if(device->swap_buffer != NULL){
			free(device->swap_buffer);
		}
		free(device);
	}
	return 0;
}
/**
 * \brief put device in a paused state 
 * \param device the device to pause (returned by #aio_open())
 * \returns 0 on succes or -1 on faillure
 */

int aio_pause(aio_device_t *device) {

	if(device == NULL)
		return -1;
	if(device->funcs == NULL)
		return -1;
	return device->funcs->pause(device);
}
/**
 * \brief resume playback from after pause state
 * \param device the device to pause (returned by #aio_open())
 * \returns 0 on succes or -1 on faillure
 */

int aio_resume(aio_device_t *device){

	if(device == NULL){
		return -1;
	}
	if(device -> funcs == NULL)
		return -1;

	return device->funcs->resume(device);
}
/**
 *\brief Returns the number of bytes ready to written/read 
 *\param device  the device we want to interogate (returned by #aio_open())
 *\param dir input or outpu (#AIO_SPACE_IN, #AIO_SPACE_OUT) 
 *\returns the number of bytes ready to read/etitten or -1 if an error occurs
 *\note 
 * for this work with a capture device you should read atleat one byte before calling \
 * otherwise it will always reporte 0
 * */

int aio_getspace(aio_device_t *device,int dir ){

	if (device == NULL)
		return -1;
	if(device->funcs == NULL)
		return -1;
	return device->funcs->get_space(device,dir);

}
	/**
	 * \example aio_example.c
	 * */

/**
 *\brief Returns the delay in seconds. it meens the number of seconds before the \n
 	next sample is comitted to the hardware 
 *\param device  the device we want to interogate (returned by #aio_open())
 *\returns the number of seconds to it will take to play the next sample or  -1 if an error occurs
 * otherwise it will always reporte 0
 * */


float aio_getdelay(aio_device_t *device){
	if(device  == NULL)
		return -1;
	if(device->funcs == NULL)
		return -1;
	return device->funcs->get_delay(device);
}
/**
 *\brief Unload all the plugins and free any internal data structure the library has created.\
 * should be called prio to exiting the programe
 * */

void aio_shutdown(void){

	driver_list *driver = driver_head;
	driver_list *next_driver;

	if (!driver_head) return;
	
	/* unload and free all the drivers */
	while (driver) {
		if (driver->handle) {

			dlclose(driver->handle);
			//free(driver->functions); /* DON'T FREE STATIC FUNC TABLES */
		}
		next_driver = driver->next;
		free(driver);
		driver = next_driver;
	}

	/* NULL out driver_head or aio_initialize() won't work */
	driver_head = NULL;

	driver_count = 0;
	free(info_table);
	info_table = NULL;
}
/**
 * \brief get the informatio of the device 
 * \param device to query (returned by #aio_open())
 * \returns information structure or NULL if the device is \c NULL
 *
 * */

aio_info_t * aio_getinfo(aio_device_t *device){
	if(device == NULL){
		return NULL;
	}
	if(device->funcs == NULL)
		return NULL;

	return device->funcs->driver_info();

}
/**
 * \brief reset the device bye closing and reopening 
 * \param device to query (returned by #aio_open())
 * \param immed now and drop the playback or wait for the reste of the frames (#AIO_IMMED_NOW, #AIO_IMMED_LATER)
 * \returns 0 on success -1 o faillure
 *
 * */

int aio_reset(aio_device_t * device, int immed){

	if(device == NULL)
		return -1;
	if(device->funcs ==NULL)
		return -1;
	
	return device->funcs->reset(device);

}
/**
 * \brief test the endianesse of the machine 
 * return 1 if big endian 0 otherwise*/
int aio_is_big_endian(void){

	static uint16_t pattern = 0xbabe;
	return 0[(volatile unsigned char *)&pattern] == 0xba;
}

/**
 * \brief log messages of a certain level according to \ref aio_verbosity to the consol.
 * \param level of verbosity this message belongs to.
 * \param fmt format string.
 * \param ... variable argument (like \c printf(3))
 * \return the number of bytes written.
 */

int aio_msg(int level, char *fmt, ...){
	int rv = 0;
	va_list list;
	char msg[AIO_MSGSIZE_MAX];
	
	va_start(list,fmt);
	vsnprintf(msg,AIO_MSGSIZE_MAX,fmt,list);
	va_end(list);
	
	if(! (level & aio_verbosity)){
		/* the bit of that level is not set in aio_verbosity
		 	we're not allowed to continue */
		return 0;
	}

	switch (level) {

		case AIO_DEBUG:
			rv = printf("DEBUG: %s\n",msg);
			fflush(stdin);
			break;
		
		case AIO_ERROR:
			rv = fprintf(stderr,"ERROR: %s\n",msg); 
			break ;
		case AIO_WARN:
			rv = printf("WARN: %s\n",msg);
			fflush(stdin);
			break;
		default :
			rv = 0;

	}
	return rv;
}
