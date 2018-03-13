!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

!% Contains a module which implements a log-normal halo environment.

  use Cosmology_Parameters
  use Cosmology_Functions
  use Linear_Growth

  !# <haloEnvironment name="haloEnvironmentLogNormal">
  !#  <description>Implements a log-normal halo environment.</description>
  !# </haloEnvironment>
  type, extends(haloEnvironmentClass) :: haloEnvironmentLogNormal
     !% A logNormal halo environment class.
     private
     class           (cosmologyParametersClass     ), pointer :: cosmologyParameters_
     class           (cosmologyFunctionsClass      ), pointer :: cosmologyFunctions_
     class           (cosmologicalMassVarianceClass), pointer :: cosmologicalMassVariance_
     class           (linearGrowthClass            ), pointer :: linearGrowth_
     class           (criticalOverdensityClass     ), pointer :: criticalOverdensity_
     double precision                                         :: radiusEnvironment        , variance
   contains
     final     ::                         logNormalDestructor
     procedure :: overdensityLinear    => logNormalOverdensityLinear
     procedure :: overdensityNonLinear => logNormalOverdensityNonLinear
     procedure :: environmentRadius    => logNormalEnvironmentRadius
     procedure :: environmentMass      => logNormalEnvironmentMass
  end type haloEnvironmentLogNormal

  interface haloEnvironmentLogNormal
     !% Constructors for the {\normalfont \ttfamily logNormal} halo environment class.
     module procedure logNormalConstructorParameters
     module procedure logNormalConstructorInternal
  end interface haloEnvironmentLogNormal

