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

  !% Defines an object class for merger trees.

  type, public :: mergerTree
     !% The merger tree object type.
     integer         (kind=kind_int8            )                  :: index
     type            (hdf5Object                )                  :: hdf5Group
     double precision                                              :: volumeWeight                    , initializedUntil
     type            (treeNode                  ), pointer         :: baseNode               => null()
     type            (mergerTree                ), pointer         :: nextTree               => null(), firstTree        => null()
     type            (universe                  ), pointer         :: hostUniverse           => null()
     type            (treeEvent                 ), pointer, public :: event
     class           (randomNumberGeneratorClass), pointer         :: randomNumberGenerator_ => null()
     type            (doubleScalarHash)                            :: properties
   contains
     ! Tree creation/destruction.
     !@ <objectMethods>
     !@   <object>mergerTree</object>
     !@   <objectMethod>
     !@     <method>destroy</method>
     !@     <description>Destroys the merger tree, including all nodes and their components.</description>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>getNode</method>
     !@     <description>Returns a pointer to the node with given index in the merger tree, or a null pointer if no such node exists.</description>
     !@     <type>\textcolor{red}{\textless *type(treeNode)\textgreater}</type>
     !@     <arguments>\textcolor{red}{\textless integer(kind\_int8)\textgreater} nodeIndex\argin</arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>createEvent</method>
     !@    <description>Create a {\normalfont \ttfamily treeEvent} object in this tree.</description>
     !@     <type>\textcolor{red}{\textless *type(treeEvent)\textgreater}</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>removeEvent</method>
     !@    <description>Remove a {\normalfont \ttfamily treeEvent} from this tree.</description>
     !@     <type>\void</type>
     !@     <arguments>\textcolor{red}{\textless type(treeEvent)\textgreater} event\argin</arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>earliestTime</method>
     !@    <description>Return the earliest time in a merger tree.</description>
     !@     <type>\doublezero</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>earliestTimeEvolving</method>
     !@    <description>Return the earliest time in an evolving merger tree.</description>
     !@     <type>\doublezero</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>latestTime</method>
     !@    <description>Return the latest time in a merger tree.</description>
     !@     <type>\doublezero</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@   <objectMethod>
     !@    <method>sizeOf</method>
     !@    <description>Return the size (in bytes) of a merger tree.</description>
     !@     <type>\textcolor{red}{\textless integer(c\_size\_t)\textgreater}</type>
     !@     <arguments></arguments>
     !@   </objectMethod>
     !@ </objectMethods>
     procedure :: destroy              => Merger_Tree_Destroy
     procedure :: getNode              => Merger_Tree_Node_Get
     procedure :: createEvent          => Merger_Tree_Create_Event
     procedure :: removeEvent          => Merger_Tree_Remove_Event
     procedure :: earliestTime         => Merger_Tree_Earliest_Time
     procedure :: earliestTimeEvolving => Merger_Tree_Earliest_Time_Evolving
     procedure :: latestTime           => Merger_Tree_Latest_Time
     procedure :: sizeOf               => Merger_Tree_Size_Of
  end type mergerTree

  interface mergerTree
     !% Interface to merger tree constructors.
     module procedure mergerTreeConstructor
  end interface mergerTree

  type, public :: treeEvent
     !% Type for events attached to trees.
    private
    integer         (kind=kind_int8)         , public :: ID
    type            (mergerTree    ), pointer, public :: tree
    double precision                         , public :: time
    type            (treeEvent     ), pointer, public :: next
    procedure       (treeEventTask ), pointer, public :: task
 end type treeEvent

 ! Interface for tree event tasks.
 abstract interface
    logical function treeEventTask(thisEvent,thisTree,deadlockStatus)
      import treeEvent, mergerTree
      class  (treeEvent ), intent(in   ) :: thisEvent
      type   (mergerTree), intent(inout) :: thisTree
      integer            , intent(inout) :: deadlockStatus
    end function treeEventTask
 end interface

