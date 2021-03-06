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

  !% Implementation of a merger tree masses class which samples masses from a distribution.

  use :: Merger_Trees_Build_Masses_Distributions, only : mergerTreeBuildMassDistributionClass

  !# <mergerTreeBuildMasses name="mergerTreeBuildMassesSampledDistribution" abstract="yes">
  !#  <description>A merger tree masses class which samples masses from a distribution.</description>
  !# </mergerTreeBuildMasses>
  type, extends(mergerTreeBuildMassesClass) :: mergerTreeBuildMassesSampledDistribution
     !% Implementation of a merger tree masses class which samples masses from a distribution.
     private
     class           (mergerTreeBuildMassDistributionClass), pointer :: mergerTreeBuildMassDistribution_ => null()
     double precision                                                :: massTreeMinimum                 , massTreeMaximum, &
          &                                                             treesPerDecade
   contains
     !@ <objectMethods>
     !@   <object>mergerTreeBuildMassesSampledDistribution</object>
     !@   <objectMethod>
     !@     <method>constructor</method>
     !@     <arguments>\textcolor{red}{\textless type(inputParameters)\textgreater} parameters\arginout</arguments>
     !@     <type>\void</type>
     !@     <description>Handles construction of the abstract parent class.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>sampleCMF</method>
     !@     <arguments>\doubleone\ x\argout</arguments>
     !@     <type>\void</type>
     !@     <description>Return a set of values {\normalfont \ttfamily sampleCount} in the interval 0--1, corresponding to values of the cumulative mass distribution.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::              sampledDistributionDestructor
     procedure :: construct => sampledDistributionConstruct
     procedure :: sampleCMF => sampledDistributionCMF
  end type mergerTreeBuildMassesSampledDistribution

  interface mergerTreeBuildMassesSampledDistribution
     module procedure sampledDistributionConstructorParameters
  end interface mergerTreeBuildMassesSampledDistribution

