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

  !% Implementation of a fixed fraction outflow rate due to star formation feedback in galactic spheroids.

  !# <starFormationFeedbackSpheroids name="starFormationFeedbackSpheroidsFixed">
  !#  <description>A fixed fraction outflow rate due to star formation feedback in galactic spheroids.</description>
  !# </starFormationFeedbackSpheroids>
  type, extends(starFormationFeedbackSpheroidsClass) :: starFormationFeedbackSpheroidsFixed
     !% Implementation of a fixed fraction outflow rate due to star formation feedback in galactic spheroids.
     private
     double precision :: fraction
   contains
     procedure :: outflowRate => fixedOutflowRate
  end type starFormationFeedbackSpheroidsFixed

  interface starFormationFeedbackSpheroidsFixed
     !% Constructors for the fixed fraction star formation feedback in spheroids class.
     module procedure fixedConstructorParameters
     module procedure fixedConstructorInternal
  end interface starFormationFeedbackSpheroidsFixed

contains

  function fixedConstructorParameters(parameters) result(self)
    !% Constructor for the fixed fraction star formation feedback in spheroids class which takes a parameter set as input.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    use :: Input_Parameters, only : inputParameter         , inputParameters
    implicit none
    type            (starFormationFeedbackSpheroidsFixed)                :: self
    type            (inputParameters                    ), intent(inout) :: parameters
    double precision                                                     :: fraction

    !# <inputParameter>
    !#   <name>fraction</name>
    !#   <source>parameters</source>
    !#   <defaultValue>0.01d0</defaultValue>
    !#   <description>The ratio of outflow rate to star formation rate in spheroids.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    self=starFormationFeedbackSpheroidsFixed(fraction)
    !# <inputParametersValidate source="parameters"/>
    return
  end function fixedConstructorParameters

  function fixedConstructorInternal(fraction) result(self)
    !% Internal constructor for the fixed star formation feedback from spheroids class.
    implicit none
    type            (starFormationFeedbackSpheroidsFixed)                :: self
    double precision                                     , intent(in   ) :: fraction

    !# <constructorAssign variables="fraction"/>
    return
  end function fixedConstructorInternal

  double precision function fixedOutflowRate(self,node,rateEnergyInput,rateStarFormation)
    !% Returns the outflow rate (in $M_\odot$ Gyr$^{-1}$) for star formation in the galactic spheroid of {\normalfont \ttfamily
    !% node}. Assumes a fixed ratio of outflow rate to star formation rate.
    use :: Stellar_Feedback, only : feedbackEnergyInputAtInfinityCanonical
    implicit none
    class           (starFormationFeedbackSpheroidsFixed), intent(inout) :: self
    type            (treeNode                           ), intent(inout) :: node
    double precision                                     , intent(in   ) :: rateEnergyInput, rateStarFormation
    !GCC$ attributes unused :: node, rateStarFormation

    fixedOutflowRate=+self%fraction                          &
         &           *rateEnergyInput                        &
         &           /feedbackEnergyInputAtInfinityCanonical
    return
  end function fixedOutflowRate
