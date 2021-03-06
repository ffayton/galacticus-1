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

!% Implements a merger tree evolution timestepping class which limits the step to the next epoch at which to record evolution of the
!% main branch galaxy.

  use :: Cosmology_Functions, only : cosmologyFunctions, cosmologyFunctionsClass
  use :: FGSL               , only : fgsl_interp_accel
  use :: Output_Times       , only : outputTimes       , outputTimesClass

  !# <mergerTreeEvolveTimestep name="mergerTreeEvolveTimestepRecordEvolution">
  !#  <description>A merger tree evolution timestepping class which limits the step to the next epoch at which to record evolution of the main branch galaxy.</description>
  !# </mergerTreeEvolveTimestep>
  type, extends(mergerTreeEvolveTimestepClass) :: mergerTreeEvolveTimestepRecordEvolution
     !% Implementation of a merger tree evolution timestepping class which limits the step to the next epoch at which to record
     !% evolution of the main branch galaxy.
     private
     class           (cosmologyFunctionsClass), pointer                   :: cosmologyFunctions_ => null()
     class           (outputTimesClass       ), pointer                   :: outputTimes_ => null()
     logical                                                              :: oneTimeDatasetsWritten
     integer                                                              :: countSteps
     double precision                                                     :: timeBegin               , timeEnd
     double precision                         , allocatable, dimension(:) :: expansionFactor         , massStellar, &
          &                                                                  time                    , massTotal
     type            (fgsl_interp_accel      )                            :: interpolationAccelerator
   contains
     !@ <objectMethods>
     !@   <object>mergerTreeEvolveTimestepRecordEvolution</object>
     !@   <objectMethod>
     !@     <method>reset</method>
     !@     <arguments></arguments>
     !@     <type>\void</type>
     !@     <description>Reset the record of galaxy evolution.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::                 recordEvolutionDestructor
     procedure :: timeEvolveTo => recordEvolutionTimeEvolveTo
     procedure :: autoHook     => recordEvolutionAutoHook
     procedure :: reset        => recordEvolutionReset
  end type mergerTreeEvolveTimestepRecordEvolution

  interface mergerTreeEvolveTimestepRecordEvolution
     !% Constructors for the {\normalfont \ttfamily recordEvolution} merger tree evolution timestep class.
     module procedure recordEvolutionConstructorParameters
     module procedure recordEvolutionConstructorInternal
  end interface mergerTreeEvolveTimestepRecordEvolution

