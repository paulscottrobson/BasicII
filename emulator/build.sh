#
#		Copy Core files.
#
cp ../core/65816.? ../core/65816core.c ../core/traps.h .
#
#		Make the executabe
#
make -f makefile.linux

