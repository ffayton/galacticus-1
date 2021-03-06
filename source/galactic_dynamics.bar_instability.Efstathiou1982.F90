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

  !% Implementation of the \cite{efstathiou_stability_1982} model for galactic disk bar instability.

  !# <galacticDynamicsBarInstability name="galacticDynamicsBarInstabilityEfstathiou1982">
  !#  <description>The \cite{efstathiou_stability_1982} model for galactic disk bar instability.</description>
  !# </galacticDynamicsBarInstability>
  type, extends(galacticDynamicsBarInstabilityClass) :: galacticDynamicsBarInstabilityEfstathiou1982
     !% Implementation of the \cite{efstathiou_stability_1982} model for galactic disk bar instability.
     private
     double precision :: stabilityThresholdStellar, stabilityThresholdGaseous, &
          &              timescaleMinimum
   contains
     !@ <objectMethods>
     !@   <object>galacticDynamicsBarInstabilityEfstathiou1982</object>
     !@   <objectMethod>
     !@     <method>estimator</method>
     !@     <arguments></arguments>
     !@     <type>\doublezero</type>
     !@     <description>Compute the stability estimator for the \cite{efstathiou_stability_1982} model for galactic disk bar instability.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     procedure :: timescale => efstathiou1982Timescale
     procedure :: estimator => efstathiou1982Estimator
  end type galacticDynamicsBarInstabilityEfstathiou1982

  interface galacticDynamicsBarInstabilityEfstathiou1982
     !% Constructors for the {\normalfont \ttfamily efstathiou1982} model for galactic disk bar instability class.
     module procedure efstathiou1982ConstructorParameters
     module procedure efstathiou1982ConstructorInternal
  end interface galacticDynamicsBarInstabilityEfstathiou1982

  double precision, parameter :: efstathiou1982StabilityDiskIsolated=0.6221297315d0

