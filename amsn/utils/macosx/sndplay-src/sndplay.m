#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSSound *sound;

    if( argc != 2 ) {
        fprintf(stderr,"Usage: sndplay sound.[snd][aiff][wav]\n ");
        return -1;
    }
    if( strcmp(argv[1],"-?") == 0) {
        fprintf(stderr,"Usage: sndplay sound.[snd][aiff][wav]\n ");
        return -1;
    }
    if( strcmp(argv[1],"--help") == 0) {
        fprintf(stderr,"Usage: sndplay sound.[snd][aiff][wav]\n ");
        return -1;
    }
 
   NS_DURING
        sound = [[NSSound alloc] initWithContentsOfFile:[NSString stringWithCString:argv[1]] byReference:(bool)false];
        [sound play];
        while ( [sound isPlaying] );
    NS_HANDLER
    NS_ENDHANDLER

    [pool release];
    return 0;
}
