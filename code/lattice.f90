!--------------------------------------------------------------------------------------------------
! $Id$
!--------------------------------------------------------------------------------------------------
!> @author Franz Roters, Max-Planck-Institut für Eisenforschung GmbH
!> @author Philip Eisenlohr, Max-Planck-Institut für Eisenforschung GmbH
!> @author Pratheek Shanthraj, Max-Planck-Institut für Eisenforschung GmbH
!> @author Martin Diehl, Max-Planck-Institut für Eisenforschung GmbH
!> @brief  defines lattice structure definitions, slip and twin system definitions, Schimd matrix
!>         calculation and non-Schmid behavior
!--------------------------------------------------------------------------------------------------
module lattice
 use prec, only: &
   pReal, &
   pInt

 implicit none
 private
 integer(pInt), parameter, public :: &
   LATTICE_maxNslipFamily  =  6_pInt, &                                                             !< max # of slip system families over lattice structures
   LATTICE_maxNtwinFamily  =  4_pInt, &                                                             !< max # of twin system families over lattice structures
   LATTICE_maxNslip        = 33_pInt, &                                                             !< max # of slip systems over lattice structures
   LATTICE_maxNtwin        = 24_pInt, &                                                             !< max # of twin systems over lattice structures
   LATTICE_maxNinteraction = 42_pInt, &                                                             !< max # of interaction types (in hardening matrix part)
   LATTICE_maxNnonSchmid   = 6_pInt                                                                 !< max # of non schmid contributions over lattice structures
 
 integer(pInt), allocatable, dimension(:,:), protected, public :: &
   lattice_NslipSystem, &                                                                           !< total # of slip systems in each family
   lattice_NtwinSystem                                                                              !< total # of twin systems in each family

 integer(pInt), allocatable, dimension(:,:,:), protected, public :: &
   lattice_interactionSlipSlip, &                                                                   !< Slip--slip interaction type 
   lattice_interactionSlipTwin, &                                                                   !< Slip--twin interaction type 
   lattice_interactionTwinSlip, &                                                                   !< Twin--slip interaction type 
   lattice_interactionTwinTwin                                                                      !< Twin--twin interaction type 


 real(pReal), allocatable, dimension(:,:,:,:,:), protected, public :: &
   lattice_Sslip                                                                                    !< Schmid and non-Schmid matrices
  
 real(pReal), allocatable, dimension(:,:,:,:), protected, public :: &
   lattice_Sslip_v                                                                                  !< Mandel notation of lattice_Sslip
  
 real(pReal), allocatable, dimension(:,:,:), protected, public :: &
   lattice_sn, &                                                                                    !< normal direction of slip system
   lattice_sd, &                                                                                    !< slip direction of slip system
   lattice_st                                                                                       !< sd x sn

! rotation and Schmid matrices, normal, shear direction and d x n of twin systems
 real(pReal), allocatable, dimension(:,:,:,:), protected, public  :: &
   lattice_Stwin, &
   lattice_Qtwin

 real(pReal), allocatable, dimension(:,:,:), protected, public :: &
   lattice_Stwin_v, &
   lattice_tn, &
   lattice_td, &
   lattice_tt

 real(pReal), allocatable, dimension(:,:), protected, public :: &
   lattice_shearTwin                                                                                !< characteristic twin shear
   
 integer(pInt), allocatable, dimension(:), protected, public :: &
   lattice_NnonSchmid                                                                               !< total # of non-Schmid contributions for each structure

!--------------------------------------------------------------------------------------------------
! fcc
 integer(pInt), dimension(lattice_maxNslipFamily), parameter, public :: & 
   LATTICE_fcc_NslipSystem = int([12, 0, 0, 0, 0, 0],pInt)                                          !< total # of slip systems per family for fcc
   
 integer(pInt), dimension(lattice_maxNtwinFamily), parameter, public :: &
   lattice_fcc_NtwinSystem = int([12, 0, 0, 0],pInt)                                                !< total # of twin systems per family for fcc
   
 integer(pInt), parameter, private  :: &
   lattice_fcc_Nslip = 12_pInt, & ! sum(lattice_fcc_NslipSystem), &                                 !< total # of slip systems for fcc
   lattice_fcc_Ntwin = 12_pInt, & ! sum(lattice_fcc_NtwinSystem)                                    !< total # of twin systems for fcc
   lattice_fcc_NnonSchmid = 0_pInt                                                                  !< total # of non-Schmid contributions for fcc
 
 real(pReal), dimension(3+3,lattice_fcc_Nslip), parameter, private :: &
   lattice_fcc_systemSlip = reshape(real([&
    ! Slip direction     Plane normal
      0, 1,-1,     1, 1, 1, &
     -1, 0, 1,     1, 1, 1, &
      1,-1, 0,     1, 1, 1, &
      0,-1,-1,    -1,-1, 1, &
      1, 0, 1,    -1,-1, 1, &
     -1, 1, 0,    -1,-1, 1, &
      0,-1, 1,     1,-1,-1, &
     -1, 0,-1,     1,-1,-1, &
      1, 1, 0,     1,-1,-1, &
      0, 1, 1,    -1, 1,-1, &
      1, 0,-1,    -1, 1,-1, &
     -1,-1, 0,    -1, 1,-1  &
     ],pReal),[ 3_pInt + 3_pInt,lattice_fcc_Nslip])                                                 !< Slip system <110>{111} directions. Sorted according to Eisenlohr & Hantcherli

 real(pReal), dimension(3+3,lattice_fcc_Ntwin), parameter, private :: &
   lattice_fcc_systemTwin = reshape(real( [&
     -2, 1, 1,     1, 1, 1, &
      1,-2, 1,     1, 1, 1, &
      1, 1,-2,     1, 1, 1, &
      2,-1, 1,    -1,-1, 1, &
     -1, 2, 1,    -1,-1, 1, &
     -1,-1,-2,    -1,-1, 1, &
     -2,-1,-1,     1,-1,-1, &
      1, 2,-1,     1,-1,-1, &
      1,-1, 2,     1,-1,-1, &
      2, 1,-1,    -1, 1,-1, &
     -1,-2,-1,    -1, 1,-1, &
     -1, 1, 2,    -1, 1,-1  &
     ],pReal),[ 3_pInt + 3_pInt ,lattice_fcc_Ntwin])                                                !< Twin system <112>{111} directions. Sorted according to Eisenlohr & Hantcherli

 real(pReal), dimension(lattice_fcc_Ntwin), parameter, private :: &
   lattice_fcc_shearTwin = 0.5_pReal*sqrt(2.0_pReal)                                                !< Twin system <112>{111} ??? Sorted according to Eisenlohr & Hantcherli

 integer(pInt), dimension(2_pInt,lattice_fcc_Ntwin), parameter, public :: &
   lattice_fcc_twinNucleationSlipPair = reshape(int( [&
     2,3, &
     1,3, &
     1,2, &
     5,6, &
     4,6, &
     4,5, &
     8,9, &
     7,9, &
     7,8, &
     11,12, &
     10,12, &
     10,11 &
     ],pInt),[2_pInt,lattice_fcc_Ntwin])

 integer(pInt), dimension(lattice_fcc_Nslip,lattice_fcc_Nslip), parameter, public :: &
   lattice_fcc_interactionSlipSlip = reshape(int( [&
     1,2,2,4,6,5,3,5,5,4,5,6, &  ! ---> slip
     2,1,2,6,4,5,5,4,6,5,3,5, &  ! |
     2,2,1,5,5,3,5,6,4,6,5,4, &  ! |
     4,6,5,1,2,2,4,5,6,3,5,5, &  ! v slip
     6,4,5,2,1,2,5,3,5,5,4,6, &
     5,5,3,2,2,1,6,5,4,5,6,4, &
     3,5,5,4,5,6,1,2,2,4,6,5, &
     5,4,6,5,3,5,2,1,2,6,4,5, &
     5,6,4,6,5,4,2,2,1,5,5,3, &
     4,5,6,3,5,5,4,6,5,1,2,2, &
     5,3,5,5,4,6,6,4,5,2,1,2, &
     6,5,4,5,6,4,5,5,3,2,2,1  &
     ],pInt),[lattice_fcc_Nslip,lattice_fcc_Nslip],order=[2,1])                                     !< Slip--slip interaction types for fcc
                                                                                                    !< 1: self interaction
                                                                                                    !< 2: coplanar interaction
                                                                                                    !< 3: collinear interaction
                                                                                                    !< 4: Hirth locks
                                                                                                    !< 5: glissile junctions
                                                                                                    !< 6: Lomer locks
 integer(pInt), dimension(lattice_fcc_Nslip,lattice_fcc_Ntwin), parameter, public :: &
   lattice_fcc_interactionSlipTwin = reshape(int( [&
     1,1,1,3,3,3,2,2,2,3,3,3, & ! ---> twin
     1,1,1,3,3,3,3,3,3,2,2,2, & ! |
     1,1,1,2,2,2,3,3,3,3,3,3, & ! |
     3,3,3,1,1,1,3,3,3,2,2,2, & ! v slip
     3,3,3,1,1,1,2,2,2,3,3,3, &
     2,2,2,1,1,1,3,3,3,3,3,3, &
     2,2,2,3,3,3,1,1,1,3,3,3, &
     3,3,3,2,2,2,1,1,1,3,3,3, &
     3,3,3,3,3,3,1,1,1,2,2,2, &
     3,3,3,2,2,2,3,3,3,1,1,1, &
     2,2,2,3,3,3,3,3,3,1,1,1, &
     3,3,3,3,3,3,2,2,2,1,1,1  &
     ],pInt),[lattice_fcc_Nslip,lattice_fcc_Ntwin],order=[2,1])                                     !< Slip--twin interaction types for fcc
                                                                                                    !< 1: coplanar interaction
                                                                                                    !< 2: screw trace between slip system and twin habit plane (easy cross slip)
                                                                                                    !< 3: other interaction
 integer(pInt), dimension(lattice_fcc_Ntwin,lattice_fcc_Nslip), parameter, public :: &
   lattice_fcc_interactionTwinSlip = 1_pInt                                                         !< Twin--Slip interaction types for fcc

 integer(pInt), dimension(lattice_fcc_Ntwin,lattice_fcc_Ntwin), parameter,public :: &
   lattice_fcc_interactionTwinTwin = reshape(int( [&
     1,1,1,2,2,2,2,2,2,2,2,2, &  ! ---> twin
     1,1,1,2,2,2,2,2,2,2,2,2, &  ! |
     1,1,1,2,2,2,2,2,2,2,2,2, &  ! |
     2,2,2,1,1,1,2,2,2,2,2,2, &  ! v twin
     2,2,2,1,1,1,2,2,2,2,2,2, &
     2,2,2,1,1,1,2,2,2,2,2,2, &
     2,2,2,2,2,2,1,1,1,2,2,2, &
     2,2,2,2,2,2,1,1,1,2,2,2, &
     2,2,2,2,2,2,1,1,1,2,2,2, &
     2,2,2,2,2,2,2,2,2,1,1,1, &
     2,2,2,2,2,2,2,2,2,1,1,1, &
     2,2,2,2,2,2,2,2,2,1,1,1  &
     ],pInt),[lattice_fcc_Ntwin,lattice_fcc_Ntwin],order=[2,1])                                     !< Twin--twin interaction types for fcc
     
 
 
