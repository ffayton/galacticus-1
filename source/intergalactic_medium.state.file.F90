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

!+    Contributions to this file made by:  Luiz Felippe S. Rodrigues.

  !% An implementation of the intergalactic medium state class in which state is read from file.

  use :: FGSL, only : fgsl_interp, fgsl_interp_accel

  ! Current file format version for intergalactic medium state files.
  integer, parameter :: fileFormatVersionCurrent=1

  !# <intergalacticMediumState name="intergalacticMediumStateFile">
  !#  <description>The intergalactic medium state is read from file.</description>
  !# </intergalacticMediumState>
  type, extends(intergalacticMediumStateClass) :: intergalacticMediumStateFile
     !% An \gls{igm} state class which reads state from file.
     private
     ! Name of the file from which to read intergalactic medium state data.
     type            (varying_string   )                            :: fileName
     ! Flag indicating whether or not data has been read.
     logical                                                        :: dataRead                                       =.false.
     ! Data tables.
     integer                                                        :: redshiftCount
     double precision                   , allocatable, dimension(:) :: electronFractionTable                                  , temperatureTable                                    , &
          &                                                            timeTable                                              , ionizedHydrogenFractionTable                        , &
          &                                                            ionizedHeliumFractionTable
     ! Interpolation objects.
     type            (fgsl_interp_accel)                            :: interpolationAcceleratorElectronFraction               , interpolationAcceleratorTemperature                 , &
          &                                                            interpolationAcceleratorIonizedHydrogenFraction        , interpolationAcceleratorIonizedHeliumFraction
     type            (fgsl_interp      )                            :: interpolationObjectElectronFraction                    , interpolationObjectTemperature                      , &
          &                                                            interpolationObjectIonizedHydrogenFraction             , interpolationObjectIonizedHeliumFraction
     logical                                                        :: interpolationResetElectronFraction             =.true. , interpolationResetTemperature                =.true., &
          &                                                            interpolationResetIonizedHydrogenFraction      =.true. , interpolationResetIonizedHeliumFraction      =.true.
     integer                                                        :: extrapolationType
   contains
     final     ::                                fileDestructor
     procedure :: electronFraction            => fileElectronFraction
     procedure :: neutralHydrogenFraction     => fileNeutralHydrogenFraction
     procedure :: neutralHeliumFraction       => fileNeutralHeliumFraction
     procedure :: singlyIonizedHeliumFraction => fileSinglyIonizedHeliumFraction
     procedure :: temperature                 => fileTemperature
  end type intergalacticMediumStateFile

  interface intergalacticMediumStateFile
     !% Constructors for the file intergalactic medium state class.
     module procedure fileConstructorParameters
     module procedure fileConstructorInternal
  end interface intergalacticMediumStateFile

