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

  !% Implementation of a 1D distibution function which is uniform in the logarithm of the variable.

  !# <distributionFunction1D name="distributionFunction1DLogUniform">
  !#  <description>A 1D distibution function which is uniform in the logarithm of the variable.</description>
  !# </distributionFunction1D>
  type, extends(distributionFunction1DClass) :: distributionFunction1DLogUniform
     !% Implementation of a 1D distibution function which is uniform in the logarithm of the variable.
     private
     double precision :: limitLower, limitUpper
   contains
     procedure :: density    => logUniformDensity
     procedure :: cumulative => logUniformCumulative
     procedure :: inverse    => logUniformInverse
  end type distributionFunction1DLogUniform

  interface distributionFunction1DLogUniform
     !% Constructors for the {\normalfont \ttfamily logUniform} 1D distribution function class.
     module procedure logUniformConstructorParameters
     module procedure logUniformConstructorInternal
  end interface distributionFunction1DLogUniform

contains

  function logUniformConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily logUniform} 1D distribution function class which builds
    !% the object from a parameter set.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (distributionFunction1DLogUniform)                :: self
    type            (inputParameters                 ), intent(inout) :: parameters
    class           (randomNumberGeneratorClass      ), pointer       :: randomNumberGenerator_
    double precision                                                  :: limitLower            , limitUpper

    !# <inputParameter>
    !#   <name>limitLower</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The lower limit of the log-uniform distribution function.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>limitUpper</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The upper limit of the log-uniform distribution function.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <objectBuilder class="randomNumberGenerator" name="randomNumberGenerator_" source="parameters"/>
    self=distributionFunction1DLogUniform(limitLower,limitUpper,randomNumberGenerator_)
    !# <objectDestructor name="randomNumberGenerator_"/>
    !# <inputParametersValidate source="parameters"/>
    return
  end function logUniformConstructorParameters

  function logUniformConstructorInternal(limitLower,limitUpper,randomNumberGenerator_) result(self)
    !% Constructor for ``logUniform'' 1D distribution function class.
    type            (distributionFunction1DLogUniform)                                  :: self
    double precision                                  , intent(in   )                   :: limitLower            , limitUpper
    class           (randomNumberGeneratorClass      ), intent(in   ), target, optional :: randomNumberGenerator_
    !# <constructorAssign variables="limitLower, limitUpper, *randomNumberGenerator_"/>

    return
  end function logUniformConstructorInternal

  double precision function logUniformDensity(self,x)
    !% Return the density of a uniform distribution.
    implicit none
    class           (distributionFunction1DLogUniform), intent(inout) :: self
    double precision                                  , intent(in   ) :: x

    if (x < self%limitLower .or. x > self%limitUpper) then
       logUniformDensity=0.0d0
    else
       logUniformDensity=1.0d0/x/(log(self%limitUpper)-log(self%limitLower))
    end if
    return
  end function logUniformDensity

  double precision function logUniformCumulative(self,x)
    !% Return the cumulative probability of a uniform distribution.
    implicit none
    class           (distributionFunction1DLogUniform), intent(inout) :: self
    double precision                                  , intent(in   ) :: x

    if      (x < self%limitLower) then
       logUniformCumulative=0.0d0
    else if (x > self%limitUpper) then
       logUniformCumulative=1.0d0
    else
       logUniformCumulative=(log(x)-log(self%limitLower))/(log(self%limitUpper)-log(self%limitLower))
    end if
    return
  end function logUniformCumulative

  double precision function logUniformInverse(self,p)
    !% Return the inverse of a uniform distribution.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class           (distributionFunction1DLogUniform), intent(inout), target :: self
    double precision                                  , intent(in   )         :: p

    if (p < 0.0d0 .or. p > 1.0d0)                                    &
         & call Galacticus_Error_Report(                             &
         &                              'probability out of range'// &
         &                              {introspection:location}     &
         &                             )
    logUniformInverse=exp(log(self%limitLower)+p*(log(self%limitUpper)-log(self%limitLower)))
    return
  end function logUniformInverse