!--------------------------------------------------------------------------------------------------
! bcc
 integer(pInt), dimension(lattice_maxNslipFamily), parameter, public :: &
   lattice_bcc_NslipSystem = int([ 12, 12, 0, 0, 0, 0], pInt)                                       !< total # of slip systems per family for bcc
   
 integer(pInt), dimension(lattice_maxNtwinFamily), parameter, public :: &
   lattice_bcc_NtwinSystem = int([ 12, 0, 0, 0], pInt)                                              !< total # of twin systems per family for bcc
   
 integer(pInt), parameter, private  :: &
   lattice_bcc_Nslip = 24_pInt, & ! sum(lattice_bcc_NslipSystem), &                                 !< total # of slip systems for bcc
   lattice_bcc_Ntwin = 12_pInt, & ! sum(lattice_bcc_NtwinSystem)                                    !< total # of twin systems for bcc
   lattice_bcc_NnonSchmid = 6_pInt                                                                  !< # of non-Schmid contributions for bcc. 6 known non schmid contributions for BCC (A. Koester, A. Ma, A. Hartmaier 2012)
   
 real(pReal), dimension(3+3,lattice_bcc_Nslip), parameter, private :: &
   lattice_bcc_systemSlip = reshape(real([&
    ! Slip direction     Plane normal
    ! Slip system <111>{110} 
      1,-1, 1,     0, 1, 1, &
     -1,-1, 1,     0, 1, 1, &
      1, 1, 1,     0,-1, 1, &
     -1, 1, 1,     0,-1, 1, &
     -1, 1, 1,     1, 0, 1, &
     -1,-1, 1,     1, 0, 1, &
      1, 1, 1,    -1, 0, 1, &
      1,-1, 1,    -1, 0, 1, &
     -1, 1, 1,     1, 1, 0, &
     -1, 1,-1,     1, 1, 0, &
      1, 1, 1,    -1, 1, 0, &
      1, 1,-1,    -1, 1, 0, &
    ! Slip system <111>{112}
     -1, 1, 1,     2, 1, 1, &
      1, 1, 1,    -2, 1, 1, &
      1, 1,-1,     2,-1, 1, &
      1,-1, 1,     2, 1,-1, &
      1,-1, 1,     1, 2, 1, &
      1, 1,-1,    -1, 2, 1, &
      1, 1, 1,     1,-2, 1, &
     -1, 1, 1,     1, 2,-1, &
      1, 1,-1,     1, 1, 2, &
      1,-1, 1,    -1, 1, 2, &
     -1, 1, 1,     1,-1, 2, &
      1, 1, 1,     1, 1,-2  &
   !  Slip system <111>{123}
   !  1, 1,-1,     1, 2, 3, &
   !  1,-1, 1,    -1, 2, 3, &
   ! -1, 1, 1,     1,-2, 3, &
   !  1, 1, 1,     1, 2,-3, &
   !  1,-1, 1,     1, 3, 2, &
   !  1, 1,-1,    -1, 3, 2, &
   !  1, 1, 1,     1,-3, 2, &
   ! -1, 1, 1,     1, 3,-2, &
   !  1, 1,-1,     2, 1, 3, &
   !  1,-1, 1,    -2, 1, 3, &
   ! -1, 1, 1,     2,-1, 3, &
   !  1, 1, 1,     2, 1,-3, &
   !  1,-1, 1,     2, 3, 1, &
   !  1, 1,-1,    -2, 3, 1, &
   !  1, 1, 1,     2,-3, 1, &
   ! -1, 1, 1,     2, 3,-1, &
   ! -1, 1, 1,     3, 1, 2, &
   !  1, 1, 1,    -3, 1, 2, &
   !  1, 1,-1,     3,-1, 2, &
   !  1,-1, 1,     3, 1,-2, &
   ! -1, 1, 1,     3, 2, 1, &
   !  1, 1, 1,    -3, 2, 1, &
   !  1, 1,-1,     3,-2, 1, &
   !  1,-1, 1,     3, 2,-1  &
     ],pReal),[ 3_pInt + 3_pInt ,lattice_bcc_Nslip])

 real(pReal), dimension(3+3,lattice_bcc_Ntwin), parameter, private :: &
   lattice_bcc_systemTwin = reshape(real([&
    ! Twin system <111>{112}
     -1, 1, 1,     2, 1, 1, &
      1, 1, 1,    -2, 1, 1, &
      1, 1,-1,     2,-1, 1, &
      1,-1, 1,     2, 1,-1, &
      1,-1, 1,     1, 2, 1, &
      1, 1,-1,    -1, 2, 1, &
      1, 1, 1,     1,-2, 1, &
     -1, 1, 1,     1, 2,-1, &
      1, 1,-1,     1, 1, 2, &
      1,-1, 1,    -1, 1, 2, &
     -1, 1, 1,     1,-1, 2, &
      1, 1, 1,     1, 1,-2  &
     ],pReal),[ 3_pInt + 3_pInt,lattice_bcc_Ntwin])

 real(pReal), dimension(lattice_bcc_Ntwin), parameter, private :: &
   lattice_bcc_shearTwin = 0.5_pReal*sqrt(2.0_pReal)

 integer(pInt), dimension(lattice_bcc_Nslip,lattice_bcc_Nslip), parameter, public :: &
   lattice_bcc_interactionSlipSlip = reshape(int( [&
     1,2,6,6,5,4,4,3,4,3,5,4, 6,6,4,3,3,4,6,6,4,3,6,6, &  ! ---> slip  
     2,1,6,6,4,3,5,4,5,4,4,3, 6,6,3,4,4,3,6,6,3,4,6,6, &  ! |
     6,6,1,2,4,5,3,4,4,5,3,4, 4,3,6,6,6,6,3,4,6,6,4,3, &  ! |
     6,6,2,1,3,4,4,5,3,4,4,5, 3,4,6,6,6,6,4,3,6,6,3,4, &  ! v slip
     5,4,4,3,1,2,6,6,3,4,5,4, 3,6,4,6,6,4,6,3,4,6,3,6, &
     4,3,5,4,2,1,6,6,4,5,4,3, 4,6,3,6,6,3,6,4,3,6,4,6, &
     4,5,3,4,6,6,1,2,5,4,3,4, 6,3,6,4,4,6,3,6,6,4,6,3, &
     3,4,4,5,6,6,2,1,4,3,4,5, 6,4,6,3,3,6,4,6,6,3,6,4, &
     4,5,4,3,3,4,5,4,1,2,6,6, 3,6,6,4,4,6,6,3,6,4,3,6, &
     3,4,5,4,4,5,4,3,2,1,6,6, 4,6,6,3,3,6,6,4,6,3,4,6, &
     5,4,3,4,5,4,3,4,6,6,1,2, 6,3,4,6,6,4,3,6,4,6,6,3, &
     4,3,4,5,4,3,4,5,6,6,2,1, 6,4,3,6,6,3,4,6,3,6,6,4, &
     !
     6,6,4,3,3,4,6,6,3,4,6,6, 1,5,6,6,5,6,6,3,5,6,3,6, &
     6,6,3,4,6,6,3,4,6,6,3,4, 5,1,6,6,6,5,3,6,6,5,6,3, &
     4,3,6,6,4,3,6,6,6,6,4,3, 6,6,1,5,6,3,5,6,3,6,5,6, &
     3,4,6,6,6,6,4,3,4,3,6,6, 6,6,5,1,3,6,6,5,6,3,6,5, &
     3,4,6,6,6,6,4,3,4,3,6,6, 5,6,6,3,1,6,5,6,5,3,6,6, &
     4,3,6,6,4,3,6,6,6,6,4,3, 6,5,3,6,6,1,6,5,3,5,6,6, &
     6,6,3,4,6,6,3,4,6,6,3,4, 6,3,5,6,5,6,1,6,6,6,5,3, &
     6,6,4,3,3,4,6,6,3,4,6,6, 3,6,6,5,6,5,6,1,6,6,3,5, &
     4,3,6,6,4,3,6,6,6,6,4,3, 5,6,3,6,5,3,6,6,1,6,6,5, &
     3,4,6,6,6,6,4,3,4,3,6,6, 6,5,6,3,3,5,6,6,6,1,5,6, &
     6,6,4,3,3,4,6,6,3,4,6,6, 3,6,5,6,6,6,5,3,6,5,1,6, &
     6,6,3,4,6,6,3,4,6,6,3,4, 6,3,6,5,6,6,3,5,5,6,6,1  &
     ],pInt),[lattice_bcc_Nslip,lattice_bcc_Nslip],order=[2,1])                                     !< Slip--slip interaction types for bcc from Queyreau et al. Int J Plast 25 (2009) 361–377
                                                                                                    !< 1: self interaction
                                                                                                    !< 2: coplanar interaction
                                                                                                    !< 3: collinear interaction
                                                                                                    !< 4: mixed-asymmetrical junction
                                                                                                    !< 5: mixed-symmetrical junction
                                                                                                    !< 6: edge junction
 integer(pInt), dimension(lattice_bcc_Nslip,lattice_bcc_Ntwin), parameter, public :: &
  lattice_bcc_interactionSlipTwin = reshape(int( [&
     3,3,3,2,2,3,3,3,3,2,3,3, &  ! ---> twin
     3,3,2,3,3,2,3,3,2,3,3,3, &  ! |
     3,2,3,3,3,3,2,3,3,3,3,2, &  ! |
     2,3,3,3,3,3,3,2,3,3,2,3, &  ! v slip 
     2,3,3,3,3,3,3,2,3,3,2,3, &
     3,3,2,3,3,2,3,3,2,3,3,3, &
     3,2,3,3,3,3,2,3,3,3,3,2, &
     3,3,3,2,2,3,3,3,3,2,3,3, &
     2,3,3,3,3,3,3,2,3,3,2,3, &
     3,3,3,2,2,3,3,3,3,2,3,3, &
     3,2,3,3,3,3,2,3,3,3,3,2, &
     3,3,2,3,3,2,3,3,2,3,3,3, &
     !
     1,3,3,3,3,3,3,2,3,3,2,3, &
     3,1,3,3,3,3,2,3,3,3,3,2, &
     3,3,1,3,3,2,3,3,2,3,3,3, &
     3,3,3,1,2,3,3,3,3,2,3,3, &
     3,3,3,2,1,3,3,3,3,2,3,3, &
     3,3,2,3,3,1,3,3,2,3,3,3, &
     3,2,3,3,3,3,1,3,3,3,3,2, &
     2,3,3,3,3,3,3,1,3,3,2,3, &
     3,3,2,3,3,2,3,3,1,3,3,3, &
     3,3,3,2,2,3,3,3,3,1,3,3, &
     2,3,3,3,3,3,3,2,3,3,1,3, &
     3,2,3,3,3,3,2,3,3,3,3,1  &
     ],pInt),[lattice_bcc_Nslip,lattice_bcc_Ntwin],order=[2,1])                                     !< Slip--twin interaction types for bcc
                                                                                                    !< 1: coplanar interaction
                                                                                                    !< 2: screw trace between slip system and twin habit plane (easy cross slip)
                                                                                                    !< 3: other interaction
 integer(pInt), dimension(lattice_bcc_Ntwin,lattice_bcc_Nslip), parameter, public :: &
   lattice_bcc_interactionTwinSlip = 1_pInt                                                         !< Twin--slip interaction types for bcc @todo not implemented yet

 integer(pInt), dimension(lattice_bcc_Ntwin,lattice_bcc_Ntwin), parameter, public :: &
   lattice_bcc_interactionTwinTwin = reshape(int( [&
     1,3,3,3,3,3,3,2,3,3,2,3, &  ! ---> twin
     3,1,3,3,3,3,2,3,3,3,3,2, &  ! |
     3,3,1,3,3,2,3,3,2,3,3,3, &  ! |
     3,3,3,1,2,3,3,3,3,2,3,3, &  ! v twin
     3,3,3,2,1,3,3,3,3,2,3,3, &
     3,3,2,3,3,1,3,3,2,3,3,3, &
     3,2,3,3,3,3,1,3,3,3,3,2, &
     2,3,3,3,3,3,3,1,3,3,2,3, &
     3,3,2,3,3,2,3,3,1,3,3,3, &
     3,3,3,2,2,3,3,3,3,1,3,3, &
     2,3,3,3,3,3,3,2,3,3,1,3, &
     3,2,3,3,3,3,2,3,3,3,3,1  &
     ],pInt),[lattice_bcc_Ntwin,lattice_bcc_Ntwin],order=[2,1])                                     !< Twin--twin interaction types for bcc
                                                                                                    !< 1: self interaction
                                                                                                    !< 2: collinear interaction
                                                                                                    !< 3: other interaction
 

