/**
 * \file test/aio_example.c
 * \brief Example of libaio use
 * \author Mohamed Abderaouf Bencheraiet <kenshin@cerberus.endoftheinternet.org>
 * \date 2008
 *
 * Example of libaio use 
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


#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <aio/aio.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include "af_format.h"
#define BUF_SIZE 4096
extern int aio_verbosity ;



int8_t * gen_rand(int i){
	
	int8_t *samples;
	samples = malloc(i*sizeof(int8_t));


	int randInit = time(0);
	int randomInit = time(0);
	srand(randInit);
	srandom(randomInit);

	int j = 0;
	
	for(j = 0; j<i; j ++ ){
		samples[j] = rand();	

	}

	return samples;
}
int main(int argc, char **argv)
{
	aio_device_t *device =NULL;
	aio_sample_format_t format;
	int default_driver;
	int8_t *buffer = NULL;
	int8_t *buff = NULL;
	int so = 0;
	int read = 0;
	float delay =0.0;
	int loopcount;
	int buf_size;
	int record =0;


	/*-------set the verbosity to debug --------*/

	aio_verbosity = AIO_VERBOSITY_DEBUG;		
	/* -- Initialize -- */

	
	aio_initialize();
	/* -- Setup for default driver -- */
	
	default_driver = aio_driver_id("oss");
	format.channels = 2;
	format.samplerate = 44100;
	format.format =  AF_FORMAT_S16_LE;
	/* -- Open driver -- */



	if(argc >= 2 ){
		if(argv[1][0] == 'r'){
			record  = 1;
			aio_option_t dev_opt = {"rec_src","mic"};
			aio_option_t *options[] = {\
	       				&dev_opt,\
					NULL\
					};

			device = aio_open(default_driver, &format, options ,AIO_RECONLY);
		}
		
		
	}else {
		printf("salue");
		device = aio_open(default_driver, &format, NULL ,AIO_PLAYONLY);
	}



	if (device == NULL) {
		fprintf(stderr, "Error opening device.\n");
		return 1;
	}   
	if(record){
	/* -- Record some stuf -- */
	 		buf_size = 640000;
			loopcount = 0;
			buffer = (int8_t *) malloc(buf_size * sizeof(int8_t));
			buff = buffer	;
			while(loopcount <= buf_size){
				so = aio_getspace(device,AIO_SPACE_IN);
				printf("availspace   %d\n",so);
				read  = aio_record(device,buff,so,0);
				if(read == -1){
					printf("%s\n",strerror(errno));
					goto finish;
				}
				printf("recorded  %d\n",read);
				loopcount += read;
				buff+= read;

			}

			printf("replaying the recorded data \n");
			int mode = AIO_PLAYONLY;
			if(aio_control(device, AIOCONTROL_SET_MODE,&mode) == CONTROL_OK){

				goto play;
			}else{
				goto finish;

			}



	}else{
	/* -- Play some stuff -- */

			buf_size = 640000;
			loopcount = buf_size;	
			buffer = gen_rand(buf_size);
			buff = buffer;	
play:
			while(loopcount > 0){	
				
				delay = aio_getdelay(device) ;
				if(delay > 0)
					/* wakup befor the audio 
					 * buffer runs dry*/
					sleep(delay/2);
				printf("delay : %f\n",delay);
				so = aio_getspace(device,AIO_SPACE_OUT);
				printf("availspace   %d\n",so);
				read =  aio_play(device,buff,so,0);
				printf("played %d\n",read);
				loopcount -=read;
				buff +=read;
	
		}
	}
finish:
	if(buffer)
		free(buffer);
	/* -- Close and shutdown -- */
	aio_close(device,1);
    
	aio_shutdown();

  return (0);
}
