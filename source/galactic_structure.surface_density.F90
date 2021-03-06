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

!% Contains a module which implements calculations of the surface density at a specific position.

module Galactic_Structure_Surface_Densities
  !% Implements calculations of the surface density at a specific position.
  implicit none
  private
  public :: Galactic_Structure_Surface_Density

  ! Module scope variables used in mapping over components.
  integer                        :: componentTypeShared      , massTypeShared, weightByShared, weightIndexShared
  double precision, dimension(3) :: positionCylindricalShared
  !$omp threadprivate(massTypeShared,componentTypeShared,positionCylindricalShared,weightByShared,weightIndexShared)

contains

  double precision function Galactic_Structure_Surface_Density(thisNode,position,coordinateSystem,componentType,massType,weightBy,weightIndex)
    !% Compute the density (of given {\normalfont \ttfamily massType}) at the specified {\normalfont \ttfamily position}. Assumes that galactic structure has already
    !% been computed.
    use :: Coordinate_Systems        , only : Coordinates_Cartesian_To_Cylindrical, Coordinates_Spherical_To_Cylindrical
    use :: Galactic_Structure_Options, only : componentTypeAll                    , coordinateSystemCartesian           , coordinateSystemCylindrical, coordinateSystemSpherical, &
          &                                   massTypeAll                         , weightByMass                        , weightIndexNull
    use :: Galacticus_Error          , only : Galacticus_Error_Report
    use :: Galacticus_Nodes          , only : optimizeForSurfaceDensitySummation  , optimizeforsurfacedensitysummation  , reductionSummation         , reductionsummation       , &
          &                                   treeNode
    implicit none
    type            (treeNode                 ), intent(inout)           :: thisNode
    integer                                    , intent(in   ), optional :: componentType                     , coordinateSystem, &
         &                                                                  massType                          , weightBy        , &
         &                                                                  weightIndex
    double precision                           , intent(in   )           :: position                       (3)
    procedure       (Component_Surface_Density), pointer                 :: componentSurfaceDensityFunction
    integer                                                              :: coordinateSystemActual

    ! Determine position in cylindrical coordinate system to use.
    if (present(coordinateSystem)) then
       coordinateSystemActual=coordinateSystem
    else
       coordinateSystemActual=coordinateSystemCylindrical
    end if
    if (present(weightBy        )) then
       weightByShared=weightBy
    else
       weightByShared=weightByMass
    end if
    if (present(weightIndex        )) then
       weightIndexShared=weightIndex
    else
       weightIndexShared=weightIndexNull
    end if
    select case (coordinateSystemActual)
    case (coordinateSystemSpherical)
       positionCylindricalShared=Coordinates_Spherical_To_Cylindrical (position)
    case (coordinateSystemCylindrical)
       positionCylindricalShared=position
    case (coordinateSystemCartesian)
       positionCylindricalShared=Coordinates_Cartesian_To_Cylindrical(position)
    case default
       call Galacticus_Error_Report('unknown coordinate system type'//{introspection:location})
    end select
    ! Determine which mass type to use.
    if (present(massType)) then
       massTypeShared=massType
    else
       massTypeShared=massTypeAll
    end if
    ! Determine which component type to use.
    if (present(componentType)) then
       componentTypeShared=componentType
    else
       componentTypeShared=componentTypeAll
    end if
    ! Call routines to supply the densities for all components.
    componentSurfaceDensityFunction => Component_Surface_Density
    Galactic_Structure_Surface_Density=thisNode%mapDouble0(componentSurfaceDensityFunction,reductionSummation,optimizeFor=optimizeForSurfaceDensitySummation)
    return
  end function Galactic_Structure_Surface_Density

  double precision function Component_Surface_Density(component)
    !% Unary function returning the surface density in a component. Suitable for mapping over components.
    use :: Galacticus_Nodes, only : nodeComponent
    implicit none
    class(nodeComponent), intent(inout) :: component

    Component_Surface_Density=component%surfaceDensity(positionCylindricalShared,componentTypeShared&
         &,massTypeShared,weightByShared,weightIndexShared)
    return
  end function Component_Surface_Density

end module Galactic_Structure_Surface_Densities