!--------------------------------------------------------------------------------------------------
! hex
 integer(pInt), dimension(lattice_maxNslipFamily), parameter, public :: &
   lattice_hex_NslipSystem = int([ 3, 3, 3, 6, 12, 6],pInt)                                         !< # of slip systems per family for hex
   
 integer(pInt), dimension(lattice_maxNtwinFamily), parameter, public :: &
   lattice_hex_NtwinSystem = int([ 6, 6, 6, 6],pInt)                                                !< # of slip systems per family for hex 
   
 integer(pInt), parameter , private :: &
   lattice_hex_Nslip = 33_pInt, & ! sum(lattice_hex_NslipSystem),                                   !< total # of slip systems for hex 
   lattice_hex_Ntwin = 24_pInt, & ! sum(lattice_hex_NtwinSystem)                                    !< total # of twin systems for hex
   lattice_hex_NnonSchmid = 0_pInt                                                                  !< # of non-Schmid contributions for hex

 real(pReal), dimension(4+4,lattice_hex_Nslip), parameter, private :: &
   lattice_hex_systemSlip = reshape(real([&
    ! Slip direction     Plane normal
    ! Basal systems <11.0>{00.1} (independent of c/a-ratio, Bravais notation (4 coordinate base))
      2, -1, -1,  0,     0,  0,  0,  1, &
     -1,  2, -1,  0,     0,  0,  0,  1, &
     -1, -1,  2,  0,     0,  0,  0,  1, &
    ! 1st type prismatic systems <11.0>{10.0}  (independent of c/a-ratio)
      2, -1, -1,  0,     0,  1, -1,  0, &
     -1,  2, -1,  0,    -1,  0,  1,  0, &
     -1, -1,  2,  0,     1, -1,  0,  0, &
    ! 2nd type prismatic systems <10.0>{11.0} -- a slip; plane normals independent of c/a-ratio
      0,  1,  -1, 0,     2, -1, -1,  0, &
     -1,  0,  1,  0,    -1,  2, -1,  0, &
      1, -1,  0,  0,    -1, -1,  2,  0,  &
    ! 1st type 1st order pyramidal systems <11.0>{-11.1} -- plane normals depend on the c/a-ratio
      2, -1, -1,  0,     0,  1, -1,  1, &
     -1,  2, -1,  0,    -1,  0,  1,  1, &
     -1, -1,  2,  0,     1, -1,  0,  1, &
      1,  1, -2,  0,    -1,  1,  0,  1, &
     -2,  1,  1,  0,     0, -1,  1,  1, &
      1, -2,  1,  0,     1,  0, -1,  1, &
    ! pyramidal system: c+a slip <11.3>{-10.1} -- plane normals depend on the c/a-ratio
      2, -1, -1,  3,    -1,  1,  0,  1, &
      1, -2,  1,  3,    -1,  1,  0,  1, &
     -1, -1,  2,  3,     1,  0, -1,  1, &
     -2,  1,  1,  3,     1,  0, -1,  1, &
     -1,  2, -1,  3,     0, -1,  1,  1, &
      1,  1, -2,  3,     0, -1,  1,  1, &
     -2,  1,  1,  3,     1, -1,  0,  1, &
     -1,  2, -1,  3,     1, -1,  0,  1, &
      1,  1, -2,  3,    -1,  0,  1,  1, &
      2, -1, -1,  3,    -1,  0,  1,  1, &
      1, -2,  1,  3,     0,  1, -1,  1, &
     -1, -1,  2,  3,     0,  1, -1,  1, &
    ! pyramidal system: c+a slip <11.3>{-1-1.2} -- as for hexagonal ice (Castelnau et al. 1996, similar to twin system found below) 
      2, -1, -1,  3,    -2,  1,  1,  2, & ! sorted according to similar twin system
     -1,  2, -1,  3,     1, -2,  1,  2, & ! <11.3>{-1-1.2} shear = 2((c/a)^2-2)/(3 c/a)
     -1, -1,  2,  3,     1,  1, -2,  2, &
     -2,  1,  1,  3,     2, -1, -1,  2, &
      1, -2,  1,  3,    -1,  2, -1,  2, &
      1,  1, -2,  3,    -1, -1,  2,  2  &
     ],pReal),[ 4_pInt + 4_pInt,lattice_hex_Nslip])                                                 !< slip systems for hex sorted by A. Alankar & P. Eisenlohr

 real(pReal), dimension(4+4,lattice_hex_Ntwin), parameter, private :: &
   lattice_hex_systemTwin =  reshape(real([&
    ! Compression or Tension =f(twinning shear=f(c/a)) for each metal ! (according to Yoo 1981)
      1, -1,  0,  1,    -1,  1,  0,  2, & ! <-10.1>{10.2} shear = (3-(c/a)^2)/(sqrt(3) c/a)
     -1,  0,  1,  1,     1,  0, -1,  2, &
      0,  1, -1,  1,     0, -1,  1,  2, &
     -1,  1,  0,  1,     1, -1,  0,  2, &
      1,  0, -1,  1,    -1,  0,  1,  2, &
      0, -1,  1,  1,     0,  1, -1,  2, &
!
      2, -1, -1,  6,    -2,  1,  1,  1, & ! <11.6>{-1-1.1} shear = 1/(c/a)
     -1,  2, -1,  6,     1, -2,  1,  1, &
     -1, -1,  2,  6,     1,  1, -2,  1, &
     -2,  1,  1,  6,     2, -1, -1,  1, &
      1, -2,  1,  6,    -1,  2, -1,  1, &
      1,  1, -2,  6,    -1, -1,  2,  1, &
!
     -1,  1,  0, -2,    -1,  1,  0,  1, & !! <10.-2>{10.1} shear = (4(c/a)^2-9)/(4 sqrt(3) c/a)
      1,  0, -1, -2,     1,  0, -1,  1, &
      0, -1,  1, -2,     0, -1,  1,  1, &
      1, -1,  0, -2,     1, -1,  0,  1, &
     -1,  0,  1, -2,    -1,  0,  1,  1, &
      0,  1, -1, -2,     0,  1, -1,  1, &
!
      2, -1, -1, -3,     2, -1, -1,  2, & ! <11.-3>{11.2} shear = 2((c/a)^2-2)/(3 c/a)
     -1,  2, -1, -3,    -1,  2, -1,  2, &
     -1, -1,  2, -3,    -1, -1,  2,  2, &
     -2,  1,  1, -3,    -2,  1,  1,  2, &
      1, -2,  1, -3,     1, -2,  1,  2, &
      1,  1, -2, -3,     1,  1, -2,  2  &
     ],pReal),[ 4_pInt + 4_pInt ,lattice_hex_Ntwin])                                                !< twin systems for hex, order follows Prof. Tom Bieler's scheme; but numbering in data was restarted from 1 

 integer(pInt), dimension(lattice_hex_Ntwin), parameter, private :: &
   lattice_hex_shearTwin = reshape(int( [&   ! indicator to formula further below
     1, &  ! <-10.1>{10.2}
     1, &
     1, &
     1, &
     1, &
     1, &
     2, &  ! <11.6>{-1-1.1}
     2, &
     2, &
     2, &
     2, &
     2, &
     3, &  ! <10.-2>{10.1}
     3, &
     3, &
     3, &
     3, &
     3, &
     4, &  ! <11.-3>{11.2}
     4, &
     4, &
     4, &
     4, &
     4  &
     ],pInt),[lattice_hex_Ntwin])
   
 integer(pInt), dimension(lattice_hex_Nslip,lattice_hex_Nslip), parameter, public :: &
   lattice_hex_interactionSlipSlip = reshape(int( [&
      1, 2, 2,   3, 3, 3,   7, 7, 7,  13,13,13,13,13,13,  21,21,21,21,21,21,21,21,21,21,21,21,  31,31,31,31,31,31, &  ! ---> slip
      2, 1, 2,   3, 3, 3,   7, 7, 7,  13,13,13,13,13,13,  21,21,21,21,21,21,21,21,21,21,21,21,  31,31,31,31,31,31, &  ! |
      2, 2, 1,   3, 3, 3,   7, 7, 7,  13,13,13,13,13,13,  21,21,21,21,21,21,21,21,21,21,21,21,  31,31,31,31,31,31, &  ! |
    !                                                                                                                   v slip
      6, 6, 6,   4, 5, 5,   8, 8, 8,  14,14,14,14,14,14,  22,22,22,22,22,22,22,22,22,22,22,22,  32,32,32,32,32,32, &
      6, 6, 6,   5, 4, 5,   8, 8, 8,  14,14,14,14,14,14,  22,22,22,22,22,22,22,22,22,22,22,22,  32,32,32,32,32,32, &
      6, 6, 6,   5, 5, 4,   8, 8, 8,  14,14,14,14,14,14,  22,22,22,22,22,22,22,22,22,22,22,22,  32,32,32,32,32,32, &
    !
     12,12,12,  11,11,11,   9,10,10,  15,15,15,15,15,15,  23,23,23,23,23,23,23,23,23,23,23,23,  33,33,33,33,33,33, &
     12,12,12,  11,11,11,  10, 9,10,  15,15,15,15,15,15,  23,23,23,23,23,23,23,23,23,23,23,23,  33,33,33,33,33,33, &
     12,12,12,  11,11,11,  10,10, 9,  15,15,15,15,15,15,  23,23,23,23,23,23,23,23,23,23,23,23,  33,33,33,33,33,33, &
    !
     20,20,20,  19,19,19,  18,18,18,  16,17,17,17,17,17,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
     20,20,20,  19,19,19,  18,18,18,  17,16,17,17,17,17,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
     20,20,20,  19,19,19,  18,18,18,  17,17,16,17,17,17,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
     20,20,20,  19,19,19,  18,18,18,  17,17,17,16,17,17,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
     20,20,20,  19,19,19,  18,18,18,  17,17,17,17,16,17,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
     20,20,20,  19,19,19,  18,18,18,  17,17,17,17,17,16,  24,24,24,24,24,24,24,24,24,24,24,24,  34,34,34,34,34,34, &
    !
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  25,26,26,26,26,26,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,25,26,26,26,26,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,25,26,26,26,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,25,26,26,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,25,26,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,25,26,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,25,26,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,26,25,26,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,26,26,25,26,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,26,26,26,25,26,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,26,26,26,26,25,26,  35,35,35,35,35,35, &
     30,30,30,  29,29,29,  28,28,28,  27,27,27,27,27,27,  26,26,26,26,26,26,26,26,26,26,26,25,  35,35,35,35,35,35, &
    !
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  36,37,37,37,37,37, &
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  37,36,37,37,37,37, &
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  37,37,36,37,37,37, &
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  37,37,37,36,37,37, &
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  37,37,37,37,36,37, &
     42,42,42,  41,41,41,  40,40,40,  39,39,39,39,39,39,  38,38,38,38,38,38,38,38,38,38,38,38,  37,37,37,37,37,36  &  
    !
           ],pInt),[lattice_hex_Nslip,lattice_hex_Nslip],order=[2,1])                                     !< Slip--slip interaction types for hex (32? in total)
  
 integer(pInt), dimension(lattice_hex_Nslip,lattice_hex_Ntwin), parameter, public :: &
   lattice_hex_interactionSlipTwin = reshape(int( [&
      1, 1, 1, 1, 1, 1,   2, 2, 2, 2, 2, 2,   3, 3, 3, 3, 3, 3,   4, 4, 4, 4, 4, 4, & ! --> twin
      1, 1, 1, 1, 1, 1,   2, 2, 2, 2, 2, 2,   3, 3, 3, 3, 3, 3,   4, 4, 4, 4, 4, 4, & ! |
      1, 1, 1, 1, 1, 1,   2, 2, 2, 2, 2, 2,   3, 3, 3, 3, 3, 3,   4, 4, 4, 4, 4, 4, & ! |
    !                                                                                   v
      5, 5, 5, 5, 5, 5,   6, 6, 6, 6, 6, 6,   7, 7, 7, 7, 7, 7,   8, 8, 8, 8, 8, 8, & ! slip
      5, 5, 5, 5, 5, 5,   6, 6, 6, 6, 6, 6,   7, 7, 7, 7, 7, 7,   8, 8, 8, 8, 8, 8, & 
      5, 5, 5, 5, 5, 5,   6, 6, 6, 6, 6, 6,   7, 7, 7, 7, 7, 7,   8, 8, 8, 8, 8, 8, &
    !
      9, 9, 9, 9, 9, 9,  10,10,10,10,10,10,  11,11,11,11,11,11,  12,12,12,12,12,12, &
      9, 9, 9, 9, 9, 9,  10,10,10,10,10,10,  11,11,11,11,11,11,  12,12,12,12,12,12, &
      9, 9, 9, 9, 9, 9,  10,10,10,10,10,10,  11,11,11,11,11,11,  12,12,12,12,12,12, &
    !
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
     13,13,13,13,13,13,  14,14,14,14,14,14,  15,15,15,15,15,15,  16,16,16,16,16,16, &
    !
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
     17,17,17,17,17,17,  18,18,18,18,18,18,  19,19,19,19,19,19,  20,20,20,20,20,20, &
    !
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24, &
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24, &
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24, &
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24, &
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24, &
     21,21,21,21,21,21,  22,22,22,22,22,22,  23,23,23,23,23,23,  24,24,24,24,24,24  &
    !
     ],pInt),[lattice_hex_Nslip,lattice_hex_Ntwin],order=[2,1])                                     !< Slip--twin interaction types for hex (isotropic, 24 in total) 

 integer(pInt), dimension(lattice_hex_Ntwin,lattice_hex_Nslip), parameter, public :: &
   lattice_hex_interactionTwinSlip = reshape(int( [&
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, & ! --> slip
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, & ! |
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, & ! |
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, & ! v
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, & ! twin
      1, 1, 1,   5, 5, 5,   9, 9, 9,  13,13,13,13,13,13,  17,17,17,17,17,17,17,17,17,17,17,17,  21,21,21,21,21,21, &
    !
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
      2, 2, 2,   6, 6, 6,  10,10,10,  14,14,14,14,14,14,  18,18,18,18,18,18,18,18,18,18,18,18,  22,22,22,22,22,22, &
    !
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
      3, 3, 3,   7, 7, 7,  11,11,11,  15,15,15,15,15,15,  19,19,19,19,19,19,19,19,19,19,19,19,  23,23,23,23,23,23, &
    !
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24, &
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24, &
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24, &
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24, &
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24, &
      4, 4, 4,   8, 8, 8,  12,12,12,  16,16,16,16,16,16,  20,20,20,20,20,20,20,20,20,20,20,20,  24,24,24,24,24,24  &
     ],pInt),[lattice_hex_Ntwin,lattice_hex_Nslip],order=[2,1])                                     !< Twin--twin interaction types for hex (isotropic, 20 in total)

 integer(pInt), dimension(lattice_hex_Ntwin,lattice_hex_Ntwin), parameter, public :: &
   lattice_hex_interactionTwinTwin = reshape(int( [&
      1, 2, 2, 2, 2, 2,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &  ! ---> twin
      2, 1, 2, 2, 2, 2,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &  ! |
      2, 2, 1, 2, 2, 2,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &  ! |
      2, 2, 2, 1, 2, 2,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &  ! v twin
      2, 2, 2, 2, 1, 2,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &
      2, 2, 2, 2, 2, 1,   3, 3, 3, 3, 3, 3,   7, 7, 7, 7, 7, 7,  13,13,13,13,13,13, &
    !
      6, 6, 6, 6, 6, 6,   4, 5, 5, 5, 5, 5,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
      6, 6, 6, 6, 6, 6,   5, 4, 5, 5, 5, 5,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
      6, 6, 6, 6, 6, 6,   5, 5, 4, 5, 5, 5,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
      6, 6, 6, 6, 6, 6,   5, 5, 5, 4, 5, 5,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
      6, 6, 6, 6, 6, 6,   5, 5, 5, 5, 4, 5,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
      6, 6, 6, 6, 6, 6,   5, 5, 5, 5, 5, 4,   8, 8, 8, 8, 8, 8,  14,14,14,14,14,14, &
    !
     12,12,12,12,12,12,  11,11,11,11,11,11,   9,10,10,10,10,10,  15,15,15,15,15,15, &
     12,12,12,12,12,12,  11,11,11,11,11,11,  10, 9,10,10,10,10,  15,15,15,15,15,15, &
     12,12,12,12,12,12,  11,11,11,11,11,11,  10,10, 9,10,10,10,  15,15,15,15,15,15, &
     12,12,12,12,12,12,  11,11,11,11,11,11,  10,10,10, 9,10,10,  15,15,15,15,15,15, &
     12,12,12,12,12,12,  11,11,11,11,11,11,  10,10,10,10, 9,10,  15,15,15,15,15,15, &
     12,12,12,12,12,12,  11,11,11,11,11,11,  10,10,10,10,10, 9,  15,15,15,15,15,15, &
    !
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  16,17,17,17,17,17, &
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  17,16,17,17,17,17, &
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  17,17,16,17,17,17, &
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  17,17,17,16,17,17, &
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  17,17,17,17,16,17, &
     20,20,20,20,20,20,  19,19,19,19,19,19,  18,18,18,18,18,18,  17,17,17,17,17,16  &
     ],pInt),[lattice_hex_Ntwin,lattice_hex_Ntwin],order=[2,1])                                     !< Twin--slip interaction types for hex (isotropic, 16 in total)
 real(pReal),                              dimension(:,:,:),   allocatable, public, protected :: &
   lattice_C66
 real(pReal),                              dimension(:,:,:,:,:),   allocatable, public, protected :: &
   lattice_C3333
 real(pReal),                              dimension(:),   allocatable, public, protected :: &
   lattice_mu, &
   lattice_nu
 enum, bind(c)
   enumerator :: LATTICE_undefined_ID, &
                 LATTICE_iso_ID, &
                 LATTICE_fcc_ID, &
                 LATTICE_bcc_ID, &
                 LATTICE_hex_ID, &
                 LATTICE_ort_ID
 end enum
 integer(kind(LATTICE_undefined_ID)),        dimension(:),       allocatable, public, protected :: &
   lattice_structure


