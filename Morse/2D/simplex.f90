!==============================================================================!
!                                2D Simplex
!==============================================================================!
!       Modified:
!   21 Janary 2020
!       Author:
!   Shane W. Flynn, Yang Liu, Vladimir A. Mandelshtam
!==============================================================================!
!Implementation for testing the 2D morse code
!This needs to be generalized and made for new implementation this is not done!
!==============================================================================!
module qlj_mod
implicit none
!==============================================================================!
!                            Global Variables
!==============================================================================!
!d              ==> Particle Dimensionality
!Npoints        ==> Number of grid points
!c_LJ           ==> parameter for LJ
!E_cut          ==> Energy Cutoff Contour
!integral_P     ==> Normalization for P_x
!==============================================================================!
integer::d,Npoints,k
double precision,allocatable,dimension(:,:)::x
double precision::c_LJ,E_cut,integral_P
!==============================================================================!
contains
!==============================================================================!
function random_integer(Nmin,Nmax)
!==============================================================================!
!Randomly generate an integer in the range 1-Nparticles
!==============================================================================!
!Nmin           ==>minimum index value (1)
!Nmax           ==>maximum index value (Nparticles)
!random_integer ==>integer returned
!a              ==>random number (0,1)
!==============================================================================!
implicit none
integer::Nmin,Nmax,random_integer
double precision::a
call random_number(a)
random_integer=floor(a*(Nmax-Nmin+1))+Nmin
end function random_integer
!==============================================================================!
function V(x)
!==============================================================================!
!Potential Energy (Hard-Coded 2D Morse)
!==============================================================================!
!x              ==>(d) ith particles coordinate x^i_1,..,x^i_d
!V              ==>evaluate V(x)
!D_morse        ==>Parameter for Morse Potential
!omega          ==>(d) Parameter for Morse Potential
!==============================================================================!
implicit none
double precision::x(d),V
double precision,parameter::omega(2)=(/0.2041241,0.18371169/)
double precision,parameter::D_morse=12.
V=D_morse*sum((exp(-omega(:)*x(:))-1.)**2)
end function V
!==============================================================================!
function P(x)
!==============================================================================!
!Target Distribution Function
!==============================================================================!
!P              ==>evaluate P(x)
!x              ==>(d) ith particles coordinate x^i_1,..,x^i_d
!==============================================================================!
implicit none
double precision::x(d),P
if(V(x)<E_cut) P=(E_cut-V(x))**(d/2.)/integral_P
if(V(x)>=E_cut) P=1d-20
end function P
!==============================================================================!
function Pair_LJ_NRG(x1,x2)
!==============================================================================!
!quasi-Lennard Jones pairwise energy between grid points
!==============================================================================!
!x1             ==>(d) ith atoms coordinates
!x2             ==>(d) jth atoms coordinates
!a/b            ==>evaluate LJ
!sigma          ==>c*sigma(P)
!Pair_LJ_NRG    ==>Energy of the i-j q-LJ potential
!==============================================================================!
implicit none
double precision::x1(d),x2(d),a,b,Pair_LJ_NRG,sigma1,sigma2
a=sum((x1(:)-x2(:))**2)
sigma1=c_LJ*(P(x1)*Npoints)**(-1./d)
sigma2=c_LJ*(P(x2)*Npoints)**(-1./d)
b=(sigma2**2/a)**3
a=(sigma1**2/a)**3
Pair_LJ_NRG=a**2-a+b**2-b
end function Pair_LJ_NRG
!==============================================================================!
function f(PP)
!==============================================================================!
!Computes the total potential energy, needed for the simplex minimizaiton
!==============================================================================!
implicit none
integer::i,j
double precision::PP(2),f,vtot
vtot=0
do i=1,Npoints
  if(i.ne.k) vtot=vtot+Pair_LJ_NRG(x(:,i),PP(:))
enddo
f=vtot
end function f
!==============================================================================!
subroutine Moments_Reg(Moment,i,xmin,xmax)
!==============================================================================!
!Compute lower moments of the distribution to verify global accuracy
!Compute moments using a regular square grid (most accurate method for 3D Morse)
!Integrate over the square [a,b],[a,b] size determined by Moments_MMC subroutine
!int P(r)~Area_Square/N sum_n=1,N P(r_n)
!==============================================================================!
!r              ==>(d) coordinates
!xmin           ==>(d) minimum of normalization box
!xmax           ==>(d) maximum of normalization box
!Moment         ==>(0:5) 5 Lowest Moments for the distribution
!==============================================================================!
integer::i,i1,i2,j
double precision::r(d),xmin(d),xmax(d),Moment,dummy
Moment=0d0
do i1=0,i
  do i2=0,i
    r(1)=xmin(1)+i1*(xmax(1)-xmin(1))/i
    r(2)=xmin(2)+i2*(xmax(2)-xmin(2))/i
    dummy=P(r)
    Moment=Moment+dummy
  enddo
