#
# This is a modified/original file distributed in RESPACK code under GNU GPL ver.3.
# https://sites.google.com/view/kazuma7k6r
#

# for GCC Compiler
set(CMAKE_C_COMPILER "gcc" CACHE STRING "" FORCE)
set(CMAKE_Fortran_COMPILER "gfortran" CACHE STRING "" FORCE)
set(CMAKE_Fortran_FLAGS_RELEASE "-O2 -fopenmp -march=broadwell -g -fbacktrace -ffree-line-length-none" CACHE STRING "" FORCE)
set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -fopenmp -g -fbacktrace -ffree-line-length-none" CACHE STRING "" FORCE)