integer(pInt), dimension(2), parameter, private :: &
   lattice_NsymOperations = [24_pInt,12_pInt]       

real(pReal), dimension(4,36), parameter, private :: &
  lattice_symOperations = reshape([&
     1.0_pReal,                 0.0_pReal,                 0.0_pReal,                 0.0_pReal, &                      ! cubic symmetry operations
     0.0_pReal,                 0.0_pReal,                 0.7071067811865476_pReal,  0.7071067811865476_pReal, &       !     2-fold symmetry
     0.0_pReal,                 0.7071067811865476_pReal,  0.0_pReal,                 0.7071067811865476_pReal, &
     0.0_pReal,                 0.7071067811865476_pReal,  0.7071067811865476_pReal,  0.0_pReal, &
     0.0_pReal,                 0.0_pReal,                 0.7071067811865476_pReal, -0.7071067811865476_pReal, &
     0.0_pReal,                -0.7071067811865476_pReal,  0.0_pReal,                 0.7071067811865476_pReal, &
     0.0_pReal,                 0.7071067811865476_pReal, -0.7071067811865476_pReal,  0.0_pReal, &
     0.5_pReal,                 0.5_pReal,                 0.5_pReal,                 0.5_pReal, &                      !     3-fold symmetry
    -0.5_pReal,                 0.5_pReal,                 0.5_pReal,                 0.5_pReal, &
     0.5_pReal,                -0.5_pReal,                 0.5_pReal,                 0.5_pReal, &
    -0.5_pReal,                -0.5_pReal,                 0.5_pReal,                 0.5_pReal, &
     0.5_pReal,                 0.5_pReal,                -0.5_pReal,                 0.5_pReal, &
    -0.5_pReal,                 0.5_pReal,                -0.5_pReal,                 0.5_pReal, &
     0.5_pReal,                 0.5_pReal,                 0.5_pReal,                -0.5_pReal, &
    -0.5_pReal,                 0.5_pReal,                 0.5_pReal,                -0.5_pReal, &
     0.7071067811865476_pReal,  0.7071067811865476_pReal,  0.0_pReal,                 0.0_pReal, &                      !     4-fold symmetry
     0.0_pReal,                 1.0_pReal,                 0.0_pReal,                 0.0_pReal, &
    -0.7071067811865476_pReal,  0.7071067811865476_pReal,  0.0_pReal,                 0.0_pReal, &
     0.7071067811865476_pReal,  0.0_pReal,                 0.7071067811865476_pReal,  0.0_pReal, &
     0.0_pReal,                 0.0_pReal,                 1.0_pReal,                 0.0_pReal, &
    -0.7071067811865476_pReal,  0.0_pReal,                 0.7071067811865476_pReal,  0.0_pReal, &
     0.7071067811865476_pReal,  0.0_pReal,                 0.0_pReal,                 0.7071067811865476_pReal, &
     0.0_pReal,                 0.0_pReal,                 0.0_pReal,                 1.0_pReal, &
    -0.7071067811865476_pReal,  0.0_pReal,                 0.0_pReal,                 0.7071067811865476_pReal, &
     1.0_pReal,                 0.0_pReal,                 0.0_pReal,                 0.0_pReal, &                      ! hexagonal symmetry operations
     0.0_pReal,                 1.0_pReal,                 0.0_pReal,                 0.0_pReal, &                      !     2-fold symmetry
     0.0_pReal,                 0.0_pReal,                 1.0_pReal,                 0.0_pReal, &
     0.0_pReal,                 0.5_pReal,                 0.866025403784439_pReal,   0.0_pReal, &
     0.0_pReal,                -0.5_pReal,                 0.866025403784439_pReal,   0.0_pReal, &
     0.0_pReal,                 0.866025403784439_pReal,   0.5_pReal,                 0.0_pReal, &
     0.0_pReal,                -0.866025403784439_pReal,   0.5_pReal,                 0.0_pReal, &
     0.866025403784439_pReal,   0.0_pReal,                 0.0_pReal,                 0.5_pReal, &                      !     6-fold symmetry
    -0.866025403784439_pReal,   0.0_pReal,                 0.0_pReal,                 0.5_pReal, &
     0.5_pReal,                 0.0_pReal,                 0.0_pReal,                 0.866025403784439_pReal, &
    -0.5_pReal,                 0.0_pReal,                 0.0_pReal,                 0.866025403784439_pReal, &
     0.0_pReal,                 0.0_pReal,                 0.0_pReal,                 1.0_pReal &
     ],[4,36])  !< Symmetry operations as quaternions 24 for cubic, 12 for hexagonal = 36

 ! use this later on to substitute the matrix above
 !   if self.lattice == 'cubic':
 !     symQuats =  [
 !                   [ 1.0,0.0,0.0,0.0 ],
 !                   [ 0.0,1.0,0.0,0.0 ],
 !                   [ 0.0,0.0,1.0,0.0 ],
 !                   [ 0.0,0.0,0.0,1.0 ],
 !                   [ 0.0, 0.0, 0.5*math.sqrt(2), 0.5*math.sqrt(2) ],
 !                   [ 0.0, 0.0, 0.5*math.sqrt(2),-0.5*math.sqrt(2) ],
 !                   [ 0.0, 0.5*math.sqrt(2), 0.0, 0.5*math.sqrt(2) ],
 !                   [ 0.0, 0.5*math.sqrt(2), 0.0,-0.5*math.sqrt(2) ],
 !                   [ 0.0, 0.5*math.sqrt(2),-0.5*math.sqrt(2), 0.0 ],
 !                   [ 0.0,-0.5*math.sqrt(2),-0.5*math.sqrt(2), 0.0 ],
 !                   [ 0.5, 0.5, 0.5, 0.5 ],
 !                   [-0.5, 0.5, 0.5, 0.5 ],
 !                   [-0.5, 0.5, 0.5,-0.5 ],
 !                   [-0.5, 0.5,-0.5, 0.5 ],
 !                   [-0.5,-0.5, 0.5, 0.5 ],
 !                   [-0.5,-0.5, 0.5,-0.5 ],
 !                   [-0.5,-0.5,-0.5, 0.5 ],
 !                   [-0.5, 0.5,-0.5,-0.5 ],
 !                   [-0.5*math.sqrt(2), 0.0, 0.0, 0.5*math.sqrt(2) ],
 !                   [ 0.5*math.sqrt(2), 0.0, 0.0, 0.5*math.sqrt(2) ],
 !                   [-0.5*math.sqrt(2), 0.0, 0.5*math.sqrt(2), 0.0 ],
 !                   [-0.5*math.sqrt(2), 0.0,-0.5*math.sqrt(2), 0.0 ],
 !                   [-0.5*math.sqrt(2), 0.5*math.sqrt(2), 0.0, 0.0 ],
 !                   [-0.5*math.sqrt(2),-0.5*math.sqrt(2), 0.0, 0.0 ],
 !                 ]
 !   elif self.lattice == 'hexagonal':
 !     symQuats =  [
 !                   [ 1.0,0.0,0.0,0.0 ],
 !                   [ 0.0,1.0,0.0,0.0 ],
 !                   [ 0.0,0.0,1.0,0.0 ],
 !                   [ 0.0,0.0,0.0,1.0 ],
 !                   [-0.5*math.sqrt(3), 0.0, 0.0, 0.5 ],
 !                   [-0.5*math.sqrt(3), 0.0, 0.0,-0.5 ],
 !                   [ 0.0, 0.5*math.sqrt(3), 0.5, 0.0 ],
 !                   [ 0.0,-0.5*math.sqrt(3), 0.5, 0.0 ],
 !                   [ 0.0, 0.5,-0.5*math.sqrt(3), 0.0 ],
 !                   [ 0.0,-0.5,-0.5*math.sqrt(3), 0.0 ],
 !                   [ 0.5, 0.0, 0.0, 0.5*math.sqrt(3) ],
 !                   [-0.5, 0.0, 0.0, 0.5*math.sqrt(3) ],
 !                 ]
 !   elif self.lattice == 'tetragonal':
 !     symQuats =  [
 !                   [ 1.0,0.0,0.0,0.0 ],
 !                   [ 0.0,1.0,0.0,0.0 ],
 !                   [ 0.0,0.0,1.0,0.0 ],
 !                   [ 0.0,0.0,0.0,1.0 ],
 !                   [ 0.0, 0.5*math.sqrt(2), 0.5*math.sqrt(2), 0.0 ],
 !                   [ 0.0,-0.5*math.sqrt(2), 0.5*math.sqrt(2), 0.0 ],
 !                   [ 0.5*math.sqrt(2), 0.0, 0.0, 0.5*math.sqrt(2) ],
 !                   [-0.5*math.sqrt(2), 0.0, 0.0, 0.5*math.sqrt(2) ],
 !                 ]
 !   elif self.lattice == 'orthorhombic':
 !     symQuats =  [
 !                   [ 1.0,0.0,0.0,0.0 ],
 !                   [ 0.0,1.0,0.0,0.0 ],
 !                   [ 0.0,0.0,1.0,0.0 ],
 !                   [ 0.0,0.0,0.0,1.0 ],
 !                 ]
 !   else:
 !     symQuats =  [
 !                   [ 1.0,0.0,0.0,0.0 ],
 !                 ]

 public :: &
  lattice_init, &
  lattice_qDisorientation, &
  LATTICE_fcc_ID, &
  LATTICE_bcc_ID, &
  LATTICE_hex_ID

