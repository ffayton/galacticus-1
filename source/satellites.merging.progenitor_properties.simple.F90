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

  !% Implements a merger progenitor properties class which uses a simple calculation.

  use :: Satellite_Merging_Mass_Movements, only : mergerMassMovementsClass

  !# <mergerProgenitorProperties name="mergerProgenitorPropertiesSimple">
  !#  <description>A merger progenitor properties class which uses a simple calculation.</description>
  !# </mergerProgenitorProperties>
  type, extends(mergerProgenitorPropertiesClass) :: mergerProgenitorPropertiesSimple
     !% A merger progenitor properties class which uses a simple calculation.
     private
     class(mergerMassMovementsClass), pointer :: mergerMassMovements_ => null()
   contains
     final     ::        simpleDestructor
     procedure :: get => simpleGet
  end type mergerProgenitorPropertiesSimple

  interface mergerProgenitorPropertiesSimple
     !% Constructors for the {\normalfont \ttfamily simple} merger progenitor properties class.
     module procedure simpleConstructorParameters
     module procedure simpleConstructorInternal
  end interface mergerProgenitorPropertiesSimple

contains

  function simpleConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily simple} merger progenitor properties class which takes a parameter list as input.
    use :: Array_Utilities , only : operator(.intersection.)
    use :: Galacticus_Error, only : Galacticus_Component_List, Galacticus_Error_Report
    use :: Galacticus_Nodes, only : defaultDiskComponent     , defaultSpheroidComponent
    use :: Input_Parameters, only : inputParameter           , inputParameters
    implicit none
    type (mergerProgenitorPropertiesSimple)                :: self
    type (inputParameters                 ), intent(inout) :: parameters
    class(mergerMassMovementsClass        ), pointer       :: mergerMassMovements_

    ! Ensure that required methods are supported.
    if     (                                                                                                                                          &
         &  .not.                                                                                                                                     &
         &       (                                                                                                                                    &
         &        defaultDiskComponent    %    massStellarIsGettable().and.                                                                           &
         &        defaultDiskComponent    %        massGasIsGettable().and.                                                                           &
         &        defaultDiskComponent    % halfMassRadiusIsGettable()                                                                                &
         &  )                                                                                                                                         &
         & ) call Galacticus_Error_Report                                                                                                             &
         &        (                                                                                                                                   &
         &         'this method requires that massStellar, massGas, and halfMassRadius properties must all be gettable for the disk component.'    // &
         &         Galacticus_Component_List(                                                                                                         &
         &                                   'disk'                                                                                                ,  &
         &                                   defaultDiskComponent    %    massStellarAttributeMatch(requireGettable=.true.).intersection.             &
         &                                   defaultDiskComponent    %        massGasAttributeMatch(requireGettable=.true.).intersection.             &
         &                                   defaultDiskComponent    % halfMassRadiusAttributeMatch(requireGettable=.true.)                           &
         &                                  )                                                                                                      // &
         &         {introspection:location}                                                                                                           &
         &        )
    if     (                                                                                                                                          &
         &  .not.                                                                                                                                     &
         &       (                                                                                                                                    &
         &        defaultSpheroidComponent%    massStellarIsGettable().and.                                                                           &
         &        defaultSpheroidComponent%        massGasIsGettable().and.                                                                           &
         &        defaultSpheroidComponent% halfMassRadiusIsGettable()                                                                                &
         &  )                                                                                                                                         &
         & ) call Galacticus_Error_Report                                                                                                             &
         &        (                                                                                                                                   &
         &         'this method requires that massStellar, massGas, and halfMassRadius properties must all be gettable for the spheroid component.'// &
         &         Galacticus_Component_List(                                                                                                         &
         &                                   'spheroid'                                                                                            ,  &
         &                                   defaultSpheroidComponent%    massStellarAttributeMatch(requireGettable=.true.).intersection.             &
         &                                   defaultSpheroidComponent%        massGasAttributeMatch(requireGettable=.true.).intersection.             &
         &                                   defaultSpheroidComponent% halfMassRadiusAttributeMatch(requireGettable=.true.)                           &
         &                                  )                                                                                                      // &
         &         {introspection:location}                                                                                                           &
         &        )
    !# <objectBuilder class="mergerMassMovements" name="mergerMassMovements_" source="parameters"/>
    self=mergerProgenitorPropertiesSimple(mergerMassMovements_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="mergerMassMovements_"/>
    return
  end function simpleConstructorParameters

 function simpleConstructorInternal(mergerMassMovements_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily simple} merger progenitor properties class.
    implicit none
    type (mergerProgenitorPropertiesSimple)                        :: self
    class(mergerMassMovementsClass        ), intent(in   ), target :: mergerMassMovements_
    !# <constructorAssign variables="*mergerMassMovements_"/>

    return
  end function simpleConstructorInternal

  subroutine simpleDestructor(self)
    !% Destructor for the {\normalfont \ttfamily simple} merger progenitor properties class.
    implicit none
    type(mergerProgenitorPropertiesSimple), intent(inout) :: self

    !# <objectDestructor name="self%mergerMassMovements_"/>
    return
  end subroutine simpleDestructor

  subroutine simpleGet(self,nodeSatellite,nodeHost,massSatellite,massHost,massSpheroidSatellite,massSpheroidHost,massSpheroidHostPreMerger,radiusSatellite,radiusHost,factorAngularMomentum,massSpheroidRemnant,massGasSpheroidRemnant)
    !% Computes various properties of the progenitor galaxies useful for calculations of merger remnant sizes.
    use :: Galactic_Structure_Enclosed_Masses, only : Galactic_Structure_Enclosed_Mass
    use :: Galactic_Structure_Options        , only : massTypeGalactic
    use :: Galacticus_Error                  , only : Galacticus_Error_Report
    use :: Galacticus_Nodes                  , only : nodeComponentDisk               , nodeComponentSpheroid    , treeNode
    use :: Satellite_Merging_Mass_Movements  , only : destinationMergerDisk           , destinationMergerSpheroid, destinationMergerUnmoved
    implicit none
    class           (mergerProgenitorPropertiesSimple), intent(inout)         :: self
    type            (treeNode                        ), intent(inout), target :: nodeSatellite            , nodeHost
    double precision                                  , intent(  out)         :: factorAngularMomentum    , massHost                 , &
         &                                                                       radiusHost               , massSpheroidHost         , &
         &                                                                       massSpheroidHostPreMerger, massGasSpheroidRemnant   , &
         &                                                                       massSpheroidRemnant      , massSatellite            , &
         &                                                                       radiusSatellite          , massSpheroidSatellite
    class           (nodeComponentDisk               ), pointer               :: diskHost                 , diskSatelite
    class           (nodeComponentSpheroid           ), pointer               :: spheroidHost             , spheroidSatellite
    integer                                                                   :: destinationGasSatellite  , destinationGasHost       , &
         &                                                                       destinationStarsHost     , destinationStarsSatellite
    logical                                                                   :: mergerIsMajor

    ! Find how mass is moved by the merger.
    call self%mergerMassMovements_%get(nodeSatellite,destinationGasSatellite,destinationStarsSatellite,destinationGasHost,destinationStarsHost,mergerIsMajor)
    ! Get the disk and spheroid components of host and satellite.
    diskHost          => nodeHost     %disk    ()
    spheroidHost      => nodeHost     %spheroid()
    diskSatelite      => nodeSatellite%disk    ()
    spheroidSatellite => nodeSatellite%spheroid()
    ! Find the baryonic masses of the two galaxies.
    massSatellite=Galactic_Structure_Enclosed_Mass(nodeSatellite,massType=massTypeGalactic)
    massHost     =Galactic_Structure_Enclosed_Mass(nodeHost     ,massType=massTypeGalactic)
    ! Find the masses of material that will end up in the spheroid component of the remnant.
    select case (destinationGasHost)
    case (destinationMergerSpheroid)
       massSpheroidHost      =+spheroidHost%massGas()+diskHost    %massGas       ()
       massGasSpheroidRemnant=+spheroidHost%massGas()+diskHost    %massGas       ()
       massSpheroidRemnant   =+spheroidHost%massGas()+diskHost    %massGas       ()
       radiusHost            =+spheroidHost%massGas()*spheroidHost%halfMassRadius() &
            &                 +diskHost    %massGas()*diskHost    %halfMassRadius()
    case (destinationMergerDisk)
       massSpheroidHost      =+0.0d0
       massGasSpheroidRemnant=+0.0d0
       massSpheroidRemnant   =+0.0d0
    case (destinationMergerUnmoved)
       massSpheroidHost      =+spheroidHost%massGas()
       massGasSpheroidRemnant=+spheroidHost%massGas()
       massSpheroidRemnant   =+spheroidHost%massGas()
       radiusHost            =+spheroidHost%massGas()*spheroidHost%halfMassRadius()
    case default
       call Galacticus_Error_Report('unrecognized moveTo descriptor'//{introspection:location})
    end select
    select case (destinationStarsHost)
    case (destinationMergerSpheroid)
       massSpheroidHost     =+massSpheroidHost       +spheroidHost%massStellar()+    diskHost%massStellar   ()
       massSpheroidRemnant  =+massSpheroidRemnant    +spheroidHost%massStellar()+    diskHost%massStellar   ()
       radiusHost           =+radiusHost             +spheroidHost%massStellar()*spheroidHost%halfMassRadius() &
            &                                        +    diskHost%massStellar()*    diskHost%halfMassRadius()
    case (destinationMergerDisk)
       massSpheroidHost     =+massSpheroidHost
    case (destinationMergerUnmoved)
       massSpheroidHost     =+massSpheroidHost       +spheroidHost%massStellar()
       massSpheroidRemnant  =+massSpheroidRemnant    +spheroidHost%massStellar()
       radiusHost           =+radiusHost             +spheroidHost%massStellar()*spheroidHost%halfMassRadius()
    case default
       call Galacticus_Error_Report('unrecognized moveTo descriptor'//{introspection:location})
    end select
    select case (destinationGasSatellite)
    case (destinationMergerSpheroid)
       massSpheroidSatellite =                       +spheroidSatellite%massGas()+     diskSatelite%massGas       ()
       massGasSpheroidRemnant=+massGasSpheroidRemnant+spheroidSatellite%massGas()+     diskSatelite%massGas       ()
       massSpheroidRemnant   =+massSpheroidRemnant   +spheroidSatellite%massGas()+     diskSatelite%massGas       ()
       radiusSatellite       =                       +spheroidSatellite%massGas()*spheroidSatellite%halfMassRadius() &
            &                                        +     diskSatelite%massGas()*     diskSatelite%halfMassRadius()
    case (destinationMergerDisk)
       massSpheroidSatellite =+0.0d0
    case (destinationMergerUnmoved)
       massSpheroidSatellite =                       +spheroidSatellite%massGas()
       massGasSpheroidRemnant=+massGasSpheroidRemnant+spheroidSatellite%massGas()
       massSpheroidRemnant   =+massSpheroidRemnant   +spheroidSatellite%massGas()
       radiusSatellite       =                       +spheroidSatellite%massGas()*spheroidSatellite%halfMassRadius()
    case default
       call Galacticus_Error_Report('unrecognized moveTo descriptor'//{introspection:location})
    end select
    select case (destinationStarsSatellite)
    case (destinationMergerSpheroid)
       massSpheroidSatellite=+massSpheroidSatellite+spheroidSatellite%massStellar()+     diskSatelite%massStellar   ()
       massSpheroidRemnant  =+massSpheroidRemnant  +spheroidSatellite%massStellar()+     diskSatelite%massStellar   ()
       radiusSatellite      =+radiusSatellite      +spheroidSatellite%massStellar()*spheroidSatellite%halfMassRadius() &
            &                                      +     diskSatelite%massStellar()*     diskSatelite%halfMassRadius()
    case (destinationMergerDisk)
       massSpheroidSatellite=+massSpheroidSatellite
    case (destinationMergerUnmoved)
       massSpheroidSatellite=+massSpheroidSatellite+spheroidSatellite%massStellar()
       massSpheroidRemnant  =+massSpheroidRemnant  +spheroidSatellite%massStellar()
       radiusSatellite      =+radiusSatellite      +spheroidSatellite%massStellar()*spheroidSatellite%halfMassRadius()
    case default
       call Galacticus_Error_Report('unrecognized moveTo descriptor'//{introspection:location})
    end select
    ! Compute the half-mass radii of the material that will end up in the remnant spheroid.
    if (massSpheroidHost      > 0.0d0) radiusHost     =radiusHost     /massSpheroidHost
    if (massSpheroidSatellite > 0.0d0) radiusSatellite=radiusSatellite/massSpheroidSatellite
    ! Compute the angular momentum factor.
    factorAngularMomentum=1.0d0
    ! Compute the mass of the host spheroid before the merger.
    massSpheroidHostPreMerger=spheroidHost%massStellar()+spheroidHost%massGas()
    return
  end subroutine simpleGet
