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

!% Contains a module which implements a dark matter halo mass function class which averages another (presumably
!% environment-dependent) mass function over environment.

  use :: Cosmological_Density_Field, only : haloEnvironmentClass

  !# <haloMassFunction name="haloMassFunctionEnvironmentAveraged">
  !#  <description>
  !#   The halo mass function is computed averaging another (presumably environment-dependent) mass function over environment.
  !#  </description>
  !# </haloMassFunction>
  type, extends(haloMassFunctionClass) :: haloMassFunctionEnvironmentAveraged
     !% A halo mass function class which averages another (presumably environment-dependent) mass function over environment.
     private
     class           (haloMassFunctionClass), pointer :: haloMassFunctionConditioned_ => null(), haloMassFunctionUnconditioned_ => null()
     class           (haloEnvironmentClass ), pointer :: haloEnvironment_             => null()
     double precision                                 :: factorMatching                        , timeMatching
   contains
     final     ::                 environmentAveragedDestructor
     procedure :: differential => environmentAveragedDifferential
  end type haloMassFunctionEnvironmentAveraged

  interface haloMassFunctionEnvironmentAveraged
     !% Constructors for the {\normalfont \ttfamily environmentAveraged} halo mass function class.
     module procedure environmentAveragedConstructorParameters
     module procedure environmentAveragedConstructorInternal
  end interface haloMassFunctionEnvironmentAveraged