contains

  function sampledDistributionConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily sampledDistribution} merger tree masses class which takes a parameter set as
    !% input.
    use :: Galacticus_Display, only : Galacticus_Display_Message, verbosityWarn
    use :: Galacticus_Error  , only : Galacticus_Error_Report
    use :: Input_Parameters  , only : inputParameter            , inputParameters
    implicit none
    type(mergerTreeBuildMassesSampledDistribution)                :: self
    type(inputParameters                         ), intent(inout) :: parameters

    !# <inputParameter>
    !#   <name>massTreeMinimum</name>
    !#   <variable>self%massTreeMinimum</variable>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>1.0d10</defaultValue>
    !#   <description>The minimum mass of merger tree base halos to consider when sampled masses from a distribution, in units of $M_\odot$.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massTreeMaximum</name>
    !#   <variable>self%massTreeMaximum</variable>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>1.0d15</defaultValue>
    !#   <description>The maximum mass of merger tree base halos to consider when sampled masses from a distribution, in units of $M_\odot$.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>treesPerDecade</name>
    !#   <variable>self%treesPerDecade</variable>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>10.0d0</defaultValue>
    !#   <description>The number of merger trees masses to sample per decade of base halo mass.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <objectBuilder class="mergerTreeBuildMassDistribution" name="self%mergerTreeBuildMassDistribution_" source="parameters"/>
    !# <inputParametersValidate target="self" source="parameters"/>
    ! Validate input.
    if (self%massTreeMaximum >= 1.0d16              )                                                           &
         & call Galacticus_Display_Message(                                                                     &
         &                                 '[massHaloMaximum] > 10¹⁶ - this seems very large and may lead '//   &
         &                                 'to failures in merger tree construction'                         ,  &
         &                                 verbosityWarn                                                        &
         &                                )
    if (self%massTreeMaximum <= self%massTreeMinimum)                                                           &
         & call Galacticus_Error_Report   (                                                                     &
         &                                 '[massHaloMaximum] > [massHaloMinimum] is required'             //   &
         &                                 {introspection:location}                                             &
         &                                )
    return
  end function sampledDistributionConstructorParameters

  subroutine sampledDistributionDestructor(self)
    !% Destructor for the {\normalfont \ttfamily sampledDistribution} merger tree masses class.
    implicit none
    type(mergerTreeBuildMassesSampledDistribution), intent(inout) :: self

    !# <objectDestructor name="self%mergerTreeBuildMassDistribution_"/>
    return
  end subroutine sampledDistributionDestructor

  subroutine sampledDistributionConstruct(self,time,mass,massMinimum,massMaximum,weight)
    !% Construct a set of merger tree masses by sampling from a distribution.
    use            :: FGSL                   , only : fgsl_function          , fgsl_integration_workspace, fgsl_interp, fgsl_interp_accel
    use            :: Galacticus_Error       , only : Galacticus_Error_Report
    use, intrinsic :: ISO_C_Binding          , only : c_size_t
    use            :: Memory_Management      , only : allocateArray          , deallocateArray
    use            :: Numerical_Integration  , only : Integrate              , Integrate_Done
    use            :: Numerical_Interpolation, only : Interpolate            , Interpolate_Done
    use            :: Numerical_Ranges       , only : Make_Range             , rangeTypeLinear
    use            :: Sort                   , only : Sort_Do
    use            :: Table_Labels           , only : extrapolationTypeFix
    implicit none
    class           (mergerTreeBuildMassesSampledDistribution), intent(inout)                            :: self
    double precision                                          , intent(in   )                            :: time
    double precision                                          , intent(  out), allocatable, dimension(:) :: mass                                 , weight                                   , &
         &                                                                                                  massMinimum                          , massMaximum
    double precision                                          , parameter                                :: toleranceAbsolute            =1.0d-12, toleranceRelative                 =1.0d-3
    integer                                                   , parameter                                :: massFunctionSamplePerDecade  =100
    double precision                                                         , allocatable, dimension(:) :: massFunctionSampleLogMass            , massFunctionSampleLogMassMonotonic       , &
         &                                                                                                  massFunctionSampleProbability
    integer         (c_size_t                                )                                           :: treeCount                            , iTree
    integer                                                                                              :: iSample                              , jSample                                  , &
         &                                                                                                  massFunctionSampleCount
    double precision                                                                                     :: probability                          , massFunctionSampleLogPrevious
    type            (fgsl_function                           )                                           :: integrandFunction
    type            (fgsl_integration_workspace              )                                           :: integrationWorkspace
    type            (fgsl_interp                             )                                           :: interpolationObject
    type            (fgsl_interp_accel                       )                                           :: interpolationAccelerator
    logical                                                                                              :: integrandReset                       , interpolationReset                       , &
         &                                                                                                  monotonize
    !GCC$ attributes unused :: weight

    ! Generate a randomly sampled set of halo masses.
    treeCount=max(2_c_size_t,int(log10(self%massTreeMaximum/self%massTreeMinimum)*self%treesPerDecade,kind=c_size_t))
    call allocateArray(mass       ,[treeCount])
    call allocateArray(massMinimum,[treeCount])
    call allocateArray(massMaximum,[treeCount])
    ! Create a cumulative probability for sampling halo masses.
    massFunctionSampleCount=max(2,int(log10(self%massTreeMaximum/self%massTreeMinimum)*massFunctionSamplePerDecade))
    call allocateArray(massFunctionSampleLogMass         ,[massFunctionSampleCount])
    call allocateArray(massFunctionSampleLogMassMonotonic,[massFunctionSampleCount])
    call allocateArray(massFunctionSampleProbability     ,[massFunctionSampleCount])
    massFunctionSampleLogMass    =Make_Range(log10(self%massTreeMinimum),log10(self%massTreeMaximum),massFunctionSampleCount,rangeType=rangeTypeLinear)
    massFunctionSampleLogPrevious=           log10(self%massTreeMinimum)
    jSample=0
    do iSample=1,massFunctionSampleCount
       if (massFunctionSampleLogMass(iSample) > massFunctionSampleLogPrevious) then
          integrandReset=.true.
          probability=Integrate(                                                          &
               &                                  massFunctionSampleLogPrevious         , &
               &                                  massFunctionSampleLogMass    (iSample), &
               &                                  distributionIntegrand                 , &
               &                                  integrandFunction                     , &
               &                                  integrationWorkspace                  , &
               &                toleranceAbsolute=toleranceAbsolute                     , &
               &                toleranceRelative=toleranceRelative                     , &
               &                reset            =integrandReset                          &
               &               )
          call Integrate_Done(integrandFunction,integrationWorkspace)
       else
          probability=0.0d0
       end if
       if (iSample == 1) then
          monotonize=.true.
       else if (jSample > 0) then
          monotonize= massFunctionSampleProbability(jSample)+probability &
               &     >                                                   &
               &      massFunctionSampleProbability(jSample)
       else
          monotonize=.false.
       end if
       if (monotonize) then
          jSample=jSample+1
          massFunctionSampleProbability     (jSample)=probability
          massFunctionSampleLogMassMonotonic(jSample)=massFunctionSampleLogMass(iSample)
          if (jSample > 1)                                                                        &
               & massFunctionSampleProbability(jSample)=+massFunctionSampleProbability(jSample  ) &
               &                                        +massFunctionSampleProbability(jSample-1)
       end if
       massFunctionSampleLogPrevious=massFunctionSampleLogMass(iSample)
    end do
    massFunctionSampleCount=jSample
    if (massFunctionSampleCount < 2) call Galacticus_Error_Report('tabulated mass function sampling density has fewer than 2 non-zero points'//{introspection:location})
    ! Normalize the cumulative probability distribution.
    massFunctionSampleProbability(1:massFunctionSampleCount)=+massFunctionSampleProbability(1:massFunctionSampleCount) &
         &                                                   /massFunctionSampleProbability(  massFunctionSampleCount)
    ! Generate a set of points in the cumulative distribution, sort them, and find the mass ranges which they occupy.
    call self%sampleCMF(mass)
    call Sort_Do(mass)
    do iTree=1,treeCount
        if (iTree == 1       ) then
          massMinimum(iTree)=+0.0d0
       else
          massMinimum(iTree)=+0.5d0*(mass(iTree)+mass(iTree-1))
       end if
       if (iTree == treeCount) then
          massMaximum(iTree)=+1.0d0
        else
          massMaximum(iTree)=+0.5d0*(mass(iTree)+mass(iTree+1))
       end if
    end do
    ! Compute the corresponding halo masses by interpolation in the cumulative probability distribution function.
    interpolationReset=.true.
    do iTree=1,treeCount
       mass       (iTree)=Interpolate(                                                                                 &
            &                                           massFunctionSampleProbability     (1:massFunctionSampleCount), &
            &                                           massFunctionSampleLogMassMonotonic(1:massFunctionSampleCount), &
            &                                           interpolationObject                                          , &
            &                                           interpolationAccelerator                                     , &
            &                                           mass                              (  iTree                  ), &
            &                         reset            =interpolationReset                                           , &
            &                         extrapolationType=extrapolationTypeFix                                           &
            &                        )
       massMinimum(iTree)=Interpolate(                                                                                 &
            &                                           massFunctionSampleProbability     (1:massFunctionSampleCount), &
            &                                           massFunctionSampleLogMassMonotonic(1:massFunctionSampleCount), &
            &                                           interpolationObject                                          , &
            &                                           interpolationAccelerator                                     , &
            &                                           massMinimum                       (  iTree                  ), &
            &                         reset            =interpolationReset                                           , &
            &                         extrapolationType=extrapolationTypeFix                                           &
            &                        )
       massMaximum(iTree)=Interpolate(                                                                                 &
            &                                           massFunctionSampleProbability     (1:massFunctionSampleCount), &
            &                                           massFunctionSampleLogMassMonotonic(1:massFunctionSampleCount), &
            &                                           interpolationObject                                          , &
            &                                           interpolationAccelerator                                     , &
            &                                           massMaximum                       (  iTree                  ), &
            &                         reset            =interpolationReset                                           , &
            &                         extrapolationType=extrapolationTypeFix                                           &
            &                        )
    end do
    mass       =10.0d0**mass
    massMinimum=10.0d0**massMinimum
    massMaximum=10.0d0**massMaximum
    call Interpolate_Done(interpolationObject,interpolationAccelerator,interpolationReset)
    call deallocateArray(massFunctionSampleLogMass         )
    call deallocateArray(massFunctionSampleProbability     )
    call deallocateArray(massFunctionSampleLogMassMonotonic)
    return

  contains

    double precision function distributionIntegrand(logMass)
      !% The integrand over the mass function sampling density function.
      implicit none
      double precision, intent(in   ) :: logMass

      distributionIntegrand=self%mergerTreeBuildMassDistribution_%sample(10.0d0**logMass,time,self%massTreeMinimum,self%massTreeMaximum)
      return
    end function distributionIntegrand

  end subroutine sampledDistributionConstruct

  subroutine sampledDistributionCMF(self,x)
    !% Stub function for cumulative mass function.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class           (mergerTreeBuildMassesSampledDistribution), intent(inout)               :: self
    double precision                                          , intent(  out), dimension(:) :: x
    !GCC$ attributes unused :: self, x

    call Galacticus_Error_Report('attempt to call function in abstract type'//{introspection:location})
    return
  end subroutine sampledDistributionCMF

