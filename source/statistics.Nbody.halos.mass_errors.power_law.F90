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

!% Contains a module which implements an N-body dark matter halo mass error class in which
!% errors are a power-law in halo mass.

  !# <nbodyHaloMassError name="nbodyHaloMassErrorPowerLaw">
  !#  <description>An N-body dark matter halo mass error class in which errors are a power-law in halo mass.</description>
  !# </nbodyHaloMassError>
  type, extends(nbodyHaloMassErrorClass) :: nbodyHaloMassErrorPowerLaw
     !% An N-body halo mass error class in which errors are a power-law in halo mass.
     private
     double precision :: normalizationSquared          , exponent, &
          &              fractionalErrorHighMassSquared
   contains
     procedure :: errorFractional => powerLawErrorFractional
     procedure :: correlation     => powerLawCorrelation
  end type nbodyHaloMassErrorPowerLaw

  interface nbodyHaloMassErrorPowerLaw
     !% Constructors for the {\normalfont \ttfamily powerLaw} N-body halo mass error class.
     module procedure nbodyHaloMassErrorPowerLawParameters
     module procedure nbodyHaloMassErrorPowerLawInternal
  end interface nbodyHaloMassErrorPowerLaw

  ! Reference mass used in the error model.
  double precision :: powerLawMassReference=1.0d12

contains

  function nbodyHaloMassErrorPowerLawParameters(parameters)
    !% Constructor for the {\normalfont \ttfamily powerLaw} N-body halo mass error class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (nbodyHaloMassErrorPowerLaw)                :: nbodyHaloMassErrorPowerLawParameters
    type            (inputParameters           ), intent(inout) :: parameters
    double precision                                            :: normalization                       , fractionalErrorHighMass

    ! Check and read parameters.
    !# <inputParameter>
    !#   <name>normalization</name>
    !#   <source>parameters</source>
    !#   <variable>normalization</variable>
    !#   <description>Parameter $\sigma_{12}$ appearing in model for random errors in the halo mass function.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>fractionalErrorHighMass</name>
    !#   <source>parameters</source>
    !#   <variable>fractionalErrorHighMass</variable>
    !#   <description>Parameter $\sigma_\infty$ appearing in model for random errors in the halo mass function.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>exponent</name>
    !#   <source>parameters</source>
    !#   <variable>nbodyHaloMassErrorPowerLawParameters%exponent</variable>
    !#   <description>
    !#    Parameter $\gamma$ appearing in model for random errors in the halo mass
    !#    function. Specifically, the fractional error is given by
    !#    \begin{equation}
    !#    \sigma(M) = \left[ \sigma^2_{12} \left({M_\mathrm{halo} \over 10^{12}M_\odot}\right)^{2\gamma} + \sigma^2_\infty \right]^{1/2},
    !#    \end{equation}
    !#    where $\sigma_{12}=${\normalfont \ttfamily [normalization]}, and $\gamma=${\normalfont
    !#    \ttfamily [exponent]}.
    !#   </description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    nbodyHaloMassErrorPowerLawParameters%normalizationSquared          =normalization          **2
    nbodyHaloMassErrorPowerLawParameters%fractionalErrorHighMassSquared=fractionalErrorHighMass**2
    !# <inputParametersValidate source="parameters"/>
    return
  end function nbodyHaloMassErrorPowerLawParameters

  function nbodyHaloMassErrorPowerLawInternal(normalization,exponent,fractionalErrorHighMass)
    !% Internal constructor for the {\normalfont \ttfamily powerLaw} N-body halo mass error class.
    implicit none
    type            (nbodyHaloMassErrorPowerLaw)                :: nbodyHaloMassErrorPowerLawInternal
    double precision                            , intent(in   ) :: normalization                     , exponent, &
         &                                                         fractionalErrorHighMass

    nbodyHaloMassErrorPowerLawInternal%normalizationSquared          =normalization          **2
    nbodyHaloMassErrorPowerLawInternal%exponent                      =exponent
    nbodyHaloMassErrorPowerLawInternal%fractionalErrorHighMassSquared=fractionalErrorHighMass**2
    return
  end function nbodyHaloMassErrorPowerLawInternal

  double precision function powerLawErrorFractional(self,node)
    !% Return the fractional error on the mass of an N-body halo in the power-law error model.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (nbodyHaloMassErrorPowerLaw), intent(inout) :: self
    type            (treeNode                  ), intent(inout) :: node
    class           (nodeComponentBasic        ), pointer       :: basic

    basic                   =>  node%basic        ()
    powerLawErrorFractional =   sqrt(                                     &
         &                           +self%normalizationSquared           &
         &                           *(                                   &
         &                             +basic%mass()                      &
         &                             /powerLawMassReference             &
         &                            )**(2.0d0*self%exponent)            &
         &                           +self%fractionalErrorHighMassSquared &
         &                          )
    return
  end function powerLawErrorFractional

  double precision function powerLawCorrelation(self,node1,node2)
    !% Return the correlation of the masses of a pair of N-body halos.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class(nbodyHaloMassErrorPowerLaw), intent(inout) :: self
    type (treeNode                  ), intent(inout) :: node1 , node2
    class(nodeComponentBasic        ), pointer       :: basic1, basic2
    !GCC$ attributes unused :: self

    basic1 => node1%basic()
    basic2 => node2%basic()
    if     (                                &
         &   basic1%mass() == basic2%mass() &
         &  .and.                           &
         &   basic1%time() == basic2%time() &
         & ) then
       powerLawCorrelation=1.0d0
    else
       powerLawCorrelation=0.0d0
    end if
    return
  end function powerLawCorrelation