contains

  function environmentAveragedConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily environmentAveraged} halo mass function class which takes a parameter set as
    !% input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type (haloMassFunctionEnvironmentAveraged)                :: self
    type (inputParameters                    ), intent(inout) :: parameters
    class(haloMassFunctionClass              ), pointer       :: haloMassFunctionConditioned_, haloMassFunctionUnconditioned_
    class(haloEnvironmentClass               ), pointer       :: haloEnvironment_
    class(cosmologyParametersClass           ), pointer       :: cosmologyParameters_

    !# <objectBuilder class="haloMassFunction"    name="haloMassFunctionConditioned_"   source="parameters" parameterName="haloMassFunctionConditioned"  />
    !# <objectBuilder class="haloMassFunction"    name="haloMassFunctionUnconditioned_" source="parameters" parameterName="haloMassFunctionUnconditioned"/>
    !# <objectBuilder class="haloEnvironment"     name="haloEnvironment_"               source="parameters"                                              />
    !# <objectBuilder class="cosmologyParameters" name="cosmologyParameters_"           source="parameters"                                              />
    self=haloMassFunctionEnvironmentAveraged(haloMassFunctionConditioned_,haloMassFunctionUnconditioned_,haloEnvironment_,cosmologyParameters_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="haloMassFunctionConditioned_"  />
    !# <objectDestructor name="haloMassFunctionUnconditioned_"/>
    !# <objectDestructor name="haloEnvironment_"              />
    !# <objectDestructor name="cosmologyParameters_"          />
    return
  end function environmentAveragedConstructorParameters

  function environmentAveragedConstructorInternal(haloMassFunctionConditioned_,haloMassFunctionUnconditioned_,haloEnvironment_,cosmologyParameters_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily environmentAveraged} halo mass function class.
    implicit none
    type (haloMassFunctionEnvironmentAveraged)                        :: self
    class(haloMassFunctionClass              ), target, intent(in   ) :: haloMassFunctionConditioned_,haloMassFunctionUnconditioned_
    class(haloEnvironmentClass               ), target, intent(in   ) :: haloEnvironment_
    class(cosmologyParametersClass           ), target, intent(in   ) :: cosmologyParameters_
    !# <constructorAssign variables="*haloMassFunctionConditioned_, *haloMassFunctionUnconditioned_, *haloEnvironment_, *cosmologyParameters_"/>

    self%timeMatching=-1.0d0
    return
  end function environmentAveragedConstructorInternal

  subroutine environmentAveragedDestructor(self)
    !% Destructor for the {\normalfont \ttfamily environmentAveraged} halo mass function class.
    implicit none
    type(haloMassFunctionEnvironmentAveraged), intent(inout) :: self

    !# <objectDestructor name="self%haloMassFunctionConditioned_"  />
    !# <objectDestructor name="self%haloMassFunctionUnconditioned_"/>
    !# <objectDestructor name="self%haloEnvironment_"              />
    !# <objectDestructor name="self%cosmologyParameters_"          />
    return
  end subroutine environmentAveragedDestructor

  recursive double precision function environmentAveragedDifferential(self,time,mass,node)
    !% Return the differential halo mass function at the given time and mass.
    use :: Galacticus_Nodes     , only : mergerTree         , nodeComponentBasic           , treeNode
    use :: Numerical_Integration, only : Integrate          , Integrate_Done
    use :: Root_Finder          , only : rangeExpandAdditive, rangeExpandSignExpectNegative, rangeExpandSignExpectPositive, rootFinder
    implicit none
    class           (haloMassFunctionEnvironmentAveraged), intent(inout)           :: self
    double precision                                     , intent(in   )           :: time                              , mass
    type            (treeNode                           ), intent(inout), optional :: node
    class           (nodeComponentBasic                 ), pointer                 :: basic
    double precision                                     , parameter               :: overdensityCDFFraction     =1.0d-6
    double precision                                     , parameter               :: rangeExpandStep            =1.0d-1
    double precision                                     , parameter               :: toleranceBackground        =1.0d-3
    type            (mergerTree                         ), target                  :: tree
    double precision                                                               :: environmentOverdensityLower       , environmentOverdensityUpper, &
         &                                                                            cdfTarget                         , massBackground
    type            (fgsl_function                      )                          :: integrandFunction
    type            (fgsl_integration_workspace         )                          :: integrationWorkspace
    type            (rootFinder                         )                          :: finder

    massBackground=self%haloEnvironment_%environmentMass()
    if (mass >= massBackground) then
       ! If the halo mass is equal to or greater than the mass of the environment, we simply use the unconditioned mass
       ! function. We include an empirical correction to ensure that the mass function transitions smoothly through the background
       ! mass.
       if (time /= self%timeMatching) then
          self%factorMatching=+self                               %differential(time,massBackground*(1.0d0-toleranceBackground),node) &
               &              /self%haloMassFunctionUnconditioned_%differential(time,massBackground*(1.0d0-toleranceBackground),node)
          self%timeMatching  =+                                                 time
       end if
       environmentAveragedDifferential=+self%haloMassFunctionUnconditioned_%differential(time,mass,node) &
            &                          *self%factorMatching
    else
       ! Halo mass is less than the mass of the environment - we must average the mass function over environment.
       ! Create a work node.
       call tree%properties%initialize()
       tree %baseNode          => treeNode               (                 )
       tree %baseNode%hostTree => tree
       basic                   => tree    %baseNode%basic(autoCreate=.true.)
       ! Set the properties of the work node.
       call basic%massSet(mass)
       call basic%timeSet(time)
       ! Find the range of overdensities over which to integrate.
       call finder%tolerance   (                                                                                     &
            &                   toleranceRelative            = 1.0d-6                                                &
            &                  )
       call finder%rangeExpand (                                                                                     &
            &                   rangeExpandUpward            =+rangeExpandStep                                     , &
            &                   rangeExpandDownward          =-rangeExpandStep                                     , &
            &                   rangeExpandUpwardSignExpect  =                      rangeExpandSignExpectPositive  , &
            &                   rangeExpandDownwardSignExpect=                      rangeExpandSignExpectNegative  , &
            &                   rangeUpwardLimit             =self%haloEnvironment_%overdensityLinearMaximum     (), &
            &                   rangeExpandType              =                      rangeExpandAdditive              &
            &                  )
       call finder%rootFunction(                                                                                     &
            &                                                                       environmentAveragedRoot          &
            &                  )
       cdfTarget                  =+0.0+overdensityCDFFraction
       environmentOverdensityLower=finder%find(rootGuess=0.0d0)
       cdfTarget                  =+1.0-overdensityCDFFraction
       environmentOverdensityUpper=finder%find(rootGuess=0.0d0)
       if (environmentAveragedIntegrand(environmentOverdensityLower) == 0.0d0) then
          do while (environmentAveragedIntegrand(environmentOverdensityLower) == 0.0d0 .and. environmentOverdensityLower < 0.0d0)
             environmentOverdensityLower=environmentOverdensityLower+rangeExpandStep
          end do
          environmentOverdensityLower=environmentOverdensityLower-rangeExpandStep
       end if
       ! Perform the averaging integral.
       environmentAveragedDifferential=Integrate(                                       &
            &                                    environmentOverdensityLower          , &
            &                                    environmentOverdensityUpper          , &
            &                                    environmentAveragedIntegrand         , &
            &                                    integrandFunction                    , &
            &                                    integrationWorkspace                 , &
            &                                    toleranceAbsolute           =1.0d-100, &
            &                                    toleranceRelative           =1.0d-009  &
            &                                   )
       call Integrate_Done(integrandFunction,integrationWorkspace)
       ! Clean up our work node.
       call tree%baseNode%destroy()
       deallocate(tree%baseNode)
    end if
    return

  contains

    double precision function environmentAveragedRoot(environmentOverdensity)
      !% Root function used in determining the range of overdensity over which to integrate.
      implicit none
      double precision, intent(in   ) :: environmentOverdensity

      environmentAveragedRoot=self%haloEnvironment_ %cdf(environmentOverdensity)-cdfTarget
      return
    end function environmentAveragedRoot

    double precision function environmentAveragedIntegrand(environmentOverdensity)
      !% Integrand function used in averging the dark matter halo mass function over environment.
      implicit none
      double precision, intent(in   ) :: environmentOverdensity

      call self%haloEnvironment_%overdensityLinearSet(node=tree%baseNode,overdensity=environmentOverdensity)
      environmentAveragedIntegrand=+self%haloMassFunctionConditioned_%differential(time                  ,mass,node=tree%baseNode) &
           &                       *self%haloEnvironment_            %pdf         (environmentOverdensity                        )
      return
    end function environmentAveragedIntegrand

  end function environmentAveragedDifferential