contains

  function efstathiou1982ConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily efstathiou1982} model for galactic disk bar instability class which takes a
    !% parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (galacticDynamicsBarInstabilityEfstathiou1982)                :: self
    type            (inputParameters                             ), intent(inout) :: parameters
    double precision                                                              :: stabilityThresholdStellar, stabilityThresholdGaseous, &
         &                                                                           timescaleMinimum

    !# <inputParameter>
    !#   <name>stabilityThresholdStellar</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>1.1d0</defaultValue>
    !#   <description>The stability threshold in the \cite{efstathiou_stability_1982} algorithm for purely stellar disks.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>stabilityThresholdGaseous</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>0.7d0</defaultValue>
    !#   <description>The stability threshold in the \cite{efstathiou_stability_1982} algorithm for purely gaseous disks.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>timescaleMinimum</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>1.0d-9</defaultValue>
    !#   <description>The minimum absolute dynamical timescale (in Gyr) to use in the \cite{efstathiou_stability_1982} algorithm.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !# </inputParameter>
    self=galacticDynamicsBarInstabilityEfstathiou1982(stabilityThresholdStellar,stabilityThresholdGaseous,timescaleMinimum)
    !# <inputParametersValidate source="parameters"/>
    return
  end function efstathiou1982ConstructorParameters

  function efstathiou1982ConstructorInternal(stabilityThresholdStellar,stabilityThresholdGaseous,timescaleMinimum) result(self)
    !% Internal constructor for the {\normalfont \ttfamily efstathiou1982} model for galactic disk bar instability class.
    implicit none
    type            (galacticDynamicsBarInstabilityEfstathiou1982)                :: self
    double precision                                              , intent(in   ) :: stabilityThresholdStellar, stabilityThresholdGaseous, &
         &                                                                           timescaleMinimum
    !# <constructorAssign variables="stabilityThresholdStellar, stabilityThresholdGaseous, timescaleMinimum"/>

    return
  end function efstathiou1982ConstructorInternal

  subroutine efstathiou1982Timescale(self,node,timescale,externalDrivingSpecificTorque)
    !% Computes a timescale for depletion of a disk to a pseudo-bulge via bar instability based on the criterion of
    !% \cite{efstathiou_stability_1982}.
    use :: Galacticus_Nodes                , only : nodeComponentDisk, treeNode
    use :: Numerical_Constants_Astronomical, only : gigaYear         , megaParsec
    use :: Numerical_Constants_Physical    , only : speedLight
    use :: Numerical_Constants_Prefixes    , only : kilo
    implicit none
    class           (galacticDynamicsBarInstabilityEfstathiou1982), intent(inout) :: self
    type            (treeNode                                    ), intent(inout) :: node
    double precision                                              , intent(  out) :: externalDrivingSpecificTorque                , timescale
    class           (nodeComponentDisk                           ), pointer       :: disk
    ! Maximum timescale (in dynamical times) allowed.
    double precision                                              , parameter     :: timescaleDimensionlessMaximum=1.0000000000d10
    double precision                                                              :: massDisk                                     , timeDynamical            , &
         &                                                                           fractionGas                                  , stabilityEstimator       , &
         &                                                                           stabilityEstimatorRelative                   , stabilityIsolatedRelative, &
         &                                                                           stabilityThreshold                           , timescaleDimensionless

    ! Assume infinite timescale (i.e. no instability) initially.
    timescale                    =-1.0d0
    externalDrivingSpecificTorque= 0.0d0
    ! Get the disk.
    disk => node%disk()
    ! Compute the disk mass.
    massDisk=disk%massGas()+disk%massStellar()
    ! Return if disk has unphysical angular momentum.
    if (disk%angularMomentum() <= 0.0d0                            ) return
    ! Return if disk has unphysical velocity or radius.
    if (disk%velocity       () <= 0.0d0 .or. disk%radius() <= 0.0d0) return
    ! Compute the gas fraction in the disk.
    fractionGas=disk%massGas()/massDisk
    ! Compute the stability threshold.
    stabilityThreshold=+self%stabilityThresholdStellar*(1.0d0-fractionGas) &
         &             +self%stabilityThresholdGaseous*       fractionGas
    ! Compute the stability estimator for this node.
    stabilityEstimator=self%estimator(node)
    ! Check if the disk is bar unstable.
    if (stabilityEstimator < stabilityThreshold) then
       ! Disk is unstable, compute a timescale for depletion.
       ! Begin by finding the disk dynamical time.
       timeDynamical=(megaParsec/kilo/gigaYear)*disk%radius()/min(disk%velocity(),speedLight/kilo)
       ! Simple scaling which gives infinite timescale at the threshold, decreasing to dynamical time for a maximally unstable
       ! disk.
       stabilityIsolatedRelative =stabilityThreshold-efstathiou1982StabilityDiskIsolated
       stabilityEstimatorRelative=stabilityThreshold-stabilityEstimator
       if (stabilityIsolatedRelative > timescaleDimensionlessMaximum*stabilityEstimatorRelative) then
          timescaleDimensionless=timescaleDimensionlessMaximum
       else
          timescaleDimensionless=(stabilityIsolatedRelative/stabilityEstimatorRelative)**2
       end if
       timescale=max(timeDynamical,self%timescaleMinimum)*timescaleDimensionless
    end if
    return
  end subroutine efstathiou1982Timescale

  double precision function efstathiou1982Estimator(self,node)
    !% Compute the stability estimator for the \cite{efstathiou_stability_1982} model for galactic disk bar instability.
    use :: Galacticus_Nodes            , only : nodeComponentDisk              , treeNode
    use :: Numerical_Constants_Physical, only : gravitationalConstantGalacticus
    implicit none
    class           (galacticDynamicsBarInstabilityEfstathiou1982), intent(inout) :: self
    type            (treeNode                                    ), intent(inout) :: node
    ! Factor by which to boost velocity (evaluated at scale radius) to convert to maximum velocity (assuming an isolated disk) as
    ! appears in stability criterion.
    double precision                                              , parameter     :: velocityBoostFactor=1.1800237580d0
    class           (nodeComponentDisk                           ), pointer       :: disk
    double precision                                                              :: massDisk
    !GCC$ attributes unused :: self

    ! Get the disk.
    disk => node%disk()
    ! Compute the disk mass.
    massDisk=disk%massGas()+disk%massStellar()
    ! Return perfect stability if there is no disk.
    if (massDisk <= 0.0d0) then
       efstathiou1982Estimator=huge(0.0d0)
    else
       ! Compute the stability estimator for this node.
       efstathiou1982Estimator=max(                                       &
            &                      +efstathiou1982StabilityDiskIsolated , &
            &                      +velocityBoostFactor                   &
            &                      *      disk%velocity()                 &
            &                      /sqrt(                                 &
            &                            +gravitationalConstantGalacticus &
            &                            *massDisk                        &
            &                            /disk%radius  ()                 &
            &                           )                                 &
            &                     )
    end if
    return
  end function efstathiou1982Estimator

