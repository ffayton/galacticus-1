!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
!!           2019, 2020
!!    Andrew Benson <abenson@carnegiescience.edu>
!!
!! This file is part of Galacticus.
!!
!!    Galacticus is free software: you can redistribute it and/or modify
!!    it under the terms of the GNU General Public License as published by
!!    the Free Software Foundation, either version 3 of the License, or
!!    (at your option) any later version.
!!
!!    Galacticus is distributed in the hope that it will be useful,
!!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!    GNU General Public License for more details.
!!
!!    You should have received a copy of the GNU General Public License
!!    along with Galacticus.  If not, see <http://www.gnu.org/licenses/>.

!% Contains a program to test ODE solver routines.

program Test_ODE_Solver
  !% Tests that ODE solver routines work.
  use :: FGSL                     , only : fgsl_odeiv_control            , fgsl_odeiv_evolve     , fgsl_odeiv_step     , fgsl_odeiv_system
  use :: Galacticus_Display       , only : Galacticus_Verbosity_Level_Set, verbosityStandard
  use :: ODE_Solver               , only : ODE_Solve                     , ODE_Solver_Free
  use :: Test_ODE_Solver_Functions, only : ODE_Set_1                     , ODE_Set_2
  use :: Unit_Tests               , only : Assert                        , Unit_Tests_Begin_Group, Unit_Tests_End_Group, Unit_Tests_Finish
  implicit none
  double precision                    , dimension(10) :: xEnd
  double precision                    , dimension( 2) :: y
  type            (fgsl_odeiv_step   )                :: odeStepper
  type            (fgsl_odeiv_control)                :: odeController
  type            (fgsl_odeiv_evolve )                :: odeEvolver
  type            (fgsl_odeiv_system )                :: odeSystem
  logical                                             :: odeReset
  integer                                             :: i
  double precision                                    :: xStart
  character       (len=32            )                :: message

  ! Set verbosity level.
  call Galacticus_Verbosity_Level_Set(verbosityStandard)

  ! Begin unit tests.
  call Unit_Tests_Begin_Group("ODE solver")

  ! Sinusoid.
  call Unit_Tests_Begin_Group("y'=sin(x)")
  xEnd=[1.0d0,2.0d0,3.0d0,4.0d0,5.0d0,6.0d0,7.0d0,8.0d0,9.0d0,10.0d0]
  do i=1,size(xEnd)
     odeReset=.true.
     y(1:1)=[0.0d0]
     xStart=0.0d0
     call ODE_Solve(odeStepper,odeController,odeEvolver,odeSystem,xStart,xEnd(i),1,y(1:1)&
          &,ODE_Set_1,toleranceAbsolute=0.0d0,toleranceRelative=1.0d-9,reset=odeReset)
     call ODE_Solver_Free(odeStepper,odeController,odeEvolver,odeSystem)
     write (message,'(a,f4.1)') "x=0 to ",xEnd(i)
     call Assert(trim(message),y(1:1),1.0d0-cos(xEnd(i:i)),relTol=1.0d-6)
  end do
  call Unit_Tests_End_Group()

  ! Harmonic oscillator.
  call Unit_Tests_Begin_Group("y''=-y")
  xEnd=[1.0d0,2.0d0,3.0d0,4.0d0,5.0d0,6.0d0,7.0d0,8.0d0,9.0d0,10.0d0]
  do i=1,size(xEnd)
     odeReset=.true.
     y(1:2)=[1.0d0,0.0d0]
     xStart=0.0d0
     call ODE_Solve(odeStepper,odeController,odeEvolver,odeSystem,xStart,xEnd(i),2,y(1:2)&
          &,ODE_Set_2,toleranceAbsolute=0.0d0,toleranceRelative=1.0d-9,reset=odeReset)
     call ODE_Solver_Free(odeStepper,odeController,odeEvolver,odeSystem)
     write (message,'(a,f4.1)') "x=0 to ",xEnd(i)
     call Assert(trim(message),y(1:2),[cos(xEnd(i)),-sin(xEnd(i))],relTol=1.0d-6)
  end do
  call Unit_Tests_End_Group()

  ! End unit tests.
  call Unit_Tests_End_Group()
  call Unit_Tests_Finish()

end program Test_ODE_Solver