contains

  function fileConstructorParameters(parameters) result(self)
    !% Default constructor for the file \gls{igm} state class.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type (intergalacticMediumStateFile)                :: self
    type (inputParameters             ), intent(inout) :: parameters
    class(cosmologyFunctionsClass     ), pointer       :: cosmologyFunctions_
    class(cosmologyParametersClass    ), pointer       :: cosmologyParameters_
    type (varying_string              )                :: fileName

    !# <inputParameter>
    !#   <name>fileName</name>
    !#   <source>parameters</source>
    !#   <variable>fileName</variable>
    !#   <description>The name of the file from which to read intergalactic medium state data.</description>
    !#   <type>string</type>
    !#   <cardinality>1</cardinality>
    !# </inputParameter>
    !# <objectBuilder class="cosmologyFunctions"  name="cosmologyFunctions_"  source="parameters"/>
    !# <objectBuilder class="cosmologyParameters" name="cosmologyParameters_" source="parameters"/>
    self=intergalacticMediumStateFile(fileName,cosmologyFunctions_,cosmologyParameters_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="cosmologyFunctions_" />
    !# <objectDestructor name="cosmologyParameters_"/>
    return
  end function fileConstructorParameters

  function fileConstructorInternal(fileName,cosmologyFunctions_,cosmologyParameters_) result(self)
    !% Constructor for the file \gls{igm} state class.
    use :: File_Utilities, only : File_Name_Expand
    implicit none
    type (intergalacticMediumStateFile)                        :: self
    type (varying_string              ), intent(in   )         :: fileName
    class(cosmologyFunctionsClass     ), intent(inout), target :: cosmologyFunctions_
    class(cosmologyParametersClass    ), intent(inout), target :: cosmologyParameters_
    !# <constructorAssign variables="*cosmologyFunctions_, *cosmologyParameters_"/>

    self%fileName=File_Name_Expand(char(fileName))
    return
  end function fileConstructorInternal

  subroutine fileDestructor(self)
    !% Destructor for the file \gls{igm} state class.
    implicit none
    type(intergalacticMediumStateFile), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyParameters_"/>
    !# <objectDestructor name="self%cosmologyFunctions_" />
    return
  end subroutine fileDestructor

  subroutine fileReadData(self)
    !% Read in data describing the state of the intergalactic medium.
    use :: File_Utilities  , only : File_Exists
    use :: Galacticus_Error, only : Galacticus_Error_Report
    use :: IO_HDF5         , only : hdf5Access             , hdf5Object
    use :: Table_Labels    , only : extrapolationTypeAbort , extrapolationTypeExtrapolate
    implicit none
    class  (intergalacticMediumStateFile), intent(inout) :: self
    integer                                              :: fileFormatVersion   , iRedshift, &
         &                                                  extrapolationAllowed
    type   (hdf5Object                  )                :: file

    ! Check if data has yet to be read.
    if (.not.self%dataRead) then
       if (.not.File_Exists(char(self%fileName))) call Galacticus_Error_Report('Unable to find intergalactic medium state file "' //char(self%fileName)//'"'//{introspection:location})
       call hdf5Access%set()
       ! Open the file.
       call file%openFile(char(self%fileName),readOnly=.true.)
       ! Check the file format version of the file.
       call file%readAttribute('fileFormat',fileFormatVersion)
       if (fileFormatVersion /= fileFormatVersionCurrent) call Galacticus_Error_Report('file format version is out of date'//{introspection:location})
       ! Check if extrapolation is allowed.
       self%extrapolationType=extrapolationTypeAbort
       if (file%hasAttribute('extrapolationAllowed')) then
          call file%readAttribute('extrapolationAllowed',extrapolationAllowed)
          if (extrapolationAllowed /= 0) self%extrapolationType=extrapolationTypeExtrapolate
       end if
       call file%readAttribute('fileFormat',fileFormatVersion)
       ! Read the data.
       call file%readDataset('redshift'         ,self%timeTable                   )
       call file%readDataset('electronFraction' ,self%electronFractionTable       )
       call file%readDataset('hIonizedFraction' ,self%ionizedHydrogenFractionTable)
       call file%readDataset('heIonizedFraction',self%ionizedHeliumFractionTable  )
       call file%readDataset('matterTemperature',self%temperatureTable            )
       call file%close      (                                                     )
       call hdf5Access%unset()
       self%redshiftCount=size(self%timeTable)
       ! Convert redshifts to times.
       do iRedshift=1,self%redshiftCount
          self%timeTable(iRedshift)=self%cosmologyFunctions_%cosmicTime(self%cosmologyFunctions_%expansionFactorFromRedshift(self%timeTable(iRedshift)))
       end do
       ! Flag that data has now been read.
       self%dataRead=.true.
    end if
    return
  end subroutine fileReadData

  double precision function fileTemperature(self,time)
    !% Return the temperature of the intergalactic medium at the specified {\normalfont \ttfamily time} by interpolating in tabulated data.
    use :: Numerical_Interpolation, only : Interpolate
    implicit none
    class           (intergalacticMediumStateFile), intent(inout) :: self
    double precision                              , intent(in   ) :: time

    ! Ensure that data has been read.
    call fileReadData(self)
    ! Interpolate in the tables to get the electron fraction.
    fileTemperature=max(                                                                        &
         &              0.0d0                                                                 , &
         &              Interpolate(                                                            &
         &                                            self%timeTable                          , &
         &                                            self%temperatureTable                   , &
         &                                            self%interpolationObjectTemperature     , &
         &                                            self%interpolationAcceleratorTemperature, &
         &                                                 time                               , &
         &                          reset            =self%interpolationResetTemperature      , &
         &                          extrapolationType=self%extrapolationType                    &
         &                         )                                                            &
         &             )
    return
  end function fileTemperature

  double precision function fileElectronFraction(self,time)
    !% Return the electron fraction in the intergalactic medium at the specified {\normalfont \ttfamily time} by interpolating in tabulated data,
    use :: Numerical_Interpolation, only : Interpolate
    implicit none
    class           (intergalacticMediumStateFile), intent(inout) :: self
    double precision                              , intent(in   ) :: time

    ! Ensure that data has been read.
    call fileReadData(self)
    ! Interpolate in the tables to get the electron fraction.
    fileElectronFraction=min(                                                                                 &
         &                       1.0d0                                                                      , &
         &                   max(                                                                             &
         &                       0.0d0                                                                      , &
         &                       Interpolate(                                                                 &
         &                                                     self%timeTable                               , &
         &                                                     self%electronFractionTable                   , &
         &                                                     self%interpolationObjectElectronFraction     , &
         &                                                     self%interpolationAcceleratorElectronFraction, &
         &                                                          time                                    , &
         &                                   reset            =self%interpolationResetElectronFraction      , &
         &                                   extrapolationType=self%extrapolationType                         &
         &                                  )                                                                 &
         &                       )                                                                            &
         &                  )
    return
  end function fileElectronFraction

  double precision function fileNeutralHydrogenFraction(self,time)
    !% Return the neutral hydrogen fraction in the intergalactic medium at the specified {\normalfont \ttfamily time} by interpolating in tabulated data,
    use :: Numerical_Interpolation, only : Interpolate
    implicit none
    class           (intergalacticMediumStateFile), intent(inout) :: self
    double precision                              , intent(in   ) :: time

    ! Ensure that data has been read.
    call fileReadData(self)
    ! Interpolate in the tables to get the electron fraction.
    fileNeutralHydrogenFraction=+1.0d0                                                                                       &
         &                      -min(                                                                                        &
         &                               1.0d0                                                                             , &
         &                           max(                                                                                    &
         &                               0.0d0                                                                             , &
         &                               Interpolate(                                                                        &
         &                                                             self%timeTable                                      , &
         &                                                             self%ionizedHydrogenFractionTable                   , &
         &                                                             self%interpolationObjectIonizedHydrogenFraction     , &
         &                                                             self%interpolationAcceleratorIonizedHydrogenFraction, &
         &                                                                  time                                           , &
         &                                           reset            =self%interpolationResetIonizedHydrogenFraction      , &
         &                                           extrapolationType=self%extrapolationType                                &
         &                                          )                                                                        &
         &                              )                                                                                    &
         &                          )
    return
  end function fileNeutralHydrogenFraction

  double precision function fileNeutralHeliumFraction(self,time)
    !% Return the neutral helium fraction in the intergalactic medium at the specified {\normalfont \ttfamily time} by interpolating in tabulated data,
    use :: Numerical_Interpolation, only : Interpolate
    implicit none
    class           (intergalacticMediumStateFile), intent(inout) :: self
    double precision                              , intent(in   ) :: time

    ! Ensure that data has been read.
    call fileReadData(self)
    ! Interpolate in the tables to get the electron fraction.
    fileNeutralHeliumFraction=+1.0d0                                                                                     &
         &                    -min(                                                                                      &
         &                             1.0d0                                                                           , &
         &                         max(                                                                                  &
         &                             0.0d0                                                                           , &
         &                             Interpolate(                                                                      &
         &                                                           self%timeTable                                    , &
         &                                                           self%ionizedHeliumFractionTable                   , &
         &                                                           self%interpolationObjectIonizedHeliumFraction     , &
         &                                                           self%interpolationAcceleratorIonizedHeliumFraction, &
         &                                                                time                                         , &
         &                                         reset            =self%interpolationResetIonizedHeliumFraction      , &
         &                                         extrapolationType=self%extrapolationType                              &
         &                                        )                                                                      &
         &                            )                                                                                  &
         &                        )
    return
  end function fileNeutralHeliumFraction

  double precision function fileSinglyIonizedHeliumFraction(self,time)
    !% Return the neutral helium fraction in the intergalactic medium at the specified {\normalfont \ttfamily time} by interpolating in tabulated data,
    use :: Numerical_Interpolation, only : Interpolate
    implicit none
    class           (intergalacticMediumStateFile), intent(inout) :: self
    double precision                              , intent(in   ) :: time

    ! Ensure that data has been read.
    call fileReadData(self)
    ! Interpolate in the tables to get the electron fraction.
    fileSinglyIonizedHeliumFraction=min(                                                                                      &
         &                                  1.0d0                                                                           , &
         &                              max(                                                                                  &
         &                                  0.0d0                                                                           , &
         &                                  Interpolate(                                                                      &
         &                                                                self%timeTable                                    , &
         &                                                                self%ionizedHeliumFractionTable                   , &
         &                                                                self%interpolationObjectIonizedHeliumFraction     , &
         &                                                                self%interpolationAcceleratorIonizedHeliumFraction, &
         &                                                                     time                                         , &
         &                                              reset            =self%interpolationResetIonizedHeliumFraction      , &
         &                                              extrapolationType=self%extrapolationType                              &
         &                                             )                                                                      &
         &                                 )                                                                                  &
         &                             )
    return
  end function fileSinglyIonizedHeliumFraction
