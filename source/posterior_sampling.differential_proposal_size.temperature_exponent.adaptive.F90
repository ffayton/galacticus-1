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

  !% Implementation of a posterior sampling differential evolution proposal size temperature exponent class in which the exponent
  !% is adaptive.

  !# <posteriorSampleDffrntlEvltnPrpslSzTmpExp name="posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive">
  !#  <description>A posterior sampling differential evolution proposal size class in which the exponent is adaptive.</description>
  !# </posteriorSampleDffrntlEvltnPrpslSzTmpExp>
  type, extends(posteriorSampleDffrntlEvltnPrpslSzTmpExpClass) :: posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive
     !% Implementation of a posterior sampling differential evolution proposal size class in which the exponent is adaptive.
     private
     double precision :: exponentCurrent, exponentAdjustFactor, &
          &              exponentInitial
     double precision :: exponentMinimum, exponentMaximum
     double precision :: gradientMinimum, gradientMaximum
     integer          :: updateCount    , lastUpdateCount
   contains
     procedure :: exponent => adaptiveExponent
  end type posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive

  interface posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive
     !% Constructors for the {\normalfont \ttfamily adaptive} posterior sampling differential evolution random jump class.
     module procedure adaptiveConstructorParameters
     module procedure adaptiveConstructorInternal
  end interface posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive

contains

  function adaptiveConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily adaptive} posterior sampling differential evolution random jump class which
    !% builds the object from a parameter set.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive)                 :: self
    type            (inputParameters                                 ), intent(inout)  :: parameters
    double precision                                                                   :: exponentInitial, exponentMinimum     , &
         &                                                                                exponentMaximum, exponentAdjustFactor, &
         &                                                                                gradientMinimum, gradientMaximum
    integer                                                                            :: updateCount

    !# <inputParameter>
    !#   <name>exponentInitial</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The initial exponent.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>exponentMinimum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The minimum allowed exponent.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>exponentMaximum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The maximum allowed exponent.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>exponentAdjustFactor</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The factor by which to adjust the exponent.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>gradientMinimum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The minimum acceptable gradient of acceptance rate with log-temperature.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>gradientMaximum</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The maximum acceptable gradient of acceptance rate with log-temperature.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>updateCount</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The number of steps between potential updates of the temperature exponent.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    self=posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive(exponentInitial,exponentMinimum,exponentMaximum,exponentAdjustFactor,gradientMinimum,gradientMaximum,updateCount)
    !# <inputParametersValidate source="parameters"/>
    return
  end function adaptiveConstructorParameters

  function adaptiveConstructorInternal(exponentInitial,exponentMinimum,exponentMaximum,exponentAdjustFactor,gradientMinimum,gradientMaximum,updateCount) result(self)
    !% Constructor for the ``adaptive'' differential evolution proposal size class.
    implicit none
    type            (posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive)                :: self
    double precision                                                  , intent(in   ) :: exponentInitial, exponentAdjustFactor, &
         &                                                                               exponentMinimum, exponentMaximum     , &
         &                                                                               gradientMinimum, gradientMaximum
    integer                                                           , intent(in   ) :: updateCount
    !# <constructorAssign variables="exponentInitial,exponentMinimum,exponentMaximum,exponentAdjustFactor,gradientMinimum,gradientMaximum,updateCount"/>

    self%exponentCurrent=exponentInitial
    self%lastUpdateCount=0
    return
  end function adaptiveConstructorInternal