enddo
dummy=1./i**d
do j=1,d
  dummy=dummy*(xmax(j)-xmin(j))
enddo
integral_P=dummy*Moment
end subroutine Moments_Reg
!==============================================================================!
subroutine box_size(N_MC,xmin,xmax)
!==============================================================================!
!Metropolis Monte Carlo to determine the box size for normalizing P(xmin,xmax)
!==============================================================================!
!N_MC           ==>Number of Monte Carlo Iterations
!mv_cutoff      ==>trial displacement move cutoff
!r              ==>(d) coordinates
!r_trial        ==>(d) trial coordinates
!s              ==>(d) trail displacement; random number for coordinates
!xmin           ==>(d) minimum of normalization box
!xmax           ==>(d) maximum of normalization box
!==============================================================================!
integer::N_MC,i,j
double precision::dummy,r_trial(d),r(d),s(d),xmin(d),xmax(d)
double precision,parameter::mv_cutoff=0.1
Moment=0d0
r=0d0
xmin=r
xmax=r
do i=1,N_MC
!==============================================================================!
!                   Generate coordinates for Random move
!           random numbers generated (0,1), make it (-1,1) ==> s=2*s-1
!==============================================================================!
  call random_number(s)
  r_trial=r+mv_cutoff*(2*s-1)
!==============================================================================!
!                             Test Acceptance
!==============================================================================!
  call random_number(dummy)
  if(P(r_trial)/P(r).ge.dummy) then
    r=r_trial
    do j=1,d
      if(xmin(j)>r(j)) xmin(j)=r(j)
      if(xmax(j)<r(j)) xmax(j)=r(j)
    enddo
  endif
enddo
end subroutine Moments_MMC
!==============================================================================!
!We have adapted the original amoeba subroutine made available by J-P Moreau
!Special thanks for making this code available!
!   http://jean-pierre.moreau.pagesperso-orange.fr/Fortran/tamoeba_f90.txt
!See Numerical Recipies for more details on downhill simplex minimization
!==============================================================================!
SUBROUTINE AMOEBA(P,Y,Npar,FTOL,ITER)
!==============================================================================!
! Multidimensional minimization of the function f(X) where X is
! an Npar-dimensional vector, by the downhill simplex method of
! Nelder and Mead. Input is a matrix P whose Npar+1 rows are Npar-
! dimensional vectors which are the vertices of the starting simplex
! (Logical dimensions of P are P(Npar+1,Npar); physical dimensions
! are input as P(Npar+1,Npar)). Also input is the vector Y of length Npar
! +1, whose components must be pre-initialized to the values of f
! evaluated at the Npar+1 vertices (rows) of P; and FTOL the fractio-
! nal convergence tolerance to be achieved in the function value. On
! output, P and Y will have been reset to Npar+1 new points all within
! FTOL of a minimum function value, and ITER gives the number of ite-
! rations taken.
!==============================================================================!
!VM:  on input ITER is the maximum number of iterations to be perform
!on output it is the actual number of iterations
!==============================================================================!
implicit none
double precision, PARAMETER :: ALPHA=1.d0,BETA=0.5d0,GAMMA=2.d0
! Expected maximum number of dimensions, three parameters which define
! the expansions and contractions, and maximum allowed number of
! iterations.
integer Npar, ITER, MPTS, ILO, IHI, INHI, I, J, ITMAX
double precision ::  P(Npar+1,Npar), Y(Npar+1), PR(Npar), PRR(Npar), PBAR(Npar)
double precision :: FTOL, RTOL, YPR, YPRR
    ITMAX=ITER
    MPTS=Npar+1
    ITER=0
  1 ILO=1
    IF(Y(1).GT.Y(2)) THEN
       IHI=1
       INHI=2
    ELSE
       IHI=2
       INHI=1
    ENDIF
    DO I=1, MPTS
       IF(Y(I).LT.Y(ILO)) ILO=I
       IF(Y(I).GT.Y(IHI)) THEN
          INHI=IHI
          IHI=I
       ELSE IF (Y(I).GT.Y(INHI)) THEN
          IF(I.NE.IHI) INHI=I
       END IF
    END DO
    ! Compute the fractional range from highest to lowest and return if
    ! satisfactory.
    RTOL=2.d0*ABS(Y(IHI)-Y(ILO))/(ABS(Y(IHI))+ABS(Y(ILO)))
    IF(RTOL.LT.FTOL) RETURN
    IF(ITER.EQ.ITMAX) then
       write(*,*) ' Amoeba exceeding maximum iterations.'
       return
    endif
    ITER=ITER+1
    DO J=1, Npar
       PBAR(J)=0.d0
    END DO
    DO I=1, MPTS
       IF(I.NE.IHI) THEN
          DO J=1,Npar
             PBAR(J)=PBAR(J) + P(I,J)
          END DO
       END IF
    END DO
    DO J=1, Npar
       PBAR(J)=PBAR(J)/Npar
       PR(J)=(1.d0+ALPHA)*PBAR(J) - ALPHA*P(IHI,J)
    END DO
    YPR=f(PR)
    IF(YPR.LE.Y(ILO)) THEN
       DO J=1,Npar
          PRR(J)=GAMMA*PR(J) + (1.d0-GAMMA)*PBAR(J)
       END DO
       YPRR=f(PRR)
       IF(YPRR.LT.Y(ILO)) THEN
          DO J=1, Npar
             P(IHI,J)=PRR(J)
          END DO
          Y(IHI)=YPRR
       ELSE
          DO J=1, Npar
             P(IHI,J)=PR(J)
          END DO
          Y(IHI)=YPR
       END IF
    ELSE IF(YPR.GE.Y(INHI)) THEN
       IF(YPR.LT.Y(IHI)) THEN
          DO J=1, Npar
             P(IHI,J)=PR(J)
          END DO
          Y(IHI)=YPR
       END IF
       DO J=1, Npar
          PRR(J)=BETA*P(IHI,J) + (1.d0-BETA)*PBAR(J)
       END DO
       YPRR=f(PRR)
       IF(YPRR.LT.Y(IHI)) THEN
          DO J=1, Npar
             P(IHI,J)=PRR(J)
          END DO
          Y(IHI)=YPRR
       ELSE
          DO I=1, MPTS
             IF(I.NE.ILO) THEN
                DO J=1,Npar
                   PR(J)=0.5d0*(P(I,J) + P(ILO,J))
                   P(I,J)=PR(J)
                END DO
                Y(I)=f(PR)
             END IF
          END DO
       END IF
    ELSE
       DO J=1, Npar
          P(IHI,J)=PR(J)
       END DO
       Y(IHI)=YPR
    END IF
    GO TO 1
