#==============================================================================#
#			   Fortran Compiler/Flags
#		-O0=no optimization,-O3=full optimization
#==============================================================================#
FC=gfortran
FFLAGS=-O2
#FFLAGS= -g -O0 -Wall -Wextra -pedantic -fcheck=all -fbacktrace
#==============================================================================#
#Targets
#==============================================================================#
all: potentials int mod grid main
#==============================================================================#
potentials:
	$(FC) $(FFLAGS) -c potentials_mod.f90
#==============================================================================#
int:
	$(FC) $(FFLAGS) -c gen_hermite_rule.f90
#==============================================================================#
mod:
	$(FC) $(FFLAGS) -c Lmon_spectra_module.f90
#==============================================================================#
grid:
	$(FC) $(FFLAGS) -c Lmon_spectra.f90
#==============================================================================#
main:
	$(FC) $(FFLAGS) gen_hermite_rule.o potentials_mod.o Lmon_spectra_module.o Lmon_spectra.o -llapack
#==============================================================================#
clean:
	rm -rf *.o *.mod main out a.out