double precision function adaptiveExponent(self,temperedStates,temperatures,simulationState,simulationConvergence)
  !% Return the adaptive differential evolution proposal size temperature exponent.
  use :: Galacticus_Display, only : Galacticus_Display_Indent, Galacticus_Display_Message, Galacticus_Display_Unindent, Galacticus_Verbosity_Level, &
          &                         verbosityInfo
  use :: ISO_Varying_String, only : varying_string
  use :: MPI_Utilities     , only : mpiSelf
  use :: String_Handling   , only : operator(//)
  implicit none
  class           (posteriorSampleDffrntlEvltnPrpslSzTmpExpAdaptive), intent(inout)                                  :: self
  class           (posteriorSampleStateClass                       ), intent(inout)                                  :: simulationState
  class           (posteriorSampleStateClass                       ), intent(inout), dimension(                   :) :: temperedStates
  double precision                                                  , intent(in   ), dimension(                   :) :: temperatures
  class           (posteriorSampleConvergenceClass                 ), intent(inout)                                  :: simulationConvergence
  double precision                                                                 , dimension(size(temperedStates)) :: acceptanceRates      , logTemperatures
  integer                                                                                                            :: levelCount           , i
  double precision                                                                                                   :: gradient
  character       (len=8                                           )                                                 :: label
  type            (varying_string                                  )                                                 :: message
  !GCC$ attributes unused :: simulationState

  ! Should we consider updating the exponent?
  levelCount=size(temperedStates)
  if     (                                                                                               &
       &        temperedStates       (levelCount)%count      () >= self%lastUpdateCount+self%updateCount &
       &  .and.                                                                                          &
       &   .not.simulationConvergence            %isConverged()                                          &
       & ) then
     ! Reset the number of steps remaining.
     self%lastUpdateCount=temperedStates(levelCount)%count()
     ! Find the mean acceptance rates across all chains.
     do i=1,levelCount
        acceptanceRates(i)=temperedStates(i)%acceptanceRate()
     end do
     acceptanceRates=mpiSelf%average(acceptanceRates)
     ! Find the gradient of the acceptance rate with log temperature.
     logTemperatures=log(temperatures)
     gradient       =                                                 &
          &           (                                               &
          &            +sum (logTemperatures    *    acceptanceRates) &
          &            -sum (logTemperatures   )*sum(acceptanceRates) &
          &            /dble(levelCount        )                      &
          &           )                                               &
          &          /(                                               &
          &            +sum (logTemperatures**2)                      &
          &            -sum (logTemperatures   )**2                   &
          &            /dble(levelCount        )                      &
          &          )
     ! Report.
     if (mpiSelf%rank() == 0 .and. Galacticus_Verbosity_Level() >= verbosityInfo) then
        message='Tempered acceptance rate report after '
        message=message//temperedStates(levelCount)%count()//' tempered steps:'
        call Galacticus_Display_Indent(message)
        call Galacticus_Display_Message('Temperature Acceptance Rate')
        call Galacticus_Display_Message('---------------------------')
        do i=1,levelCount
           write (label,'(f8.1)') temperatures   (i)
           message="   "//trim(label)
           write (label,'(f5.3)') acceptanceRates(i)
           message=message//"           "//trim(label)
           call Galacticus_Display_Message(message)
        end do
        call Galacticus_Display_Message('---------------------------')
        write (label,'(f8.3)') gradient
        message="Gradient [dR/dln(T)] = "//trim(label)
        call Galacticus_Display_Message(message)
        call Galacticus_Display_Unindent('done')
     end if
     ! If the gradient is out of range, adjust the exponent.
     if      (gradient > self%gradientMaximum .and. self%exponentCurrent < self%exponentMaximum) then
         self%exponentCurrent=min(self%exponentCurrent+self%exponentAdjustFactor,self%exponentMaximum)
         if (mpiSelf%rank() == 0 .and. Galacticus_Verbosity_Level() >= verbosityInfo) then
            write (label,'(f8.5)') self%exponentCurrent
            call Galacticus_Display_Message('Adjusting exponent up to '//label)
         end if
     else if (gradient < self%gradientMinimum .and. self%exponentCurrent > self%exponentMinimum) then
         self%exponentCurrent=max(self%exponentCurrent-self%exponentAdjustFactor,self%exponentMinimum)
         if (mpiSelf%rank() == 0 .and. Galacticus_Verbosity_Level() >= verbosityInfo) then
            write (label,'(f8.5)') self%exponentCurrent
            call Galacticus_Display_Message('Adjusting exponent down to '//label)
         end if
      end if
  end if
  ! Return the current exponent.
  adaptiveExponent=self%exponentCurrent
  return
end function adaptiveExponent