contains

!--------------------------------------------------------------------------------------------------
!> @brief Module initialization
!--------------------------------------------------------------------------------------------------
subroutine lattice_init
 use, intrinsic :: iso_fortran_env                                                                  ! to get compiler_version and compiler_options (at least for gfortran 4.6 at the moment)
 use prec, only: &
   tol_math_check
 use IO, only: &
   IO_open_file,&
   IO_open_jobFile_stat, &
   IO_countSections, &
   IO_countTagInPart, &
   IO_error, &
   IO_timeStamp, &
   IO_stringPos, &
   IO_EOF, &
   IO_read, &
   IO_lc, &
   IO_getTag, &
   IO_isBlank, &
   IO_stringPos, &
   IO_stringValue, &
   IO_floatValue, &
   IO_EOF
 use material, only: &
   material_configfile, &
   material_localFileExt, &
   material_partPhase
 use debug, only: &
   debug_level, &
   debug_lattice, &
   debug_levelBasic
   
 implicit none
 integer(pInt), parameter :: FILEUNIT = 200_pInt
 integer(pInt) :: Nphases
 character(len=65536) :: &
   tag  = '', &
   line = ''
 integer(pInt), parameter :: MAXNCHUNKS = 2_pInt
 integer(pInt), dimension(1+2*MAXNCHUNKS) :: positions
 integer(pInt) :: section = 0_pInt,i
 real(pReal),                          dimension(:), allocatable :: CoverA  !< c/a ratio for hex type lattice

 write(6,'(/,a)') ' <<<+-  lattice init  -+>>>'
 write(6,'(a)')   ' $Id$'
 write(6,'(a15,a)')   ' Current time: ',IO_timeStamp()
