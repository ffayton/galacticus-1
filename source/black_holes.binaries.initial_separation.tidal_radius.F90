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

  !+    Contributions to this file made by:  Stéphane Mangeon, Andrew Benson.

  !% Implements a class for black hole binary initial separation based on tidal disruption of the satellite galaxy.

  !# <blackHoleBinaryInitialSeparation name="blackHoleBinaryInitialSeparationTidalRadius">
  !#  <description>A black hole binary initial separation class in which the radius is based on tidal disruption of the satellite galaxy.</description>
  !# </blackHoleBinaryInitialSeparation>
  type, extends(blackHoleBinaryInitialSeparationClass) :: blackHoleBinaryInitialSeparationTidalRadius
     !% A black hole binary initial separation class in which the radius is based on tidal disruption of the satellite galaxy.
     private
   contains
     procedure :: separationInitial => tidalRadiusSeparationInitial
  end type blackHoleBinaryInitialSeparationTidalRadius

  interface blackHoleBinaryInitialSeparationTidalRadius
     !% Constructors for the {\normalfont \ttfamily tidalRadius} black hole binary initial radius class.
     module procedure tidalRadiusConstructorParameters
  end interface blackHoleBinaryInitialSeparationTidalRadius

  ! Module-scope variables used in root finding.
  double precision                    :: tidalRadiusMassHalf  , tidalRadiusRadiusHalfMass
  type            (treeNode), pointer :: tidalRadiusNode
  !$omp threadprivate(tidalRadiusRadiusHalfMass,tidalRadiusMassHalf,tidalRadiusNode)

contains

  function tidalRadiusConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily tidalRadius} black hole bianry recoild class which takes a parameter list as
    !% input.
    use :: Input_Parameters, only : inputParameters
    implicit none
    type(blackHoleBinaryInitialSeparationTidalRadius)                :: self
    type(inputParameters                            ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters

    self=blackHoleBinaryInitialSeparationTidalRadius()
    return
  end function tidalRadiusConstructorParameters

  double precision function tidalRadiusSeparationInitial(self,node,nodeHost)
    !% Returns an initial separation for a binary black holes through tidal disruption.
    use :: Galactic_Structure_Enclosed_Masses, only : Galactic_Structure_Enclosed_Mass, Galactic_Structure_Radius_Enclosing_Mass
    use :: Galactic_Structure_Options        , only : massTypeGalactic
    use :: Galacticus_Nodes                  , only : nodeComponentBlackHole          , treeNode
    use :: Root_Finder                       , only : rangeExpandMultiplicative       , rangeExpandSignExpectNegative           , rangeExpandSignExpectPositive, rootFinder
    implicit none
    class(blackHoleBinaryInitialSeparationTidalRadius), intent(inout)         :: self
    type (treeNode                                   ), intent(inout), target :: nodeHost , node
    class(nodeComponentBlackHole                     ), pointer               :: blackHole
    type (rootFinder                                 ), save                  :: finder
    !$omp threadprivate(finder)
    !GCC$ attributes unused :: self

    ! Assume zero separation by default.
    tidalRadiusSeparationInitial=0.0d0
    ! Get the black hole component.
    blackHole => node%blackHole(instance=1)
    ! If the primary black hole has zero mass (i.e. has been ejected), then return immediately.
    if (blackHole%mass() <= 0.0d0) return
    ! Get the half-mass radius of the satellite galaxy.
    tidalRadiusRadiusHalfMass=Galactic_Structure_Radius_Enclosing_Mass(node,fractionalMass=0.5d0                    ,massType=massTypeGalactic)
    ! Get the mass within the half-mass radius.
    tidalRadiusMassHalf      =Galactic_Structure_Enclosed_Mass        (node,               tidalRadiusRadiusHalfMass,massType=massTypeGalactic)
    ! Return zero radius for massless galaxy.
    if (tidalRadiusRadiusHalfMass <= 0.0d0 .or. tidalRadiusMassHalf <= 0.0d0) return
    ! Initialize our root finder.
    if (.not.finder%isInitialized()) then
       call finder%rootFunction(tidalRadiusRoot)
       call finder%rangeExpand (                                                             &
            &                   rangeExpandDownward          =0.5d+0                       , &
            &                   rangeExpandUpward            =2.0d+0                       , &
            &                   rangeExpandDownwardSignExpect=rangeExpandSignExpectPositive, &
            &                   rangeExpandUpwardSignExpect  =rangeExpandSignExpectNegative, &
            &                   rangeExpandType              =rangeExpandMultiplicative      &
            &                  )
       call finder%tolerance   (                                                             &
            &                   toleranceAbsolute            =0.0d+0                       , &
            &                   toleranceRelative            =1.0d-6                         &
            &                  )
    end if
    ! Solve for the radius around the host at which the satellite gets disrupted.
    tidalRadiusNode              => nodeHost
    tidalRadiusSeparationInitial =  finder%find(                                                                              &
         &                                      rootGuess=Galactic_Structure_Radius_Enclosing_Mass(                           &
         &                                                                                         nodeHost                 , &
         &                                                                                         fractionalMass=0.5d0     , &
         &                                                                                         massType=massTypeGalactic  &
         &                                                                                        )                           &
         &                                     )
    return
  end function tidalRadiusSeparationInitial

  double precision function tidalRadiusRoot(radius)
    !% Root function used in solving for the radius of tidal disruption of a satellite galaxy.
    use :: Galactic_Structure_Enclosed_Masses, only : Galactic_Structure_Enclosed_Mass
    use :: Galactic_Structure_Options        , only : massTypeGalactic
    implicit none
    double precision, intent(in   ) :: radius

    ! Evaluate the root function.
    tidalRadiusRoot=+Galactic_Structure_Enclosed_Mass(tidalRadiusNode,radius,massType=massTypeGalactic) &
         &          /tidalRadiusMassHalf                                                                &
         &          -(                                                                                  &
         &            +radius                                                                           &
         &            /tidalRadiusRadiusHalfMass                                                        &
         &           )**3
    return
  end function tidalRadiusRoot