contains

  function recordEvolutionConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily recordEvolution} merger tree evolution timestep class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (mergerTreeEvolveTimestepRecordEvolution)                :: self
    type            (inputParameters                        ), intent(inout) :: parameters
    class           (cosmologyFunctionsClass                ), pointer       :: cosmologyFunctions_
    class           (outputTimesClass                       ), pointer       :: outputTimes_
    double precision                                                         :: timeBegin          , timeEnd, &
         &                                                                      ageUniverse
    integer                                                                  :: countSteps

    !# <objectBuilder class="cosmologyFunctions" name="cosmologyFunctions_" source="parameters"/>
    !# <objectBuilder class="outputTimes"        name="outputTimes_"        source="parameters"/>
    ageUniverse=cosmologyFunctions_%cosmicTime(1.0d0)
    !# <inputParameter>
    !#   <name>timeBegin</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>0.05d0*ageUniverse</defaultValue>
    !#   <description>The earliest time at which to tabulate the evolution of main branch progenitor galaxies (in Gyr).</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>timeEnd</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>ageUniverse</defaultValue>
    !#   <description>The latest time at which to tabulate the evolution of main branch progenitor galaxies (in Gyr).</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>countSteps</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>100</defaultValue>
    !#   <description>The number of steps (spaced logarithmically in cosmic time) at which to tabulate the evolution of main branch progenitor galaxies.</description>
    !#   <source>parameters</source>
    !#   <type>integer</type>
    !# </inputParameter>
    self=mergerTreeEvolveTimestepRecordEvolution(timeBegin,timeEnd,countSteps,cosmologyFunctions_,outputTimes_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="cosmologyFunctions_"/>
    !# <objectDestructor name="outputTimes_"       />
    return
  end function recordEvolutionConstructorParameters

  function recordEvolutionConstructorInternal(timeBegin,timeEnd,countSteps,cosmologyFunctions_,outputTimes_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily recordEvolution} merger tree evolution timestep class.
    use, intrinsic :: ISO_C_Binding    , only : c_size_t
    use            :: Memory_Management, only : allocateArray
    use            :: Numerical_Ranges , only : Make_Range   , rangeTypeLogarithmic
    implicit none
    type            (mergerTreeEvolveTimestepRecordEvolution)                        :: self
    class           (cosmologyFunctionsClass                ), intent(in   ), target :: cosmologyFunctions_
    class           (outputTimesClass                       ), intent(in   ), target :: outputTimes_
    double precision                                         , intent(in   )         :: timeBegin          , timeEnd
    integer                                                  , intent(in   )         :: countSteps
    integer         (c_size_t                               )                        :: timeIndex
    !# <constructorAssign variables="timeBegin, timeEnd, countSteps, *cosmologyFunctions_, *outputTimes_"/>

    call allocateArray(self%time           ,[self%countSteps])
    call allocateArray(self%expansionFactor,[self%countSteps])
    call allocateArray(self%massStellar    ,[self%countSteps])
    call allocateArray(self%massTotal      ,[self%countSteps])
    self%time=Make_Range(self%timeBegin,self%timeEnd,self%countSteps,rangeTypeLogarithmic)
    do timeIndex=1,self%countSteps
       self%expansionFactor(timeIndex)=self%cosmologyFunctions_%expansionFactor(self%time(timeIndex))
    end do
    call self%reset()
    self%oneTimeDatasetsWritten=.false.
    return
  end function recordEvolutionConstructorInternal

  subroutine recordEvolutionAutoHook(self)
    !% Create a hook to the merger tree extra output event to allow us to write out our data.
    use :: Events_Hooks, only : mergerTreeExtraOutputEvent
    implicit none
    class(mergerTreeEvolveTimestepRecordEvolution), intent(inout) :: self

    call mergerTreeExtraOutputEvent%attach(self,recordEvolutionOutput)
   return
  end subroutine recordEvolutionAutoHook

  subroutine recordEvolutionDestructor(self)
    !% Destructor for the {\normalfont \ttfamily recordEvolution} merger tree evolution timestep class.
    implicit none
    type(mergerTreeEvolveTimestepRecordEvolution), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyFunctions_"/>
    !# <objectDestructor name="self%outputTimes_"       />
    return
  end subroutine recordEvolutionDestructor

  double precision function recordEvolutionTimeEvolveTo(self,node,task,taskSelf,report,lockNode,lockType)
    !% Determines the timestep to go to the next tabulation point for galaxy evolution storage.
    use            :: Evolve_To_Time_Reports , only : Evolve_To_Time_Report
    use            :: Galacticus_Nodes       , only : nodeComponentBasic   , treeNode
    use, intrinsic :: ISO_C_Binding          , only : c_size_t
    use            :: ISO_Varying_String     , only : varying_string
    use            :: Numerical_Interpolation, only : Interpolate_Locate
    implicit none
    class           (mergerTreeEvolveTimestepRecordEvolution), intent(inout), target            :: self
    type            (treeNode                               ), intent(inout), target            :: node
    procedure       (timestepTask                           ), intent(  out), pointer           :: task
    class           (*                                      ), intent(  out), pointer           :: taskSelf
    logical                                                  , intent(in   )                    :: report
    type            (treeNode                               ), intent(  out), pointer, optional :: lockNode
    type            (varying_string                         ), intent(  out)         , optional :: lockType
    class           (nodeComponentBasic                     )               , pointer           :: basic
    integer         (c_size_t                               )                                   :: indexTime
    double precision                                                                            :: time

    recordEvolutionTimeEvolveTo =  huge(0.0d0)
    if (present(lockNode)) lockNode => null()
    if (present(lockType)) lockType =  ""
    task                            => null()
    taskSelf                        => null()
    if (node%isOnMainBranch()) then
       basic     => node %basic()
       time      =  basic%time ()
       indexTime =  Interpolate_Locate(self%time,self%interpolationAccelerator,time)
       if (time < self%time(indexTime+1)) then
          recordEvolutionTimeEvolveTo     =  self%time(indexTime+1)
          if (present(lockNode)) lockNode => node
          if (present(lockType)) lockType =  "record evolution"
          task                            => recordEvolutionStore
          taskSelf                        => self
       end if
    end if
    if (report) call Evolve_To_Time_Report("record evolution: ",recordEvolutionTimeEvolveTo)
    return
  end function recordEvolutionTimeEvolveTo

  subroutine recordEvolutionStore(self,tree,node,deadlockStatus)
    !% Store properties of the main progenitor galaxy.
    use            :: Galactic_Structure_Enclosed_Masses, only : Galactic_Structure_Enclosed_Mass
    use            :: Galactic_Structure_Options        , only : massTypeGalactic                , massTypeStellar
    use            :: Galacticus_Error                  , only : Galacticus_Error_Report
    use            :: Galacticus_Nodes                  , only : mergerTree                      , nodeComponentBasic, treeNode
    use, intrinsic :: ISO_C_Binding                     , only : c_size_t
    use            :: Numerical_Interpolation           , only : Interpolate_Locate
    implicit none
    class           (*                 ), intent(inout)          :: self
    type            (mergerTree        ), intent(in   )          :: tree
    type            (treeNode          ), intent(inout), pointer :: node
    integer                             , intent(inout)          :: deadlockStatus
    class           (nodeComponentBasic)               , pointer :: basic
    integer         (c_size_t          )                         :: indexTime
    double precision                                             :: time
    !GCC$ attributes unused :: deadlockStatus, tree

    select type (self)
    class is (mergerTreeEvolveTimestepRecordEvolution)
       basic => node %basic()
       time  =  basic%time ()
       if (time == self%time(self%countSteps)) then
          indexTime=self%countSteps
       else
          indexTime=Interpolate_Locate(self%time,self%interpolationAccelerator,time)
       end if
       self%massStellar(indexTime)=Galactic_Structure_Enclosed_Mass(node,massType=massTypeStellar )
       self%massTotal  (indexTime)=Galactic_Structure_Enclosed_Mass(node,massType=massTypeGalactic)
    class default
       call Galacticus_Error_Report('incorrect class'//{introspection:location})
    end select
    return
  end subroutine recordEvolutionStore

  subroutine recordEvolutionOutput(self,node,iOutput,treeIndex,nodePassesFilter)
    !% Store main branch evolution to the output file.
    use            :: Galacticus_Error                , only : Galacticus_Error_Report
    use            :: Galacticus_HDF5                 , only : galacticusOutputFile
    use            :: IO_HDF5                         , only : hdf5Access             , hdf5Object
    use, intrinsic :: ISO_C_Binding                   , only : c_size_t
    use            :: ISO_Varying_String              , only : var_str                , varying_string
    use            :: Kind_Numbers                    , only : kind_int8
    use            :: Numerical_Constants_Astronomical, only : gigaYear               , massSolar
    use            :: String_Handling                 , only : operator(//)
    implicit none
    class  (*             ), intent(inout) :: self
    type   (treeNode      ), intent(inout) :: node
    integer(c_size_t      ), intent(in   ) :: iOutput
    integer(kind=kind_int8), intent(in   ) :: treeIndex
    logical                , intent(in   ) :: nodePassesFilter
    type   (varying_string)                :: datasetName
    type   (hdf5Object    )                :: outputGroup     , dataset

    select type (self)
    class is (mergerTreeEvolveTimestepRecordEvolution)
       if (nodePassesFilter.and.iOutput == self%outputTimes_%count().and.node%isOnMainBranch()) then
          !$ call hdf5Access%set()
          outputGroup=galacticusOutputFile%openGroup("mainProgenitorEvolution","Evolution data of main progenitors.")
          if (.not.self%oneTimeDatasetsWritten) then
             call outputGroup%writeDataset  (self%time           ,"time"           ,"The time of the main progenitor."            ,datasetReturned=dataset)
             call dataset    %writeAttribute(gigaYear            ,"unitsInSI"                                                                             )
             call dataset    %close         (                                                                                                             )
             call outputGroup%writeDataset  (self%expansionFactor,"expansionFactor","The expansion factor of the main progenitor."                        )
             self%oneTimeDatasetsWritten=.true.
          end if
          datasetName=var_str("stellarMass")//treeIndex
          call outputGroup%writeDataset  (self%massStellar,char(datasetName),"The stellar mass of the main progenitor."       ,datasetReturned=dataset)
          call dataset    %writeAttribute(massSolar       ,"unitsInSI"                                                                                )
          call dataset    %close         (                                                                                                            )
          datasetName=var_str("totalMass"  )//treeIndex
          call outputGroup%writeDataset  (self%massTotal  ,char(datasetName),"The total baryonic mass of the main progenitor.",datasetReturned=dataset)
          call dataset    %writeAttribute(massSolar       ,"unitsInSI"                                                                                )
          call dataset    %close         (                                                                                                            )
          call outputGroup%close         (                                                                                                            )
          !$ call hdf5Access%unset()
          call    self      %reset()
       end if
    class default
       call Galacticus_Error_Report('incorrect class'//{introspection:location})
    end select
    return
  end subroutine recordEvolutionOutput

  subroutine recordEvolutionReset(self)
    !% Resets recorded datasets to zero.
    implicit none
    class(mergerTreeEvolveTimestepRecordEvolution), intent(inout) :: self

    self%massStellar=0.0d0
    self%massTotal  =0.0d0
    return
  end subroutine recordEvolutionReset