#include "compilation_info.f90"

!--------------------------------------------------------------------------------------------------
! consistency checks
 if (LATTICE_maxNslip /= maxval([lattice_fcc_Nslip,lattice_bcc_Nslip,lattice_hex_Nslip])) &
   call IO_error(0_pInt,ext_msg = 'LATTICE_maxNslip')
 if (LATTICE_maxNtwin /= maxval([lattice_fcc_Ntwin,lattice_bcc_Ntwin,lattice_hex_Ntwin])) &
   call IO_error(0_pInt,ext_msg = 'LATTICE_maxNtwin')
 if (LATTICE_maxNnonSchmid /= maxval([lattice_fcc_NnonSchmid,lattice_bcc_NnonSchmid,&
   lattice_hex_NnonSchmid])) call IO_error(0_pInt,ext_msg = 'LATTICE_maxNnonSchmid')
 if (LATTICE_maxNinteraction /= max(&
   maxval(lattice_fcc_interactionSlipSlip), &
   maxval(lattice_bcc_interactionSlipSlip), &
   maxval(lattice_hex_interactionSlipSlip), &
   !
   maxval(lattice_fcc_interactionSlipTwin), &
   maxval(lattice_bcc_interactionSlipTwin), &
   maxval(lattice_hex_interactionSlipTwin), &
   !
   maxval(lattice_fcc_interactionTwinSlip), &
   maxval(lattice_bcc_interactionTwinSlip), &
   maxval(lattice_hex_interactionTwinSlip), &
   !
   maxval(lattice_fcc_interactionTwinTwin), &
   maxval(lattice_bcc_interactionTwinTwin), &
   maxval(lattice_hex_interactionTwinTwin))) &
   call IO_error(0_pInt,ext_msg = 'LATTICE_maxNinteraction')

!--------------------------------------------------------------------------------------------------
! read from material configuration file
 if (.not. IO_open_jobFile_stat(FILEUNIT,material_localFileExt)) &                                  ! no local material configuration present...
   call IO_open_file(FILEUNIT,material_configFile)                                                  ! ... open material.config file
 Nphases = IO_countSections(FILEUNIT,material_partPhase)

 if(Nphases<1_pInt) &
   call IO_error(160_pInt,Nphases, ext_msg='No phases found')

 if (iand(debug_level(debug_lattice),debug_levelBasic) /= 0_pInt) then
   write(6,'(a16,1x,i5)')   ' # phases:',Nphases
 endif
 
 allocate(lattice_structure(Nphases),source = LATTICE_undefined_ID)
 allocate(lattice_C66(6,6,Nphases),  source=0.0_pReal)
 allocate(lattice_C3333(3,3,3,3,Nphases),  source=0.0_pReal)

 allocate(lattice_mu(Nphases),       source=0.0_pReal)
 allocate(lattice_nu(Nphases),       source=0.0_pReal)

 allocate(lattice_NnonSchmid(Nphases), source=0_pInt)
 allocate(lattice_Sslip(3,3,1+2*lattice_maxNnonSchmid,lattice_maxNslip,Nphases),source=0.0_pReal)
 allocate(lattice_Sslip_v(6,1+2*lattice_maxNnonSchmid,lattice_maxNslip,Nphases),source=0.0_pReal)
 allocate(lattice_sd(3,lattice_maxNslip,Nphases),source=0.0_pReal)
 allocate(lattice_st(3,lattice_maxNslip,Nphases),source=0.0_pReal)
 allocate(lattice_sn(3,lattice_maxNslip,Nphases),source=0.0_pReal)

 allocate(lattice_Qtwin(3,3,lattice_maxNtwin,Nphases),source=0.0_pReal)
 allocate(lattice_Stwin(3,3,lattice_maxNtwin,Nphases),source=0.0_pReal)
 allocate(lattice_Stwin_v(6,lattice_maxNtwin,Nphases),source=0.0_pReal)
 allocate(lattice_td(3,lattice_maxNtwin,Nphases),source=0.0_pReal)
 allocate(lattice_tt(3,lattice_maxNtwin,Nphases),source=0.0_pReal)
 allocate(lattice_tn(3,lattice_maxNtwin,Nphases),source=0.0_pReal)

 allocate(lattice_shearTwin(lattice_maxNtwin,Nphases),source=0.0_pReal)

 allocate(lattice_NslipSystem(lattice_maxNslipFamily,Nphases),source=0_pInt)
 allocate(lattice_NtwinSystem(lattice_maxNtwinFamily,Nphases),source=0_pInt)

 allocate(lattice_interactionSlipSlip(lattice_maxNslip,lattice_maxNslip,Nphases),source=0_pInt)! other:me
 allocate(lattice_interactionSlipTwin(lattice_maxNslip,lattice_maxNtwin,Nphases),source=0_pInt)! other:me
 allocate(lattice_interactionTwinSlip(lattice_maxNtwin,lattice_maxNslip,Nphases),source=0_pInt)! other:me
 allocate(lattice_interactionTwinTwin(lattice_maxNtwin,lattice_maxNtwin,Nphases),source=0_pInt)! other:me

 allocate(CoverA(Nphases),source=0.0_pReal)
 rewind(fileUnit)
 line        = ''                                                                                   ! to have it initialized
 section     = 0_pInt                                                                               !  - " -
 do while (trim(line) /= IO_EOF .and. IO_lc(IO_getTag(line,'<','>')) /= material_partPhase)         ! wind forward to <Phase>
   line = IO_read(fileUnit)
 enddo

 do while (trim(line) /= IO_EOF)                                                                    ! read through sections of material part
   line = IO_read(fileUnit)
   if (IO_isBlank(line)) cycle                                                                      ! skip empty lines
   if (IO_getTag(line,'<','>') /= '') then                                                          ! stop at next part
     line = IO_read(fileUnit, .true.)                                                               ! reset IO_read
     exit                                                                                           
   endif
   if (IO_getTag(line,'[',']') /= '') then                                                          ! next section
     section = section + 1_pInt
   endif
   if (section > 0_pInt) then
     positions = IO_stringPos(line,MAXNCHUNKS)
     tag = IO_lc(IO_stringValue(line,positions,1_pInt))                                             ! extract key
     select case(tag)
       case ('lattice_structure')
         select case(trim(IO_lc(IO_stringValue(line,positions,2_pInt))))
           case('iso','isotropic')
             lattice_structure(section) = LATTICE_iso_ID
           case('fcc')
             lattice_structure(section) = LATTICE_fcc_ID
           case('bcc')
             lattice_structure(section) = LATTICE_bcc_ID
           case('hex','hexagonal')
             lattice_structure(section) = LATTICE_hex_ID
           case('ort','orthorombic')
             lattice_structure(section) = LATTICE_ort_ID
           case default
             !there will be an error here
         end select
     case ('c11')
         lattice_C66(1,1,section) = IO_floatValue(line,positions,2_pInt)
     case ('c12')
         lattice_C66(1,2,section) = IO_floatValue(line,positions,2_pInt)
     case ('c13')
         lattice_C66(1,3,section) = IO_floatValue(line,positions,2_pInt)
     case ('c22')
         lattice_C66(2,2,section) = IO_floatValue(line,positions,2_pInt)
     case ('c23')
         lattice_C66(2,3,section) = IO_floatValue(line,positions,2_pInt)
     case ('c33')
         lattice_C66(3,3,section) = IO_floatValue(line,positions,2_pInt)
     case ('c44')
         lattice_C66(4,4,section) = IO_floatValue(line,positions,2_pInt)
     case ('c55')
         lattice_C66(5,5,section) = IO_floatValue(line,positions,2_pInt)
     case ('c66')
         lattice_C66(6,6,section) = IO_floatValue(line,positions,2_pInt)
       case ('covera_ratio','c/a_ratio','c/a')
       CoverA(section) = IO_floatValue(line,positions,2_pInt)
         if (CoverA(section) < 1.0_pReal .or. CoverA(section) > 2.0_pReal) call IO_error(206_pInt)  ! checking physical significance of c/a
     end select
   endif
 enddo

 do i = 1_pInt,Nphases
   call lattice_initializeStructure(i, CoverA(i))
 enddo

 deallocate(CoverA)

end subroutine lattice_init


!--------------------------------------------------------------------------------------------------
!> @brief   Calculation of Schmid matrices, etc.
!--------------------------------------------------------------------------------------------------
subroutine lattice_initializeStructure(myPhase,CoverA)
 use prec, only: &
  tol_math_check
 use math, only: &
   math_vectorproduct, &
   math_tensorproduct, &
   math_norm3, &
   math_mul33x3, &
   math_trace33, &
   math_symmetric33, &
   math_Mandel33to6, &
   math_Mandel3333to66, &
   math_Voigt66to3333, &
   math_axisAngleToR, &
   INRAD
 use IO, only: &
   IO_error
 
 implicit none
 integer(pInt), intent(in) :: myPhase
 real(pReal), intent(in) :: CoverA

 real(pReal), dimension(3) :: &
   sdU, snU, &
   np,  nn
 real(pReal), dimension(3,lattice_maxNslip) :: &
   sd,  sn
 real(pReal), dimension(3,3,2,lattice_maxNnonSchmid,lattice_maxNslip) :: &
   sns
 real(pReal), dimension(3,lattice_maxNtwin) :: &
   td, tn
 real(pReal), dimension(lattice_maxNtwin) :: &
   ts
 integer(pInt) :: &
  i,j, &
  myNslip, myNtwin

 lattice_C66(1:6,1:6,myPhase) = lattice_symmetrizeC66(lattice_structure(myPhase),lattice_C66(1:6,1:6,myPhase))
 lattice_mu(myPhase) = 0.2_pReal * (lattice_C66(1,1,myPhase) - lattice_C66(1,2,myPhase) + 3.0_pReal*lattice_C66(4,4,myPhase)) ! (C11iso-C12iso)/2 with C11iso=(3*C11+2*C12+4*C44)/5 and C12iso=(C11+4*C12-2*C44)/5
 lattice_nu(myPhase) = (lattice_C66(1,1,myPhase) + 4.0_pReal*lattice_C66(1,2,myPhase) - 2.0_pReal*lattice_C66(4,4,myPhase)) &
      / (4.0_pReal*lattice_C66(1,1,myPhase) + 6.0_pReal*lattice_C66(1,2,myPhase) + 2.0_pReal*lattice_C66(4,4,myPhase))  ! C12iso/(C11iso+C12iso) with C11iso=(3*C11+2*C12+4*C44)/5 and C12iso=(C11+4*C12-2*C44)/5
 lattice_C3333(1:3,1:3,1:3,1:3,myPhase) = math_Voigt66to3333(lattice_C66(1:6,1:6,myPhase))          ! Literature data is Voigt
 lattice_C66(1:6,1:6,myPhase) = math_Mandel3333to66(lattice_C3333(1:3,1:3,1:3,1:3,myPhase))         ! DAMASK uses Mandel

 
 select case(lattice_structure(myPhase))
