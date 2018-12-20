#!/bin/bash
NETCDF=/public/home/xiaolh/software/netcdf/all
ifort convert.f90 -L$NETCDF/lib -lnetcdff -lnetcdf -I$NETCDF/include -o convert
