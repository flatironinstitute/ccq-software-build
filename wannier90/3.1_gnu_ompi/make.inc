#===================
# gfortran
#===================
//MKLROOT = /cm/shared/sw/pkg/vendor/intel-pstudio/2020/compilers_and_libraries_2020.0.166/linux/mkl

F90 = gfortran -m64 -I${MKLROOT}/include

#Add next two lines for parallel postw90. Choose the correct name of the mpi f90 wrapper
#COMMS  = mpi 
#MPIF90 = mpif90 -m64 -I${MKLROOT}/include 

FCOPTS = -O3 
LDOPTS =

LIBS =  ${MKLROOT}/lib/intel64/libmkl_scalapack_lp64.a -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_gf_lp64.a ${MKLROOT}/lib/intel64/libmkl_sequential.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_blacs_openmpi_lp64.a -Wl,--end-group -lpthread -lm -ldl  




