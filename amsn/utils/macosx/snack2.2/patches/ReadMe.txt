These patches were created by David Luyer (the Makefile.in patch was created from looking at the code in his build-amsn-snack.sh script), in order to make snack work correctly on Intel mac machines.

The patches are against the 2.2.10 version of snack, and reconfigure the Makefile to build universally, while also editing jkAudIO_osx to work correctly.

The patches should be applied inside the unix directory of the snack2.2.10 folder. They should be applied before snack is configured, there is no particular order in which they should be applied.