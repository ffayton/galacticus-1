!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

  !% An implementation of the intergalactic medium state class for a simplistic model of instantaneous and full reionization.

  !# <accretionHaloTotal name="accretionHaloTotalBertschinger">
  !#  <description>A halo total accretion class which assumes the accretion corresponds to the basic mass.</description>
  !# </accretionHaloTotal>
  type, extends(accretionHaloTotalClass) :: accretionHaloTotalBertschinger
     !% A halo total accretion class which assumes the accretion corresponds to the Bertschinger mass.
     private
   contains
     procedure :: accretionRate => bertschingerAccretionRate
     procedure :: accretedMass  => bertschingerAccretedMass
  end type accretionHaloTotalBertschinger

  interface accretionHaloTotalBertschinger
     !% Constructors for the bertschinger total halo accretion class.
     module procedure bertschingerConstructorParameters
  end interface accretionHaloTotalBertschinger

contains

  function bertschingerConstructorParameters(parameters) result (self)
    !% Constructor for the bertschinger total halo accretion state class which takes a parameter set as input.
    use Input_Parameters2
    implicit none
    type(accretionHaloTotalBertschinger)                :: self
    type(inputParameters               ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters

    self=accretionHaloTotalBertschinger()
    return
  end function bertschingerConstructorParameters

  double precision function bertschingerAccretionRate(self,node)
    !% Return the accretion rate onto a halo.
    implicit none
    class(accretionHaloTotalBertschinger), intent(inout) :: self
    type (treeNode                      ), intent(inout) :: node
    class(nodeComponentBasic            ), pointer       :: basic
    !GCC$ attributes unused :: self

    basic                     => node %basic                    ()
    bertschingerAccretionRate =  basic%accretionRateBertschinger()
    return
  end function bertschingerAccretionRate

  double precision function bertschingerAccretedMass(self,node)
    !% Return the mass accreted onto a halo.
    implicit none
    class(accretionHaloTotalBertschinger), intent(inout) :: self
    type (treeNode                      ), intent(inout) :: node
    class(nodeComponentBasic            ), pointer       :: basic
    !GCC$ attributes unused :: self

    basic                    => node %basic           ()
    bertschingerAccretedMass =  basic%massBertschinger()
    return
  end function bertschingerAccretedMass