!--------------------------------------------------------------------------------------------------
! fcc
   case (LATTICE_fcc_ID)
     myNslip = lattice_fcc_Nslip
     myNtwin = lattice_fcc_Ntwin
     do i = 1_pInt,lattice_fcc_Nslip                                                                ! assign slip system vectors
         sd(1:3,i) = lattice_fcc_systemSlip(1:3,i)
         sn(1:3,i) = lattice_fcc_systemSlip(4:6,i)
         enddo  
     do i = 1_pInt,lattice_fcc_Ntwin                                                                ! assign twin system vectors and shears
         td(1:3,i) = lattice_fcc_systemTwin(1:3,i)
         tn(1:3,i) = lattice_fcc_systemTwin(4:6,i)
         ts(i)     = lattice_fcc_shearTwin(i)
     enddo
     lattice_NslipSystem(1:lattice_maxNslipFamily,myPhase) = lattice_fcc_NslipSystem
     lattice_NtwinSystem(1:lattice_maxNtwinFamily,myPhase) = lattice_fcc_NtwinSystem
     lattice_NnonSchmid(myPhase)                           = lattice_fcc_NnonSchmid
     lattice_interactionSlipSlip(1:myNslip,1:myNslip,myPhase) = &
                                                             lattice_fcc_interactionSlipSlip
     lattice_interactionSlipTwin(1:myNslip,1:myNtwin,myPhase) = &
                                                             lattice_fcc_interactionSlipTwin
     lattice_interactionTwinSlip(1:myNtwin,1:myNslip,myPhase) = &
                                                             lattice_fcc_interactionTwinSlip
     lattice_interactionTwinTwin(1:myNtwin,1:myNtwin,myPhase) = &
                                                             lattice_fcc_interactionTwinTwin
     
!--------------------------------------------------------------------------------------------------
! bcc
   case (LATTICE_bcc_ID)
     myNslip = lattice_bcc_Nslip
     myNtwin = lattice_bcc_Ntwin
     do i = 1_pInt,lattice_bcc_Nslip                                                                ! assign slip system vectors
         sd(1:3,i) = lattice_bcc_systemSlip(1:3,i)
         sn(1:3,i) = lattice_bcc_systemSlip(4:6,i)
         sdU = sd(1:3,i) / math_norm3(sd(1:3,i))
         snU = sn(1:3,i) / math_norm3(sn(1:3,i))
         ! "np" and "nn" according to Gröger_etal2008, Acta Materialia 56 (2008) 5412–5425, table 1 (corresponds to their "n1" for positive and negative slip direction respectively)
         np = math_mul33x3(math_axisAngleToR(sdU,60.0_pReal*INRAD), snU)
         nn = math_mul33x3(math_axisAngleToR(-sdU,60.0_pReal*INRAD), snU)
         ! Schmid matrices with non-Schmid contributions according to Koester_etal2012, Acta Materialia 60 (2012) 3894–3901, eq. (17) ("n1" is replaced by either "np" or "nn" according to either positive or negative slip direction)
         sns(1:3,1:3,1,1,i) = math_tensorproduct(sdU, np)
         sns(1:3,1:3,2,1,i) = math_tensorproduct(-sdU, nn)
         sns(1:3,1:3,1,2,i) = math_tensorproduct(math_vectorproduct(snU, sdU), snU)
         sns(1:3,1:3,2,2,i) = math_tensorproduct(math_vectorproduct(snU, -sdU), snU)
         sns(1:3,1:3,1,3,i) = math_tensorproduct(math_vectorproduct(np, sdU), np)
         sns(1:3,1:3,2,3,i) = math_tensorproduct(math_vectorproduct(nn, -sdU), nn)
         sns(1:3,1:3,1,4,i) = math_tensorproduct(snU, snU)
         sns(1:3,1:3,2,4,i) = math_tensorproduct(snU, snU)
         sns(1:3,1:3,1,5,i) = math_tensorproduct(math_vectorproduct(snU, sdU), math_vectorproduct(snU, sdU))
         sns(1:3,1:3,2,5,i) = math_tensorproduct(math_vectorproduct(snU, -sdU), math_vectorproduct(snU, -sdU))
         sns(1:3,1:3,1,6,i) = math_tensorproduct(sdU, sdU)
         sns(1:3,1:3,2,6,i) = math_tensorproduct(-sdU, -sdU)
       enddo
     do i = 1_pInt,lattice_bcc_Ntwin                                                                ! assign twin system vectors and shears
         td(1:3,i) = lattice_bcc_systemTwin(1:3,i)
         tn(1:3,i) = lattice_bcc_systemTwin(4:6,i)
         ts(i)     = lattice_bcc_shearTwin(i)
       enddo
     lattice_NslipSystem(1:lattice_maxNslipFamily,myPhase) = lattice_bcc_NslipSystem
     lattice_NtwinSystem(1:lattice_maxNtwinFamily,myPhase) = lattice_bcc_NtwinSystem
     lattice_NnonSchmid(myPhase)                           = lattice_bcc_NnonSchmid
     lattice_interactionSlipSlip(1:lattice_bcc_Nslip,1:lattice_bcc_Nslip,myPhase) = &
                                                             lattice_bcc_interactionSlipSlip
     lattice_interactionSlipTwin(1:lattice_bcc_Nslip,1:lattice_bcc_Ntwin,myPhase) = &
                                                             lattice_bcc_interactionSlipTwin
     lattice_interactionTwinSlip(1:lattice_bcc_Ntwin,1:lattice_bcc_Nslip,myPhase) = &
                                                             lattice_bcc_interactionTwinSlip
     lattice_interactionTwinTwin(1:lattice_bcc_Ntwin,1:lattice_bcc_Ntwin,myPhase) = &
                                                             lattice_bcc_interactionTwinTwin
     
!--------------------------------------------------------------------------------------------------
! hex (including conversion from miller-bravais (a1=a2=a3=c) to miller (a, b, c) indices)
   case (LATTICE_hex_ID)
     myNslip = lattice_hex_Nslip
     myNtwin = lattice_hex_Ntwin
     do i = 1_pInt,lattice_hex_Nslip                                                                ! assign slip system vectors                                                         
       sd(1,i) =  lattice_hex_systemSlip(1,i)*1.5_pReal ! direction [uvtw]->[3u/2 (u+2v)*sqrt(3)/2 w*(c/a)]
       sd(2,i) = (lattice_hex_systemSlip(1,i)+2.0_pReal*lattice_hex_systemSlip(2,i))*(0.5_pReal*sqrt(3.0_pReal))
       sd(3,i) =  lattice_hex_systemSlip(4,i)*CoverA
       sn(1,i) =  lattice_hex_systemSlip(5,i)           ! plane (hkil)->(h (h+2k)/sqrt(3) l/(c/a))
       sn(2,i) = (lattice_hex_systemSlip(5,i)+2.0_pReal*lattice_hex_systemSlip(6,i))/sqrt(3.0_pReal)
       sn(3,i) =  lattice_hex_systemSlip(8,i)/CoverA
     enddo  
     do i = 1_pInt,lattice_hex_Ntwin                                                                ! assign twin system vectors and shears
       td(1,i) =  lattice_hex_systemTwin(1,i)*1.5_pReal
       td(2,i) = (lattice_hex_systemTwin(1,i)+2.0_pReal*lattice_hex_systemTwin(2,i))*(0.5_pReal*sqrt(3.0_pReal))
       td(3,i) =  lattice_hex_systemTwin(4,i)*CoverA
       tn(1,i) =  lattice_hex_systemTwin(5,i)
       tn(2,i) = (lattice_hex_systemTwin(5,i)+2.0_pReal*lattice_hex_systemTwin(6,i))/sqrt(3.0_pReal)
       tn(3,i) =  lattice_hex_systemTwin(8,i)/CoverA
       select case(lattice_hex_shearTwin(i))                                          ! from Christian & Mahajan 1995 p.29
         case (1_pInt)                                                                ! <-10.1>{10.2}
                  ts(i) = (3.0_pReal-CoverA*CoverA)/sqrt(3.0_pReal)/CoverA
         case (2_pInt)                                                                ! <11.6>{-1-1.1}
                  ts(i) = 1.0_pReal/CoverA
         case (3_pInt)                                                                ! <10.-2>{10.1}
                  ts(i) = (4.0_pReal*CoverA*CoverA-9.0_pReal)/4.0_pReal/sqrt(3.0_pReal)/CoverA
         case (4_pInt)                                                                ! <11.-3>{11.2}
                  ts(i) = 2.0_pReal*(CoverA*CoverA-2.0_pReal)/3.0_pReal/CoverA
       end select
     enddo
     lattice_NslipSystem(1:lattice_maxNslipFamily,myPhase) = lattice_hex_NslipSystem
     lattice_NtwinSystem(1:lattice_maxNtwinFamily,myPhase) = lattice_hex_NtwinSystem
     lattice_NnonSchmid(myPhase)                           = lattice_hex_NnonSchmid
     lattice_interactionSlipSlip(1:lattice_hex_Nslip,1:lattice_hex_Nslip,myPhase) = &
                                                             lattice_hex_interactionSlipSlip
     lattice_interactionSlipTwin(1:lattice_hex_Nslip,1:lattice_hex_Ntwin,myPhase) = &
                                                             lattice_hex_interactionSlipTwin
     lattice_interactionTwinSlip(1:lattice_hex_Ntwin,1:lattice_hex_Nslip,myPhase) = &
                                                             lattice_hex_interactionTwinSlip
     lattice_interactionTwinTwin(1:lattice_hex_Ntwin,1:lattice_hex_Ntwin,myPhase) = &
                                                             lattice_hex_interactionTwinTwin

!--------------------------------------------------------------------------------------------------
! orthorombic and isotropic (no crystal plasticity)
   case (LATTICE_ort_ID, LATTICE_iso_ID)
     myNslip       = 0_pInt
     myNtwin       = 0_pInt