END SUBROUTINE AMOEBA
!==============================================================================!
end module qlj_mod
!==============================================================================!
program main
use qlj_mod
!==============================================================================!
!N_MC           ==># of MMC steps to distribute points
!N_MC_moments   ==># of MC moves to compute moments
!N_reg          ==># grid points in each dimension for moments with regular grid
!MMC_freq       ==>Interval to update MMC acceptance ratio
!accept         ==># of acceptances for adjusting trial move acceptance
!Delta_E        ==>change in energy due to trial move
!mv_cutoff      ==>maximum displacement factor for trial move
!Moment         ==>(0:5) 5 Lowest Moments for the distribution
!x0             ==>(d) store coordinate before
!U_move          file_in==>(Npoints)  qLJ-Energy for trial movement
!xmin           ==>(d) minimum for P(x) normalization box
!xmax           ==>(d) maximum of P(x) normalization box
!x              ==>(d,Npoints) All coordinates
!U              ==>(Npoints,Npoints) All i,j pair-wise energies
!Npar           ==> Number of parameters for simplex minimization (b, beta1)
!ITER           ==> Maximum number of iterations (on output, the actual number)
!FTOL           ==> tolerance for simplex minimization
!hissize        ==> the maximum of the histogram size
!==============================================================================!
implicit none
integer::N_MC,N_MC_moments,N_reg,MMC_freq,accept,counter,i,j,plt_count
integer::ITER,Npar,m,nh,xm,hissize,l1,l2
double precision::delx,dist,sigma,gr
double precision::Delta_E,deltae1,mv_cutoff,time1,time2,Moment(0:5),FTOL
double precision,allocatable,dimension(:)::x0,s,U_move,xmin(:),xmax(:)
double precision,allocatable,dimension(:,:)::U
double precision, allocatable :: PP(:,:), Y(:),hist(:,:),dist0(:,:)
!==============================================================================!
call cpu_time(time1)
read(*,*) d
read(*,*) Npoints
read(*,*) N_MC_moments
read(*,*) N_reg
read(*,*) N_MC
read(*,*) E_cut
read(*,*) c_LJ
read(*,*) Npar
read(*,*) ITER
read(*,*) FTOL
read(*,*) xm
read(*,*) delx
read(*,*) hissize
!==============================================================================!
!                               Allocations
!==============================================================================!
allocate(x(d,Npoints),x0(d),s(d),U(Npoints,Npoints),U_move(Npoints),xmin(d))
allocate(xmax(d))
allocate(PP(Npar+1,Npar), Y(Npar+1))
allocate(hist(hissize,6),dist0(Npoints,6))
write(*,*) 'Test 0; Successfully Read Input File'
!==============================================================================!
!                Run Monte Carlo to Normalize P/Get Moments
!==============================================================================!
integral_P=1d0                       !set equal to 1 so you can initially call P
call box_size(N_MC_moments,xmin,xmax)
do i=1,d
  write(*,*) i,' xmin xmax ==>', xmin(i),xmax(i)
