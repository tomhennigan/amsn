/* 
   Copyright (c) 2002 Malte Starostik <malte.starostik@t-online.de>

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; see the file COPYING.  If not, write to
   the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.
*/

#include <cstring>
#include <iostream>
#include <vector>

#include <alsa/mixer.h>

extern "C"
{
# include "grab-ng.h"
}

class alsa_mixer;

class attr_proxy : public ng_attribute
{
public:
	typedef int ( alsa_mixer::*accessor )();
	typedef void ( alsa_mixer::*mutator )( int );
	attr_proxy() { std::memset( this, 0, sizeof( ng_attribute ) ); }
	attr_proxy( int type, int id, const char* name, alsa_mixer* instance, accessor read, mutator write )
	{
		this->id = id;
		this->name = name;
		this->type = type;
		this->read = &read_proxy;
		this->write = &write_proxy;

		handle_data* d = new handle_data;
		d->instance = instance;
		d->read = read;
		d->write = write;
		this->handle = d;
	}
	attr_proxy( const attr_proxy& other )
	{
		handle = 0;
		*this = other;
	}
	attr_proxy& operator =( const attr_proxy& rhs )
	{
		if ( &rhs != this )
		{
			deref();
			std::memcpy( this, &rhs, sizeof( ng_attribute ) );
			ref();
		}
		return *this;
	}
	~attr_proxy() { deref(); }

private:
	struct handle_data
	{
		handle_data() : ref_count( 1 ) {}

		alsa_mixer* instance;
		accessor read;
		mutator write;
		int ref_count;
	};

	handle_data* data() const { return reinterpret_cast< handle_data* >( handle ); }
	void ref() { if ( data() ) data()->ref_count++; }
	void deref()
	{
		if ( data() && !--data()->ref_count )
		{
			delete data();
			handle = 0;
		}
	}

	static int read_proxy( ng_attribute* attr )
	{
		handle_data* d = reinterpret_cast< handle_data* >( attr->handle );
		return ( d->instance->*d->read )();
	}
	static void write_proxy( ng_attribute* attr, int val )
	{
		handle_data* d = reinterpret_cast< handle_data* >( attr->handle );
		( d->instance->*d->write )( val );
	}
};

class alsa_mixer
{
public:
	alsa_mixer();
	~alsa_mixer();

	bool init( const char* channel );

	int mute();
	void mute( int val );

	int volume();
	void volume( int val );

	static void* open( char* );
	static void close( void* inst );

	static ng_devinfo* probe();
	static ng_devinfo* channels( char* device );

	static ng_attribute* volctl( void* inst, char* channel );

private:
	std::vector< attr_proxy > attrs;
	snd_mixer_t* handle;
	snd_mixer_elem_t* elem;
	bool muted;
};

alsa_mixer::alsa_mixer()
	: attrs( 3 )
{
	snd_mixer_open( &handle, 0 );
	snd_mixer_attach( handle, "default" );
	snd_mixer_selem_register( handle, 0, 0 );
	snd_mixer_load( handle );

	attrs[ 0 ] = attr_proxy( ATTR_TYPE_BOOL, ATTR_ID_MUTE, "mute",
	                         this, &alsa_mixer::mute, &alsa_mixer::mute );
	attrs[ 1 ] = attr_proxy( ATTR_TYPE_INTEGER, ATTR_ID_VOLUME, "volume",
	                         this, &alsa_mixer::volume, &alsa_mixer::volume );
}

alsa_mixer::~alsa_mixer()
{
	if ( handle ) snd_mixer_close( handle );
}

bool alsa_mixer::init( const char* channel )
{
	for ( elem = snd_mixer_first_elem( handle ); elem; elem = snd_mixer_elem_next( elem ) )
		if ( strcasecmp( channel, snd_mixer_selem_get_name( elem ) ) == 0 )
		{
			long min, max;
			snd_mixer_selem_get_playback_volume_range( elem, &min, &max );
			attrs[ 1 ].min = min;
			attrs[ 1 ].max = max;
			return true;
		}
	return false;
}

int alsa_mixer::mute()
{
	int left, right;
	snd_mixer_selem_get_playback_switch( elem, SND_MIXER_SCHN_FRONT_LEFT, &left );
	snd_mixer_selem_get_playback_switch( elem, SND_MIXER_SCHN_FRONT_RIGHT, &right );
	return !left && !right;
}

void alsa_mixer::mute( int val )
{
	snd_mixer_selem_set_playback_switch( elem, SND_MIXER_SCHN_FRONT_LEFT, !val );
	snd_mixer_selem_set_playback_switch( elem, SND_MIXER_SCHN_FRONT_RIGHT, !val );
}

int alsa_mixer::volume()
{
	long left, right;
	snd_mixer_selem_get_playback_volume( elem, SND_MIXER_SCHN_FRONT_LEFT, &left );
	snd_mixer_selem_get_playback_volume( elem, SND_MIXER_SCHN_FRONT_RIGHT, &right );
	return ( left + right ) / 2;
}

void alsa_mixer::volume( int val )
{
	snd_mixer_selem_set_playback_volume( elem, SND_MIXER_SCHN_FRONT_LEFT, val );
	snd_mixer_selem_set_playback_volume( elem, SND_MIXER_SCHN_FRONT_RIGHT, val );
}

void* alsa_mixer::open( char* )
{
	return new alsa_mixer();
}

void alsa_mixer::close( void* inst )
{
	delete reinterpret_cast< alsa_mixer* >( inst );
}

ng_devinfo* alsa_mixer::probe()
{
	std::cerr << "alsa_mixer::probe not implemented" << std::endl;
	return 0;
}

ng_devinfo* alsa_mixer::channels( char* device )
{
	std::cerr << "alsa_mixer::channels not implemented" << std::endl;
	return 0;
}

ng_attribute* alsa_mixer::volctl( void* instance, char* channel )
{
	alsa_mixer* mixer = reinterpret_cast< alsa_mixer* >( instance );
	return mixer->init( channel ) ? &mixer->attrs[ 0 ] : 0;
}

extern "C" void ng_plugin_init( void )
{
	static struct ng_mix_driver mixer_info =
	{
	    /* name */      "alsa",
	    /* probe */     alsa_mixer::probe,
	    /* channels */  alsa_mixer::channels,
	    /* open */      alsa_mixer::open,
	    /* volctl */    alsa_mixer::volctl,
	    /* close */     alsa_mixer::close,
	};

	ng_mix_driver_register( NG_PLUGIN_MAGIC, __FILE__, &mixer_info );
}

// vim: ts=4 sw=4 noet