!--------------------------------------------------------------------------------------------------
! something went wrong
   case default
     print*, 'error'
 end select


 do i = 1_pInt,myNslip                                                                              ! store slip system vectors and Schmid matrix for my structure
   lattice_sd(1:3,i,myPhase) = sd(1:3,i)/math_norm3(sd(1:3,i))                                      ! make unit vector
   lattice_sn(1:3,i,myPhase) = sn(1:3,i)/math_norm3(sn(1:3,i))                                      ! make unit vector
   lattice_st(1:3,i,myPhase) = math_vectorproduct(lattice_sd(1:3,i,myPhase), &
                                                      lattice_sn(1:3,i,myPhase))
   lattice_Sslip(1:3,1:3,1,i,myPhase) = math_tensorproduct(lattice_sd(1:3,i,myPhase), &
                                                                 lattice_sn(1:3,i,myPhase))
   do j = 1_pInt,lattice_NnonSchmid(myPhase)
     lattice_Sslip(1:3,1:3,2*j  ,i,myPhase) = sns(1:3,1:3,1,j,i)
     lattice_Sslip(1:3,1:3,2*j+1,i,myPhase) = sns(1:3,1:3,2,j,i)
     enddo 
   do j = 1_pInt,1_pInt+2_pInt*lattice_NnonSchmid(myPhase)
     lattice_Sslip_v(1:6,j,i,myPhase) = &
       math_Mandel33to6(math_symmetric33(lattice_Sslip(1:3,1:3,j,i,myPhase)))
     enddo
   if (abs(math_trace33(lattice_Sslip(1:3,1:3,1,i,myPhase))) > tol_math_check) &
     call IO_error(0_pInt,myPhase,i,0_pInt,ext_msg = 'dilatational slip Schmid matrix')
   enddo
   do i = 1_pInt,myNtwin                                                                            ! store twin system vectors and Schmid plus rotation matrix for my structure
   lattice_td(1:3,i,myPhase) = td(1:3,i)/math_norm3(td(1:3,i))                                      ! make unit vector
   lattice_tn(1:3,i,myPhase) = tn(1:3,i)/math_norm3(tn(1:3,i))                                      ! make unit vector
   lattice_tt(1:3,i,myPhase) = math_vectorproduct(lattice_td(1:3,i,myPhase), &
                                                      lattice_tn(1:3,i,myPhase))
   lattice_Stwin(1:3,1:3,i,myPhase) = math_tensorproduct(lattice_td(1:3,i,myPhase), &
                                                             lattice_tn(1:3,i,myPhase))
   lattice_Stwin_v(1:6,i,myPhase)   = math_Mandel33to6(math_symmetric33(lattice_Stwin(1:3,1:3,i,myPhase)))
   lattice_Qtwin(1:3,1:3,i,myPhase) = math_axisAngleToR(tn(1:3,i),180.0_pReal*INRAD)
   lattice_shearTwin(i,myPhase)     = ts(i)
   if (abs(math_trace33(lattice_Stwin(1:3,1:3,i,myPhase))) > tol_math_check) &
     call IO_error(301_pInt,myPhase,ext_msg = 'dilatational twin Schmid matrix')
 enddo
      
end subroutine lattice_initializeStructure


!--------------------------------------------------------------------------------------------------
!> @brief Symmetrizes stiffness matrix according to lattice type
!--------------------------------------------------------------------------------------------------
pure function lattice_symmetrizeC66(struct,C66)

 implicit none
 integer(kind(LATTICE_undefined_ID)), intent(in) :: struct
 real(pReal), dimension(6,6), intent(in) :: C66
 real(pReal), dimension(6,6) :: lattice_symmetrizeC66
 integer(pInt) :: j,k

 lattice_symmetrizeC66 = 0.0_pReal
 
 select case(struct)
   case (LATTICE_iso_ID)
     forall(k=1_pInt:3_pInt)
       forall(j=1_pInt:3_pInt) lattice_symmetrizeC66(k,j) = C66(1,2)
       lattice_symmetrizeC66(k,k) = C66(1,1)
       lattice_symmetrizeC66(k+3,k+3) = 0.5_pReal*(C66(1,1)-C66(1,2))
     end forall
   case (LATTICE_fcc_ID,LATTICE_bcc_ID)
     forall(k=1_pInt:3_pInt)
       forall(j=1_pInt:3_pInt) lattice_symmetrizeC66(k,j) =   C66(1,2)
       lattice_symmetrizeC66(k,k) =     C66(1,1)
       lattice_symmetrizeC66(k+3_pInt,k+3_pInt) = C66(4,4)
     end forall    
   case (LATTICE_hex_ID)
     lattice_symmetrizeC66(1,1) = C66(1,1)
     lattice_symmetrizeC66(2,2) = C66(1,1)
     lattice_symmetrizeC66(3,3) = C66(3,3)
     lattice_symmetrizeC66(1,2) = C66(1,2)
     lattice_symmetrizeC66(2,1) = C66(1,2)
     lattice_symmetrizeC66(1,3) = C66(1,3)
     lattice_symmetrizeC66(3,1) = C66(1,3)
     lattice_symmetrizeC66(2,3) = C66(1,3)
     lattice_symmetrizeC66(3,2) = C66(1,3)
     lattice_symmetrizeC66(4,4) = C66(4,4)
     lattice_symmetrizeC66(5,5) = C66(4,4)
     lattice_symmetrizeC66(6,6) = 0.5_pReal*(C66(1,1)-C66(1,2))
   case (LATTICE_ort_ID)
     lattice_symmetrizeC66(1,1) = C66(1,1)
     lattice_symmetrizeC66(2,2) = C66(2,2)
     lattice_symmetrizeC66(3,3) = C66(3,3)
     lattice_symmetrizeC66(1,2) = C66(1,2)
     lattice_symmetrizeC66(2,1) = C66(1,2)
     lattice_symmetrizeC66(1,3) = C66(1,3)
     lattice_symmetrizeC66(3,1) = C66(1,3)
     lattice_symmetrizeC66(2,3) = C66(2,3)
     lattice_symmetrizeC66(3,2) = C66(2,3)
     lattice_symmetrizeC66(4,4) = C66(4,4)
     lattice_symmetrizeC66(5,5) = C66(5,5)
     lattice_symmetrizeC66(6,6) = C66(6,6)
   case default
     lattice_symmetrizeC66 = C66
  end select
  
 end function lattice_symmetrizeC66


!--------------------------------------------------------------------------------------------------
!> @brief figures whether unit quat falls into stereographic standard triangle
!--------------------------------------------------------------------------------------------------
logical pure function lattice_qInSST(Q, struct)
 use math, only: &
   math_qToRodrig

 implicit none
 real(pReal), dimension(4), intent(in) ::      Q                           ! orientation
 integer(kind(LATTICE_undefined_ID)), intent(in) :: struct                 ! lattice structure
 real(pReal), dimension(3) ::                  Rodrig                      ! Rodrigues vector of Q

 Rodrig = math_qToRodrig(Q)
 if (any(Rodrig/=Rodrig)) then
   lattice_qInSST = .false.
 else
   select case (struct)
     case (LATTICE_bcc_ID,LATTICE_fcc_ID)
       lattice_qInSST = Rodrig(1) > Rodrig(2) .and. &
                        Rodrig(2) > Rodrig(3) .and. &
                        Rodrig(3) > 0.0_pReal
     case (LATTICE_hex_ID)
       lattice_qInSST = Rodrig(1) > sqrt(3.0_pReal)*Rodrig(2) .and. &
                        Rodrig(2) > 0.0_pReal .and. &
                        Rodrig(3) > 0.0_pReal
     case default
       lattice_qInSST = .true.
   end select
 endif

end function lattice_qInSST


!--------------------------------------------------------------------------------------------------
!> @brief calculates the disorientation for 2 unit quaternions
!--------------------------------------------------------------------------------------------------
pure function lattice_qDisorientation(Q1, Q2, struct)
 use prec, only: &
  tol_math_check
 use math, only: &
   math_qMul, &
   math_qConj

 implicit none
 real(pReal), dimension(4) ::                  lattice_qDisorientation
 real(pReal), dimension(4), intent(in) :: &
   Q1, &                                                                                          ! 1st orientation
                                               Q2                                                   ! 2nd orientation
 integer(kind(LATTICE_undefined_ID)), optional, intent(in) :: &                                   ! if given, symmetries between the two orientation will be considered
   struct

 real(pReal), dimension(4) ::                  dQ,dQsymA,mis
 integer(pInt)    ::                           i,j,k,s,symmetry
 integer(kind(LATTICE_undefined_ID)) :: myStruct

!--------------------------------------------------------------------------------------------------
! check if a structure with known symmetries is given
 if (present(struct)) then
   myStruct = struct
   select case (struct)
     case(LATTICE_fcc_ID,LATTICE_bcc_ID)
       symmetry = 1_pInt
     case(LATTICE_hex_ID)
       symmetry = 2_pInt
     case default
       symmetry = 0_pInt
   end select
 else
   symmetry = 0_pInt
   myStruct = LATTICE_undefined_ID
 endif


!--------------------------------------------------------------------------------------------------
! calculate misorientation, for cubic(1) and hexagonal(2) structure find symmetries
 dQ = math_qMul(math_qConj(Q1),Q2)
 lattice_qDisorientation = dQ

 select case(symmetry) 

    case (1_pInt,2_pInt)
     s = sum(lattice_NsymOperations(1:symmetry-1_pInt))
      do i = 1_pInt,2_pInt
        dQ = math_qConj(dQ)                                                                         ! switch order of "from -- to"
       do j = 1_pInt,lattice_NsymOperations(symmetry)                                               ! run through first crystal's symmetries
          dQsymA = math_qMul(lattice_symOperations(1:4,s+j),dQ)                                     ! apply sym
         do k = 1_pInt,lattice_NsymOperations(symmetry)                                             ! run through 2nd crystal's symmetries
            mis = math_qMul(dQsymA,lattice_symOperations(1:4,s+k))                                  ! apply sym
            if (mis(1) < 0.0_pReal) &                                                               ! want positive angle
              mis = -mis
           if (mis(1)-lattice_qDisorientation(1) > -tol_math_check &
             .and. lattice_qInSST(mis,LATTICE_undefined_ID)) lattice_qDisorientation = mis                      ! found better one
      enddo; enddo; enddo
   case (0_pInt)
     if (lattice_qDisorientation(1) < 0.0_pReal) lattice_qDisorientation = -lattice_qDisorientation ! keep omega within 0 to 180 deg
  end select

end function lattice_qDisorientation

end module lattice
