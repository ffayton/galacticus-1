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

  !% Implementation of the \cite{creasey_how_2012} outflow rate due to star formation feedback in galactic disks.

  use :: Star_Formation_Rate_Surface_Density_Disks, only : starFormationRateSurfaceDensityDisksClass

  !# <starFormationFeedbackDisks name="starFormationFeedbackDisksCreasey2012">
  !#  <description>The \cite{creasey_how_2012} outflow rate due to star formation feedback in galactic disks.</description>
  !# </starFormationFeedbackDisks>
  type, extends(starFormationFeedbackDisksClass) :: starFormationFeedbackDisksCreasey2012
     !% Implementation of the \cite{creasey_how_2012} outflow rate due to star formation feedback in galactic disks.
     private
    class           (starFormationRateSurfaceDensityDisksClass), pointer :: starFormationRateSurfaceDensityDisks_ => null()
     double precision                                                    :: nu                                   , mu, &
          &                                                                 beta0
   contains
     final     ::                creasey2012Destructor
     procedure :: outflowRate => creasey2012OutflowRate
  end type starFormationFeedbackDisksCreasey2012

  interface starFormationFeedbackDisksCreasey2012
     !% Constructors for the creasey2012 fraction star formation feedback in disks class.
     module procedure creasey2012ConstructorParameters
     module procedure creasey2012ConstructorInternal
  end interface starFormationFeedbackDisksCreasey2012

