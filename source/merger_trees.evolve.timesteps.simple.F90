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

  use :: Cosmology_Functions, only : cosmologyFunctions, cosmologyFunctionsClass

  !# <mergerTreeEvolveTimestep name="mergerTreeEvolveTimestepSimple">
  !#  <description>A merger tree evolution timestepping class which limits the step to a fraction of the current time or an absolute step, whichever is smaller.</description>
  !# </mergerTreeEvolveTimestep>
  type, extends(mergerTreeEvolveTimestepClass) :: mergerTreeEvolveTimestepSimple
     !% Implementation of an output times class which reads a simple of output times from a parameter.
     private
     class           (cosmologyFunctionsClass), pointer :: cosmologyFunctions_ => null()
     double precision                                   :: timeStepAbsolute   , timeStepRelative
   contains
     final     ::                 simpleDestructor
     procedure :: timeEvolveTo => simpleTimeEvolveTo
  end type mergerTreeEvolveTimestepSimple

  interface mergerTreeEvolveTimestepSimple
     !% Constructors for the {\normalfont \ttfamily simple} merger tree evolution timestep class.
     module procedure simpleConstructorParameters
     module procedure simpleConstructorInternal
  end interface mergerTreeEvolveTimestepSimple

contains

  function simpleConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily simple} merger tree evolution timestep class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (mergerTreeEvolveTimestepSimple)                :: self
    type            (inputParameters               ), intent(inout) :: parameters
    class           (cosmologyFunctionsClass       ), pointer       :: cosmologyFunctions_
    double precision                                                :: timeStepAbsolute   , timeStepRelative

    !# <inputParameter>
    !#   <name>timeStepRelative</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>0.1d0</defaultValue>
    !#   <description>The maximum allowed relative change in time for a single step in the evolution of a node.</description>
    !#   <group>timeStepping</group>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>timeStepAbsolute</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>1.0d0</defaultValue>
    !#   <description>The maximum allowed absolute change in time (in Gyr) for a single step in the evolution of a node.</description>
    !#   <group>timeStepping</group>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <objectBuilder class="cosmologyFunctions" name="cosmologyFunctions_" source="parameters"/>
    self=mergerTreeEvolveTimestepSimple(timeStepAbsolute,timeStepRelative,cosmologyFunctions_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="cosmologyFunctions_"/>
    return
  end function simpleConstructorParameters

  function simpleConstructorInternal(timeStepAbsolute,timeStepRelative,cosmologyFunctions_) result(self)
    !% Constructor for the {\normalfont \ttfamily simple} merger tree evolution timestep class which takes a parameter set as input.
    implicit none
    type            (mergerTreeEvolveTimestepSimple)                        :: self
    double precision                                , intent(in   )         :: timeStepAbsolute   , timeStepRelative
    class           (cosmologyFunctionsClass       ), intent(in   ), target :: cosmologyFunctions_
    !# <constructorAssign variables="timeStepAbsolute, timeStepRelative, *cosmologyFunctions_"/>

    return
  end function simpleConstructorInternal

  subroutine simpleDestructor(self)
    !% Destructor for the {\normalfont \ttfamily simple} merger tree evolution timestep class.
    implicit none
    type(mergerTreeEvolveTimestepSimple), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyFunctions_"/>
    return
  end subroutine simpleDestructor

  double precision function simpleTimeEvolveTo(self,node,task,taskSelf,report,lockNode,lockType)
    !% Determine a suitable timestep for {\normalfont \ttfamily node} using the simple method. This simply selects the smaller of {\normalfont \ttfamily
    !% timeStepAbsolute} and {\normalfont \ttfamily timeStepRelative}$H^{-1}(t)$.
    use :: Evolve_To_Time_Reports, only : Evolve_To_Time_Report
    use :: Galacticus_Nodes      , only : nodeComponentBasic   , treeNode
    use :: ISO_Varying_String    , only : varying_string
    implicit none
    class           (mergerTreeEvolveTimestepSimple), intent(inout), target            :: self
    type            (treeNode                      ), intent(inout), target            :: node
    procedure       (timestepTask                  ), intent(  out), pointer           :: task
    class           (*                             ), intent(  out), pointer           :: taskSelf
    logical                                         , intent(in   )                    :: report
    type            (treeNode                      ), intent(  out), pointer, optional :: lockNode
    type            (varying_string                ), intent(  out)         , optional :: lockType
    class           (nodeComponentBasic            )               , pointer           :: basic
    double precision                                                                   :: expansionFactor, timescaleExpansion, &
         &                                                                                time

    ! Find current expansion timescale.
    basic => node%basic()
    if (self%timeStepRelative > 0.0d0) then
       time               =        basic                    %time           (               )
       expansionFactor    =        self %cosmologyFunctions_%expansionFactor(           time)
       timescaleExpansion =  1.0d0/self %cosmologyFunctions_%expansionRate  (expansionFactor)
       simpleTimeEvolveTo =  min(self%timestepRelative*timescaleExpansion,self%timeStepAbsolute)+basic%time()
    else
       simpleTimeEvolveTo =                                               self%timeStepAbsolute +basic%time()
    end if
    task                            => null()
    taskSelf                        => null()
    if (present(lockNode)) lockNode => node
    if (present(lockType)) lockType =  "simple"
    if (        report   ) call Evolve_To_Time_Report("simple: ",simpleTimeEvolveTo)
    return
  end function simpleTimeEvolveTo
