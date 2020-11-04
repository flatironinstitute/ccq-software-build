# Vasp 6.1 


## GNU OMPI4 MKL build chain

this version is build with OpenMPI4, gfortran, and using MKL 2019 libraries. Moreover, wannier90 is linked into it automatically. If using on skylake one needs to use the module `openmpi4/4.0.5-opa` instead of `openmpi4/4.0.5`. 

Some benchmark results of this version (timing from cpu time LOOP+ in OUTCAR):

| #nodes | ranks per node | type    | NCORE | KPAR | time (sec)   | speedup |
|---     |---             |---      |---    |---   |---           |---      | 
| 1      | 40             | skylake | 6     | 1    | 3434.7 (ref) | 1.00    |
| 1      | 40             | rome    | 6     | 1    | 2988.4       | 1.15    |
| 1      | 64             | rome    | 8     | 1    | 1175.2       | 2.92    |
| 1      | 128            | rome    | 8     | 1    | 746.4        | 4.60    |
| 1      | 128            | rome    | 16    | 1    | 642.1        | 5.35    |
| 1      | 128            | rome    | 16    | 2    | 534.9        | 6.42    |
| 1      | 128            | rome    | 8     | 4    | 593.7        |  5.79   |
| 3      | 120            | skylake | 5     | 3    | 442.9        | 7.76    |
| 4      | 160            | skylake | 5     | 4    | 351.5        | 9.77    |
| 2      | 256            | rome    | 16    | 2    | 494.2        | 6.95    |
| 2      | 256            | rome    | 16    | 4    | 354.7        | 9.68    |

This shows, that MPI scaling is better with skylake, but nevertheless Vasp benefits a lot from the 128 cores per node on rome, outperforming one skylake node being 4.6 times faster without special adjustments. However, one can also see that with that many cores per node, KPAR becomes more important, as MPI is consuming even on 1 node too much time until KPAR parrellism is activated. A `KPAR=2` setting in Vasp maximizes 1 node performance to a speedup of 6.4. Compared to one skylake node. But, 3 skylake nodes with a similar amount of cores than one rome node have a speed up of 7.8, outperforming the rome node slightly. Hence, the new AMD epyc rome nodes are really fast, but benefit a lot from proper setting of parallelization flags in Vasp.
