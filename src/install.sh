
CC=icc
FC=ifort

#ENDIAN=little_endian
ENDIAN=big_endian

# I/O routine
$CC -D _UNDERSCORE=1 -w -c read_geogrid.c
$CC -D _UNDERSCORE=1 -w -c write_geogrid.c

#$FC -convert $ENDIAN -c main.f90
$FC -mcmodel=medium -c main.f90

# link
$FC  -o updatelanduse *.o
