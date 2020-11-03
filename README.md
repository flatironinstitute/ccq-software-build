# ccq-software-build

CCQ software build scripts to be run on rusty, workstations, or popeye with available modules.

topdir lists available codes, and subdirs should be labelled by  version numbers, and build chain. We should limit ourselves to OpenMPI and IntelMPI build chains. Hence, a typical module file should load for example the following modules:

```
gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3
```
Caution: For running on different parts of rusty/popeye the MPI version needs to be adapted. At the moment everythin is compiled using the default `openmpi4/4.0.5` module, which is optimal for all infiband connected nodes, e.g. constrain `rome` or no constraint. Moreover, these version works fine on all Linux workstations. More information can be found here: https://docs.simonsfoundation.org/index.php/MPI

Each code dir contains helper files, a bash script `install.sh`  that compiles the code and a module file. By adding the following line to your bashrc you load these modules then:
```
export MODULEPATH=/path/to/ccq-software-build:$MODULEPATH
```


The following codes are supported:
* Vasp ver 6.1 linked against Wannier90 ver 3.1
    * OpenMPI 4, Intel MKL including Scalapack and blacs, FFTW
    * Wannier90 is fully MPI enabled
* Wannier90 ver 3.1 using the same build chain as Vasp 6.1
