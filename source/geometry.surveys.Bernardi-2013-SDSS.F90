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

!% Implements the geometry of the SDSS survey used by \cite{bernardi_massive_2013}.


  !# <surveyGeometry name="surveyGeometryBernardi2013SDSS">
  !#  <description>Implements the geometry of the SDSS survey of \cite{bernardi_massive_2013}.</description>
  !# </surveyGeometry>
  type, extends(surveyGeometryMangle) :: surveyGeometryBernardi2013SDSS
     private
   contains
     procedure :: fieldCount                => bernardi2013SDSSFieldCount
     procedure :: distanceMaximum           => bernardi2013SDSSDistanceMaximum
     procedure :: angularPowerMaximumDegree => bernardi2013SDSSAngularPowerMaximumDegree
     procedure :: mangleDirectory           => bernardi2013SDSSMangleDirectory
     procedure :: mangleFiles               => bernardi2013SDSSMangleFiles
     procedure :: pointIncluded             => bernardi2013SDSSPointIncluded
  end type surveyGeometryBernardi2013SDSS

  interface surveyGeometryBernardi2013SDSS
     !% Constructors for the \cite{bernardi_massive_2013} survey geometry class.
     module procedure bernardi2013SDSSConstructorParameters
     module procedure bernardi2013SDSSConstructorInternal
  end interface surveyGeometryBernardi2013SDSS

  ! Angular power spectra.
  integer, parameter :: bernardi2013SDSSAngularPowerMaximumL=360

