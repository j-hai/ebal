# hbal (1.2.15)

* GitHub: <https://github.com/xuyiqing/hbal>
* Email: <mailto:yiqingxu@stanford.edu>
* GitHub mirror: <https://github.com/cran/hbal>

Run `revdepcheck::revdep_details(, "hbal")` for more info

## In both

*   checking whether package ‘hbal’ can be installed ... ERROR
     ```
     Installation failed.
     See ‘/Users/jhainmueller/Documents/GitHub/ebal/revdep/checks.noindex/hbal/new/hbal.Rcheck/00install.out’ for details.
     ```

## Installation

### Devel

```
* installing *source* package ‘hbal’ ...
** this is package ‘hbal’ version ‘1.2.15’
** package ‘hbal’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
using C++ compiler: ‘Apple clang version 17.0.0 (clang-1700.6.4.2)’
using SDK: ‘MacOSX26.2.sdk’
clang++ -arch arm64 -std=gnu++17 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I'/Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/Rcpp/include' -I'/Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/RcppEigen/include' -I/opt/R/arm64/include     -fPIC  -falign-functions=64 -Wall -g -O2   -c RcppExports.cpp -o RcppExports.o
In file included from RcppExports.cpp:4:
In file included from /Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/RcppEigen/include/RcppEigen.h:25:
...
      |       ^
5 warnings generated.
clang++ -arch arm64 -std=gnu++17 -dynamiclib -Wl,-headerpad_max_install_names -undefined dynamic_lookup -L/Library/Frameworks/R.framework/Resources/lib -L/opt/R/arm64/lib -o hbal.so RcppExports.o eigen.o -L/Library/Frameworks/R.framework/Resources/lib -lRlapack -L/Library/Frameworks/R.framework/Resources/lib -lRblas -L/opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0 -L/opt/gfortran/lib -lemutls_w -lheapt_w -lgfortran -lquadmath -F/Library/Frameworks/R.framework/.. -framework R
ld: warning: search path '/opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0' not found
ld: warning: search path '/opt/gfortran/lib' not found
ld: library 'emutls_w' not found
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [hbal.so] Error 1
ERROR: compilation failed for package ‘hbal’
* removing ‘/Users/jhainmueller/Documents/GitHub/ebal/revdep/checks.noindex/hbal/new/hbal.Rcheck/hbal’


```
### CRAN

```
* installing *source* package ‘hbal’ ...
** this is package ‘hbal’ version ‘1.2.15’
** package ‘hbal’ successfully unpacked and MD5 sums checked
** using staged installation
** libs
using C++ compiler: ‘Apple clang version 17.0.0 (clang-1700.6.4.2)’
using SDK: ‘MacOSX26.2.sdk’
clang++ -arch arm64 -std=gnu++17 -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG  -I'/Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/Rcpp/include' -I'/Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/RcppEigen/include' -I/opt/R/arm64/include     -fPIC  -falign-functions=64 -Wall -g -O2   -c RcppExports.cpp -o RcppExports.o
In file included from RcppExports.cpp:4:
In file included from /Users/jhainmueller/Documents/GitHub/ebal/revdep/library.noindex/hbal/RcppEigen/include/RcppEigen.h:25:
...
      |       ^
5 warnings generated.
clang++ -arch arm64 -std=gnu++17 -dynamiclib -Wl,-headerpad_max_install_names -undefined dynamic_lookup -L/Library/Frameworks/R.framework/Resources/lib -L/opt/R/arm64/lib -o hbal.so RcppExports.o eigen.o -L/Library/Frameworks/R.framework/Resources/lib -lRlapack -L/Library/Frameworks/R.framework/Resources/lib -lRblas -L/opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0 -L/opt/gfortran/lib -lemutls_w -lheapt_w -lgfortran -lquadmath -F/Library/Frameworks/R.framework/.. -framework R
ld: warning: search path '/opt/gfortran/lib/gcc/aarch64-apple-darwin20.0/14.2.0' not found
ld: warning: search path '/opt/gfortran/lib' not found
ld: library 'emutls_w' not found
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [hbal.so] Error 1
ERROR: compilation failed for package ‘hbal’
* removing ‘/Users/jhainmueller/Documents/GitHub/ebal/revdep/checks.noindex/hbal/old/hbal.Rcheck/hbal’


```
# jointCalib (0.1.0)

* GitHub: <https://github.com/ncn-foreigners/jointCalib>
* Email: <mailto:maciej.beresewicz@ue.poznan.pl>
* GitHub mirror: <https://github.com/cran/jointCalib>

Run `revdepcheck::revdep_details(, "jointCalib")` for more info

## Error before installation

### Devel

```
* using log directory ‘/Users/jhainmueller/Documents/GitHub/ebal/revdep/checks.noindex/jointCalib/new/jointCalib.Rcheck’
* using R version 4.5.3 (2026-03-11)
* using platform: aarch64-apple-darwin20
* R was compiled by
    Apple clang version 16.0.0 (clang-1600.0.26.6)
    GNU Fortran (GCC) 14.2.0
* running under: macOS Tahoe 26.3.1
* using session charset: UTF-8
* using options ‘--no-manual --no-build-vignettes’
* checking for file ‘jointCalib/DESCRIPTION’ ... OK
...
* checking for code/documentation mismatches ... OK
* checking Rd \usage sections ... OK
* checking Rd contents ... OK
* checking for unstated dependencies in examples ... OK
* checking examples ... OK
* DONE

Status: OK







```
### CRAN

```






```