enddo
xmin=xmin-(xmax-xmin)*0.01
xmax=xmax+(xmax-xmin)*0.01
call Moments_Reg(Moment,N_reg,xmin,xmax)
write(*,*) 'Normalization of P =', Integral_P
write(*,*) 'Test 1; Successfully normalized P(x)'
!==============================================================================!
!                       Generate Initial Distribution
!               Initally accept any point where Potential<Ecut
!==============================================================================!
i=1
do while(i.le.Npoints)
    call random_number(s)
    s(:)=xmin(:)+s(:)*(xmax(:)-xmin(:))
    if(V(s)<E_cut)then
        x(:,i)=s(:)
        i=i+1
    endif
enddo
!==============================================================================!
!                          Write Initial Coordinates
!==============================================================================!
open(unit=17,file='coor_ini.dat')
do i=1,Npoints
  write(17,*) x(:,i)
enddo
close(17)
!==============================================================================!
!                       Begin Simplex to Optimize GridPoints
!==============================================================================!
!                           Select Atom to Move
!==============================================================================!
do i=1,N_MC
  k=random_integer(1,Npoints)
  x0=x(:,k)
  PP(1,:)=(/x0(1),x0(2)/)
  PP(2,:) = PP(1,:) + (/0.05,0./)
  PP(3,:) = PP(1,:) + (/0.,0.05/)
  do m=1,Npar+1
    Y(m)=f(PP(m,:))
  enddo
  CALL AMOEBA(PP,Y,Npar,FTOL,ITER)

!==> select the minimum point
 if(Y(1).eq.min(Y(1),Y(2),Y(3))) then
  x(:,k)=PP(1,:)
 else if(Y(2).eq.min(Y(1),Y(2),Y(3))) then
  x(:,k)=PP(2,:)
 else
  x(:,k)=PP(3,:)
 endif

enddo

!==> Write Optimized Grid
open(unit=20,file='grid.dat')
do i=1,Npoints
  write(20,*) x(:,i)
enddo
close(20)
write(*,*) 'Successfully Generated Quasi-Regular Grid'

open(unit=71,file='d1.dat')
open(unit=72,file='d2.dat')
open(unit=73,file='d3.dat')
open(unit=74,file='d4.dat')
open(unit=75,file='d5.dat')
open(unit=76,file='d6.dat')

!==> Begin to calculate the correlation
dist0=1D7
hist=0

do i=1,Npoints
 sigma=c_LJ*(P(x(:,i))*Npoints)**(-1./d)
 do j=1,Npoints
  if(i.ne.j) then
   dist=sqrt(sum((x(:,i)-x(:,j))**2))
   if(dist.le.dist0(i,1)) then
    dist0(i,1)=dist
   else if(dist.le.dist0(i,2)) then
    dist0(i,2)=dist
   else if(dist.le.dist0(i,3)) then
    dist0(i,3)=dist
   else if(dist.le.dist0(i,4)) then
    dist0(i,4)=dist
   else if(dist.le.dist0(i,5)) then
    dist0(i,5)=dist
   else if(dist.le.dist0(i,6)) then
    dist0(i,6)=dist
   endif
  endif
 enddo
 do l1=1,6
  if(dist0(i,l1).ne.1D7)then
    gr=dist0(i,l1)/sigma-xm
   do l2=1,hissize
    if(gr.ge.(l2-1)*delx.and.gr.lt.l2*delx)then
     hist(l2,l1)=hist(l2,l1)+1
    endif
   enddo
  endif
 enddo
enddo

hist=hist/sum(hist)

do i=1,6
 do j=1,hissize
  write(70+i,*) (j-1)*delx, hist(j,i)
 enddo
enddo

end program main