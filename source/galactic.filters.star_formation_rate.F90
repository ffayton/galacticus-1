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

!% Contains a module which implements a galactic high-pass filter for total star formation rate.

  !# <galacticFilter name="galacticFilterStarFormationRate">
  !#  <description>
  !#  A galactic high-pass filter for star formation rate. Galaxies with a combined disk plus
  !#  spheroid star formation rate greater than or equal to a mass-dependent threshold. The threshold is given by
  !#  \begin{equation}
  !#  \log_{10} \left( { \dot{\phi}_\mathrm{t} \over M_\odot\,\hbox{Gyr}^{-1}} \right) = \alpha_0 + \alpha_1  \left( \log_{10} M_\star - \log_{10} M_0 \right),
  !#  \end{equation}
  !#  where $M_0=${\normalfont \ttfamily [starFormationRateThresholdLogM0]}, $\alpha_0=${\normalfont
  !#  \ttfamily [starFormationRateThresholdLogSFR0]}, and $\alpha_1=${\normalfont \ttfamily
  !#  [starFormationRateThresholdLogSFR1]}.
  !#  </description>
  !# </galacticFilter>
  type, extends(galacticFilterClass) :: galacticFilterStarFormationRate
     !% A galactic high-pass filter class for star formation rate.
     private
     double precision :: logM0  , logSFR0, &
          &              logSFR1
   contains
     procedure :: passes => starFormationRatePasses
  end type galacticFilterStarFormationRate

  interface galacticFilterStarFormationRate
     !% Constructors for the ``starFormationRate'' galactic filter class.
     module procedure starFormationRateConstructorParameters
     module procedure starFormationRateConstructorInternal
  end interface galacticFilterStarFormationRate

contains

  function starFormationRateConstructorParameters(parameters)
    !% Constructor for the ``starFormationRate'' galactic filter class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type(galacticFilterStarFormationRate)                :: starFormationRateConstructorParameters
    type(inputParameters                ), intent(inout) :: parameters

    ! Check and read parameters.
    !# <inputParameter>
    !#   <name>logM0</name>
    !#   <source>parameters</source>
    !#   <variable>starFormationRateConstructorParameters%logM0</variable>
    !#   <defaultValue>10.0d0</defaultValue>
    !#   <description>The parameter $\log_{10} M_0$ (with $M_0$ in units of $M_\odot$) appearing in the star formation rate threshold expression for the star formation rate galactic filter class.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>logSFR0</name>
    !#   <source>parameters</source>
    !#   <variable>starFormationRateConstructorParameters%logSFR0</variable>
    !#   <defaultValue>9.0d0</defaultValue>
    !#   <description>The parameter $\alpha_0$ appearing in the star formation rate threshold expression for the star formation rate galactic filter class.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>logSFR1</name>
    !#   <source>parameters</source>
    !#   <variable>starFormationRateConstructorParameters%logSFR1</variable>
    !#   <defaultValue>0.0d0</defaultValue>
    !#   <description>The parameter $\alpha_1$ appearing in the star formation rate threshold expression for the star formation rate galactic filter class.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParametersValidate source="parameters"/>
    return
  end function starFormationRateConstructorParameters

  function starFormationRateConstructorInternal(logM0,logSFR0,logSFR1)
    !% Internal constructor for the ``starFormationRate'' galactic filter class.
    implicit none
    type            (galacticFilterStarFormationRate)                :: starFormationRateConstructorInternal
    double precision                                 , intent(in   ) :: logM0                               , logSFR0, &
         &                                                              logSFR1

    starFormationRateConstructorInternal%logM0  =logM0
    starFormationRateConstructorInternal%logSFR0=logSFR0
    starFormationRateConstructorInternal%logSFR1=logSFR1
    return
  end function starFormationRateConstructorInternal

  logical function starFormationRatePasses(self,node)
    !% Implement an starFormationRate-pass galactic filter.
    use :: Galacticus_Nodes, only : nodeComponentDisk, nodeComponentSpheroid, treeNode
    implicit none
    class           (galacticFilterStarFormationRate), intent(inout) :: self
    type            (treeNode                       ), intent(inout) :: node
    class           (nodeComponentDisk              ), pointer       :: disk
    class           (nodeComponentSpheroid          ), pointer       :: spheroid
    double precision                                                 :: starFormationRate         , stellarMass, &
         &                                                              starFormationRateThreshold

    disk                      => node    %disk             ()
    spheroid                  => node    %spheroid         ()
    stellarMass               = +disk    %massStellar      () &
         &                      +spheroid%massStellar      ()
    starFormationRate         = +disk    %starFormationRate() &
         &                      +spheroid%starFormationRate()
    if (stellarMass > 0.0d0) then
       starFormationRateThreshold= +10.0d0**(                      &
            &                                +  self%logSFR0       &
            &                                +  self%logSFR1       &
            &                                *(                    &
            &                                  +log10(stellarMass) &
            &                                  -self%logM0         &
            &                                )                     &
            &                               )
       starFormationRatePasses=(starFormationRate >= starFormationRateThreshold)
    else
       starFormationRatePasses=.false.
    end if
    return
  end function starFormationRatePasses