contains
  
  function logNormalConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily logNormal} halo environment class which takes a parameter set as input.
    use Input_Parameters
    implicit none
    type            (haloEnvironmentLogNormal     )                :: self
    type            (inputParameters              ), intent(inout) :: parameters
    class           (cosmologyParametersClass     ), pointer       :: cosmologyParameters_
    class           (cosmologyFunctionsClass      ), pointer       :: cosmologyFunctions_
    class           (cosmologicalMassVarianceClass), pointer       :: cosmologicalMassVariance_
    class           (linearGrowthClass            ), pointer       :: linearGrowth_
    class           (criticalOverdensityClass     ), pointer       :: criticalOverdensity_
    double precision                                               :: radiusEnvironment

    !# <objectBuilder class="cosmologyParameters"      name="cosmologyParameters_"      source="parameters"/>
    !# <objectBuilder class="cosmologyFunctions"       name="cosmologyFunctions_"       source="parameters"/>
    !# <objectBuilder class="cosmologicalMassVariance" name="cosmologicalMassVariance_" source="parameters"/>
    !# <objectBuilder class="linearGrowth"             name="linearGrowth_"             source="parameters"/>
    !# <objectBuilder class="criticalOverdensity"      name="criticalOverdensity_"      source="parameters"/>
    !# <inputParameter>
    !#   <name>radiusEnvironment</name>
    !#   <source>parameters</source>
    !#   <variable>radiusEnvironment</variable>
    !#   <defaultValue>7.0d0</defaultValue>
    !#   <description>The radius of the sphere used to determine the variance in the environmental density.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    self=haloEnvironmentLogNormal(radiusEnvironment,cosmologyParameters_,cosmologyFunctions_,cosmologicalMassVariance_,linearGrowth_,criticalOverdensity_)
    !# <inputParametersValidate source="parameters"/>
    return
  end function logNormalConstructorParameters

  function logNormalConstructorInternal(radiusEnvironment,cosmologyParameters_,cosmologyFunctions_,cosmologicalMassVariance_,linearGrowth_,criticalOverdensity_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily logNormal} halo mass function class.
    use Numerical_Constants_Math
    implicit none
    type            (haloEnvironmentLogNormal     )                        :: self
    class           (cosmologyParametersClass     ), target, intent(in   ) :: cosmologyParameters_
    class           (cosmologyFunctionsClass      ), target, intent(in   ) :: cosmologyFunctions_
    class           (cosmologicalMassVarianceClass), target, intent(in   ) :: cosmologicalMassVariance_
    class           (linearGrowthClass            ), target, intent(in   ) :: linearGrowth_
    class           (criticalOverdensityClass     ), target, intent(in   ) :: criticalOverdensity_
    double precision                                       , intent(in   ) :: radiusEnvironment
    !# <constructorAssign variables="radiusEnvironment, *cosmologyParameters_, *cosmologyFunctions_, *cosmologicalMassVariance_, *linearGrowth_, *criticalOverdensity_" />

    self%variance=self%cosmologicalMassVariance_%rootVariance(                                                  &
         &                                                    +4.0d0                                            &
         &                                                    /3.0d0                                            &
         &                                                    *Pi                                               &
         &                                                    *self%cosmologyParameters_%OmegaMatter      ()    &
         &                                                    *self%cosmologyParameters_%densityCritical  ()    &
         &                                                    *self                     %radiusEnvironment  **3 &
         &                                                   )                                              **2
    return
  end function logNormalConstructorInternal

  subroutine logNormalDestructor(self)
    !% Destructor for the {\normalfont \ttfamily logNormal} halo mass function class.
    implicit none
    type(haloEnvironmentLogNormal), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyParameters_"      />
    !# <objectDestructor name="self%cosmologicalMassVariance_" />
    !# <objectDestructor name="self%linearGrowth_"             />
    return
  end subroutine logNormalDestructor

  double precision function logNormalOverdensityLinear(self,node,presentDay)
    !% Return the environment of the given {\normalfont \ttfamily node}.
    use Kind_Numbers
    use Statistics_Distributions
    implicit none
    class           (haloEnvironmentLogNormal), intent(inout)           :: self
    type            (treeNode                ), intent(inout)           :: node
    logical                                   , intent(in   ), optional :: presentDay
    type            (treeNode                ), pointer                 :: nodeRoot
    class           (nodeComponentBasic      ), pointer                 :: basic
    integer         (kind_int8               ), save                    :: uniqueIDPrevious           =-1_kind_int8
    double precision                          , save                    :: overdensityPrevious
    !$omp threadprivate(uniqueIDPrevious,overdensityPrevious)
    double precision                          , parameter               :: densityContrastMean        =1.0d0
    double precision                                                    :: densityContrastVariance
    type            (distributionLogNormal   )                          :: distributionDensityContrast
    !# <optionalArgument name="presentDay" defaultsTo=".false." />

    if (node%hostTree%baseNode%uniqueID() /= uniqueIDPrevious) then
       uniqueIDPrevious=node%hostTree%baseNode%uniqueID()
       if (node%hostTree%properties%exists('haloEnvironmentOverdensity')) then
          overdensityPrevious=node%hostTree%properties%value('haloEnvironmentOverdensity')
       else
          ! Find the root node of the tree.
          nodeRoot                    =>  node%hostTree     %baseNode
          ! Find variance for the root node.
          densityContrastVariance     =  +self%variance                                         &
               &                         *self%linearGrowth_%value   (expansionFactor=1.0d0)**2
          ! Construct a log-normal distribution, for 1+δ.
          distributionDensityContrast =   distributionLogNormal             (                                                                               &
               &                                                                                   +densityContrastMean                                   , &
               &                                                                                   +densityContrastVariance                               , &
               &                                                             limitUpper           =+1.0d0                                                   &
               &                                                                                   +self%criticalOverdensity_%value(expansionFactor=1.0d0)  &
               &                                                            )
          ! Choose an overdensity.
          overdensityPrevious         =  +distributionDensityContrast%sample(                                                                               &
               &                                                             randomNumberGenerator= node%hostTree%randomNumberGenerator                     &
               &                                                            )                                                                               &
               &                         -1.0d0
          call node%hostTree%properties%set('haloEnvironmentOverdensity',overdensityPrevious)
       end if
    end if
    logNormalOverdensityLinear=overdensityPrevious
    if (.not.presentDay_) then
      basic                      =>  node                                    %basic(                 )
      logNormalOverdensityLinear =  +logNormalOverdensityLinear                                        &
           &                        *self                      %linearGrowth_%value(time=basic%time())
    end if
    return
  end function logNormalOverdensityLinear

  double precision function logNormalOverdensityNonLinear(self,node)
    !% Return the environment of the given {\normalfont \ttfamily node}.
    use Galacticus_Error
    implicit none
    class(haloEnvironmentLogNormal), intent(inout) :: self
    type (treeNode                ), intent(inout) :: node

    ! In this model the nonlinear and linear density fields are identified.
    logNormalOverdensityNonLinear=self%overdensityLinear(node)
    return
  end function logNormalOverdensityNonLinear

  double precision function logNormalEnvironmentRadius(self)
    !% Return the radius of the environment.
    implicit none
    class(haloEnvironmentLogNormal), intent(inout) :: self

    logNormalEnvironmentRadius=self%radiusEnvironment
    return
  end function logNormalEnvironmentRadius

  double precision function logNormalEnvironmentMass(self)
    !% Return the mass of the environment.
    use Numerical_Constants_Math
    implicit none
    class(haloEnvironmentLogNormal), intent(inout) :: self

    logNormalEnvironmentMass=+4.0d0                                                                   &
         &                   *Pi                                                                      &
         &                   *self%radiusEnvironment                                              **3 &
         &                   *self%cosmologyFunctions_%matterDensityEpochal(expansionFactor=1.0d0)    &
         &                   /3.0d0
    return
  end function logNormalEnvironmentMass
