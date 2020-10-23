# ccq-software-build

CCQ software build scripts to be run on rusty, workstations, or popeye with available modules.

topdir lists available codes, and subdirs should be labelled by  version numbers, and build chain. We should limit ourselves to OpenMPI and IntelMPI build chains. Hence, a typical module file should load for example the following modules:

```
gcc/7.4.0 openmpi2/2.1.6-hfi lib/fftw3/3.3.8-openmpi2 intel/mkl/2019-3
```

Each code dir contains helper files, a bash script that compiles the code and a module file.