contains

  function creasey2012ConstructorParameters(parameters) result(self)
    !% Constructor for the \cite{creasey_how_2012} star formation feedback in disks class which takes a parameter set as input.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    type            (starFormationFeedbackDisksCreasey2012    )                :: self
    type            (inputParameters                          ), intent(inout) :: parameters
    class           (starFormationRateSurfaceDensityDisksClass), pointer       :: starFormationRateSurfaceDensityDisks_
    double precision                                                           :: mu                                   , nu, &
         &                                                                        beta0

    !# <inputParameter>
    !#   <name>mu</name>
    !#   <source>parameters</source>
    !#   <defaultValue>1.15d0</defaultValue>
    !#   <defaultSource>\citep{creasey_how_2012}</defaultSource>
    !#   <description>The parameter $\mu$ appearing in the \cite{creasey_how_2012} model for supernovae feedback.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>nu</name>
    !#   <source>parameters</source>
    !#   <defaultValue>0.16d0</defaultValue>
    !#   <defaultSource>\citep{creasey_how_2012}</defaultSource>
    !#   <description>The parameter $\nu$ appearing in the \cite{creasey_how_2012} model for supernovae feedback.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>beta0</name>
    !#   <source>parameters</source>
    !#   <defaultValue>13.0d0</defaultValue>
    !#   <defaultSource>\citep{creasey_how_2012}</defaultSource>
    !#   <description>The parameter $\beta_0$ appearing in the \cite{creasey_how_2012} model for supernovae feedback.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <objectBuilder class="starFormationRateSurfaceDensityDisks" name="starFormationRateSurfaceDensityDisks_" source="parameters"/>
    self=starFormationFeedbackDisksCreasey2012(mu,nu,beta0,starFormationRateSurfaceDensityDisks_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="starFormationRateSurfaceDensityDisks_"/>
    return
  end function creasey2012ConstructorParameters

  function creasey2012ConstructorInternal(mu,nu,beta0,starFormationRateSurfaceDensityDisks_) result(self)
    !% Internal constructor for the {\normalfont \ttfamily creasey2012} star formation feedback from disks class.
    implicit none
    type            (starFormationFeedbackDisksCreasey2012    )                        :: self
    class           (starFormationRateSurfaceDensityDisksClass), intent(in   ), target :: starFormationRateSurfaceDensityDisks_
    double precision                                           , intent(in   )         :: mu                                   , nu, &
         &                                                                                beta0
    !# <constructorAssign variables="mu, nu, beta0, *starFormationRateSurfaceDensityDisks_"/>

    return
  end function creasey2012ConstructorInternal

  subroutine creasey2012Destructor(self)
    !% Destructor for the {\normalfont \ttfamily creasey2012} feedback in disks class.
    implicit none
    type(starFormationFeedbackDisksCreasey2012), intent(inout) :: self

    !# <objectDestructor name="self%starFormationRateSurfaceDensityDisks_"/>
    return
  end subroutine creasey2012Destructor

  double precision function creasey2012OutflowRate(self,node,rateEnergyInput,rateStarFormation)
    !% Returns the outflow rate (in $M_\odot$ Gyr$^{-1}$) for star formation in the galactic disk of {\normalfont \ttfamily thisNode} using
    !% the model of \cite{creasey_how_2012}. The outflow rate is given by
    !% \begin{equation}
    !% \dot{M}_\mathrm{outflow} = \int_0^\infty \beta_0 \Sigma_{g,1}^{-\mu}(r) f_\mathrm{g}^\nu(r) \dot{\Sigma}_\star(r) 2 \pi r \mathrm{d}r,
    !% \end{equation}
    !% where $\Sigma_{g,1}(r)$ is the surface density of gas in units of $M_\odot$ pc$^{-2}$, $f_\mathrm{g}(r)$ is the gas
    !% fraction, $\dot{\Sigma}_\star(r)$ is the surface density of star formation rate, $\beta_0=${\normalfont \ttfamily [beta0]},
    !% $\mu=${\normalfont \ttfamily [mu]}, and $\nu=${\normalfont \ttfamily [nu]}.
    use :: FGSL                    , only : fgsl_function                         , fgsl_integration_workspace
    use :: Galacticus_Nodes        , only : nodeComponentDisk                     , treeNode
    use :: Numerical_Constants_Math, only : Pi
    use :: Numerical_Integration   , only : Integrate                             , Integrate_Done
    use :: Stellar_Feedback        , only : feedbackEnergyInputAtInfinityCanonical
    implicit none
    class           (starFormationFeedbackDisksCreasey2012), intent(inout) :: self
    type            (treeNode                             ), intent(inout) :: node
    double precision                                       , intent(in   ) :: rateEnergyInput               , rateStarFormation
    double precision                                       , parameter     :: radiusInnerDimensionless=0.0d0, radiusOuterDimensionless=10.0d0
    class           (nodeComponentDisk                    ), pointer       :: disk
    double precision                                                       :: radiusScale                   , massGas                        , &
         &                                                                    radiusInner                   , radiusOuter                    , &
         &                                                                    massStellar
    type            (fgsl_function                        )                :: integrandFunction
    type            (fgsl_integration_workspace           )                :: integrationWorkspace

    ! Get the disk properties.
    disk        => node%disk       ()
    massGas     =  disk%massGas    ()
    massStellar =  disk%massStellar()
    radiusScale =  disk%radius     ()
    ! Return immediately for a null disk.
    if (massGas <= 0.0d0 .or. massStellar <= 0.0d0 .or. radiusScale <= 0.0d0) then
       creasey2012OutflowRate=0.0d0
       return
    end if
    ! Compute suitable limits for the integration.
    radiusInner=radiusScale*radiusInnerDimensionless
    radiusOuter=radiusScale*radiusOuterDimensionless
    ! Compute the outflow rate.
    creasey2012OutflowRate=+2.0d0&
         &                *Pi                                     &
         &                *self%beta0                             &
         &                *Integrate(                             &
         &                           radiusInner                , &
         &                           radiusOuter                , &
         &                           outflowRateIntegrand       , &
         &                           integrandFunction          , &
         &                           integrationWorkspace       , &
         &                           toleranceAbsolute   =0.0d+0, &
         &                           toleranceRelative   =1.0d-3  &
         &                          )                             &
         &                /rateStarFormation                      &
         &                *rateEnergyInput                        &
         &                /feedbackEnergyInputAtInfinityCanonical
    call Integrate_Done(integrandFunction,integrationWorkspace)
    return

  contains

    double precision function outflowRateIntegrand(radius)
      !% Integrand function for the ``Creasey et al. (2012)'' supernovae feedback calculation.
      use :: Galactic_Structure_Options          , only : componentTypeDisk                 , coordinateSystemCylindrical, massTypeGaseous, massTypeStellar
      use :: Galactic_Structure_Surface_Densities, only : Galactic_Structure_Surface_Density
      use :: Numerical_Constants_Prefixes        , only : mega
      implicit none
      double precision, intent(in   ) :: radius
      double precision                :: fractionGas      , densitySurfaceRateStarFormation, &
           &                             densitySurfaceGas, densitySurfaceStellar

      ! Get gas surface density.
      densitySurfaceGas    =Galactic_Structure_Surface_Density(                                                            &
           &                                                                     node                                    , &
           &                                                                    [radius                     ,0.0d0,0.0d0], &
           &                                                   coordinateSystem= coordinateSystemCylindrical             , &
           &                                                   componentType   = componentTypeDisk                       , &
           &                                                   massType        = massTypeGaseous                           &
           &                                                  )
      ! Get stellar surface density.
      densitySurfaceStellar=Galactic_Structure_Surface_Density(                                                            &
           &                                                                     node                                    , &
           &                                                                    [radius                     ,0.0d0,0.0d0], &
           &                                                   coordinateSystem= coordinateSystemCylindrical             , &
           &                                                   componentType   = componentTypeDisk                       , &
           &                                                   massType        = massTypeStellar                           &
           &                                                  )
      ! Compute the gas fraction.
      fractionGas=+  densitySurfaceGas     &
           &      /(                       &
           &        +densitySurfaceGas     &
           &        +densitySurfaceStellar &
           &       )
      ! Convert gas surface density to units of M☉ pc⁻².
      densitySurfaceGas=+densitySurfaceGas &
           &            /mega**2
      ! Get the surface density of star formation rate.
      densitySurfaceRateStarFormation=self%starFormationRateSurfaceDensityDisks_%rate(node,radius)
      ! Compute the outflow rate.
      outflowRateIntegrand=+densitySurfaceGas              **(-self%mu) &
           &               *fractionGas                    **  self%nu  &
           &               *densitySurfaceRateStarFormation             &
           &               *radius
      return
    end function outflowRateIntegrand

  end function creasey2012OutflowRate

