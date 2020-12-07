# ccq-software-build

CCQ software build scripts to be run on rusty, workstations, or popeye with available modules.

topdir lists available codes, and subdirs should be labelled by version numbers, and build chain. We should limit ourselves to OpenMPI and IntelMPI build chains. Hence, a typical module file should load for example the following modules:

```
gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3
```

Each code dir contains helper files, and a bash script `install.sh`. Executing this this script with bash:
```
bash install.sh
```
compiles the code, ideally completely without adaptions,  and finally creates a module file. By adding the following line to your bashrc you can load these modules:
```
export MODULEPATH=/path/to/ccq-software-build:$MODULEPATH
```
Just exchange the modulepath above with the location of the git repo on your machine. 

The following codes are supported:
* Wannier90 ver 3.1 using the same build chain as Vasp 6.1
    * required to build first for Vasp and QE
* Vasp ver 6.1 linked against Wannier90 ver 3.1
    * OpenMPI 4, Intel MKL including Scalapack and blacs, FFTW
    * Wannier90 is fully MPI enabled
* Quantum Espresso ver 6.6 including w90 (no HDF5 support yet - missing fortran2003 support in HDFlib module)
* triqs 3.x.x unstable branch using the same build chain as the above DFT codes
    * includes the triqs applications: cthyb, dfttools, maxent, TPRF
* ForkTPS 3.x.x unstable, for triqs3 (install triqs3 first)
    * installs itensor

To start just go into one of the software folders provides and just `bash install.sh`.

### Note on MPI version

For running on different parts of rusty/popeye the MPI version needs to be adapted. At the moment everything is compiled using the default `openmpi4/4.0.5` module, which is optimal for all infiband connected nodes (rome and worker0xxx), e.g. the constrain `rome` or no constraint. Moreover, these version works fine on all Linux workstations. To use the compiled code on the skylake or broadwell nodes with constraint skylake or broadwell in a slurm job one has to change the MPI module before each job to the module `openmpi4/4.0.5-opa` instead of `openmpi4/4.0.5`. In general no recompiling of the code is necessary. More information can be found here: https://docs.simonsfoundation.org/index.php/MPI

For triqs job files for rusty rome and skylake can be found in the directory of the install script. The install script will generate a rome and a skylake module. The modules differ only by the loaded MPI module. A first benchmark indicated that using cthyb on 3-4 skylake nodes will have the same speed as one rome node with 128 cores. 