contains

  function bernardi2013SDSSConstructorParameters(parameters) result (self)
    !% Constructor for the \cite{bernardi_massive_2013} conditional mass function class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameters
    implicit none
    type(surveyGeometryBernardi2013SDSS)                :: self
    type(inputParameters               ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters

    ! Build the object.
    self=surveyGeometryBernardi2013SDSS()
    return
  end function bernardi2013SDSSConstructorParameters

  function bernardi2013SDSSConstructorInternal() result (self)
    !% Default constructor for the \cite{bernardi_massive_2013} conditional mass function class.
    implicit none
    type(surveyGeometryBernardi2013SDSS) :: self

    call self%initialize()
    return
  end function bernardi2013SDSSConstructorInternal

  integer function bernardi2013SDSSFieldCount(self)
    !% Return the number of fields in this sample.
    implicit none
    class(surveyGeometryBernardi2013SDSS), intent(inout) :: self
    !GCC$ attributes unused :: self

    bernardi2013SDSSFieldCount=1
    return
  end function bernardi2013SDSSFieldCount

  double precision function bernardi2013SDSSDistanceMaximum(self,mass,magnitudeAbsolute,luminosity,field)
    !% Compute the maximum distance at which a galaxy is visible.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class           (surveyGeometryBernardi2013SDSS), intent(inout)           :: self
    double precision                                , intent(in   ), optional :: mass           , magnitudeAbsolute, luminosity
    integer                                         , intent(in   ), optional :: field
    double precision                                                          :: logarithmicMass
    !GCC$ attributes unused :: self, field, magnitudeAbsolute, luminosity

    ! Find the limiting distance for this mass completeness limits. (See
    ! constraints/dataAnalysis/stellarMassFunction_SDSS_z0.07_Bernardi/massDistanceRelation.pl for details.)
    logarithmicMass=min(log10(mass),12.5d0)
    bernardi2013SDSSDistanceMaximum                                                         &
         &                         =10.0d0**(                                               &
         &                                                         +1282.1065495948200000d0 &
         &                                   +logarithmicMass*(    - 626.6442739444630000d0 &
         &                                   +logarithmicMass* (   + 122.0914916099620000d0 &
         &                                   +logarithmicMass*  (  -  11.8431000301984000d0 &
         &                                   +logarithmicMass*   ( +   0.5723990783953920d0 &
         &                                   +logarithmicMass*    (-   0.0110301089727899d0 &
         &                                                        )                         &
         &                                                       )                          &
         &                                                      )                           &
         &                                                     )                            &
         &                                                    )                             &
         &                                  )
    return
  end function bernardi2013SDSSDistanceMaximum

  integer function bernardi2013SDSSAngularPowerMaximumDegree(self)
    !% Return the maximum degree for which angular power is computed for the \cite{bernardi_massive_2013} survey.
    implicit none
    class(surveyGeometryBernardi2013SDSS), intent(inout) :: self
    !GCC$ attributes unused :: self

    bernardi2013SDSSAngularPowerMaximumDegree=bernardi2013SDSSAngularPowerMaximumL
    return
  end function bernardi2013SDSSAngularPowerMaximumDegree

  function bernardi2013SDSSMangleDirectory(self)
    !% Return the path to the directory containing \gls{mangle} files.
    use :: Galacticus_Paths, only : galacticusPath, pathTypeExec
    implicit none
    class(surveyGeometryBernardi2013SDSS), intent(inout) :: self
    type (varying_string                )                :: bernardi2013SDSSMangleDirectory
    !GCC$ attributes unused :: self

    bernardi2013SDSSMangleDirectory=galacticusPath(pathTypeExec)//"constraints/dataAnalysis/stellarMassFunction_SDSS_z0.07_Bernardi/"
    return
  end function bernardi2013SDSSMangleDirectory

  subroutine bernardi2013SDSSMangleFiles(self,mangleFiles)
    !% Return a list of \gls{mangle} files.
    use :: File_Utilities  , only : File_Exists            , File_Lock, File_Unlock, lockDescriptor
    use :: Galacticus_Error, only : Galacticus_Error_Report
    use :: System_Command  , only : System_Command_Do
    implicit none
    class  (surveyGeometryBernardi2013SDSS)                           , intent(inout) :: self
    type   (varying_string                ), allocatable, dimension(:), intent(inout) :: mangleFiles
    type   (lockDescriptor                )                                           :: lock
    integer                                                                           :: status

    allocate(mangleFiles(1))
    mangleFiles=                                                    &
         &      [                                                   &
         &       self%mangleDirectory()//"sdss_dr72safe0_res6d.pol" &
         &      ]
    if (.not.File_Exists(mangleFiles(1))) then
       call File_Lock  (char(mangleFiles(1)),lock,lockIsShared=.false.)
       if (.not.File_Exists(mangleFiles(1))) then
          call System_Command_Do("wget http://space.mit.edu/~molly/mangle/download/data/sdss_dr72safe0_res6d.pol.gz -O - | gunzip -c > "//mangleFiles(1),status)
          if (status /= 0 .or. .not.File_Exists(mangleFiles(1))) &
               & call Galacticus_Error_Report('failed to download mangle polygon file'//{introspection:location})
       end if
       call File_Unlock(                     lock                     )
    end if
    return
  end subroutine bernardi2013SDSSMangleFiles

  logical function bernardi2013SDSSPointIncluded(self,point,mass)
    !% Return true if a point is included in the survey geometry.
    use :: Numerical_Constants_Units, only : degree
    use :: Vectors                  , only : Vector_Magnitude
    implicit none
    class           (surveyGeometryBernardi2013SDSS), intent(inout)               :: self
    double precision                                , intent(in   ), dimension(3) :: point
    double precision                                , intent(in   )               :: mass
    double precision                                                              :: pointDistance, rightAscension, &
         &                                                                           declination

    ! Get the distance to the point.
    pointDistance=Vector_Magnitude(point)
    ! Compute if point lies within survey bounds.
    bernardi2013SDSSPointIncluded=                    &
         & pointDistance > self%distanceMinimum(mass) &
         & .and.                                      &
         & pointDistance < self%distanceMaximum(mass)
    if (.not.bernardi2013SDSSPointIncluded) return
    ! Exclude regions with no SDSS coverage.
    bernardi2013SDSSPointIncluded=.false.
    declination   =+90.0d0-acos (point(3)/pointDistance)/degree
    if     (                       &
         &   declination < -15.0d0 &
         &  .or.                   &
         &   declination > +75.0d0 &
         & ) return
    if     ( declination > +30.0d0) then
       rightAscension=    +atan2(point(2),point(1)     )/degree
       if     (                                                           &
            &   (rightAscension >   0.0d0 .and. rightAscension <  90.0d0) &
            &  .or.                                                       &
            &   (rightAscension > 270.0d0 .and. rightAscension < 360.0d0) &
            & ) return
    end if
    ! If point has not been excluded, perform the full test.
    bernardi2013SDSSPointIncluded=manglePointIncluded(self,point,mass)
    return
  end function bernardi2013SDSSPointIncluded
