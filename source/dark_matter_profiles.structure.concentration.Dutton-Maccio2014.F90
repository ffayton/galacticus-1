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

  !% An implementation of dark matter halo profile concentrations using the \cite{dutton_cold_2014} algorithm.

  use :: Cosmology_Functions , only : cosmologyFunctionsClass
  use :: Cosmology_Parameters, only : cosmologyParametersClass

  !# <darkMatterProfileConcentration name="darkMatterProfileConcentrationDuttonMaccio2014">
  !#  <description>Dark matter halo concentrations are computed using the algorithm of \cite{dutton_cold_2014}.</description>
  !# </darkMatterProfileConcentration>
  type, extends(darkMatterProfileConcentrationClass) :: darkMatterProfileConcentrationDuttonMaccio2014
     !% A dark matter halo profile concentration class implementing the algorithm of \cite{dutton_cold_2014}.
     private
     class           (cosmologyParametersClass  ), pointer :: cosmologyParameters_             => null()
     class           (cosmologyFunctionsClass   ), pointer :: cosmologyFunctions_              => null()
     class           (virialDensityContrastClass), pointer :: virialDensityContrastDefinition_ => null()
     class           (darkMatterProfileDMOClass ), pointer :: darkMatterProfileDMODefinition_  => null()
     double precision                                      :: a1                                        , a2                  , &
          &                                                   a3                                        , a4                  , &
          &                                                   b1                                        , b2
     integer                                               :: densityContrastMethod                     , densityProfileMethod
   contains
     !@ <objectMethods>
     !@   <object>darkMatterProfileConcentrationDuttonMaccio2014</object>
     !@   <objectMethod>
     !@     <method>definitions</method>
     !@     <arguments></arguments>
     !@     <type>\void</type>
     !@     <description>Establish definitions for virial density contrast and dark matter halo profile.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::                                   duttonMaccio2014Destructor
     procedure :: definitions                    => duttonMaccio2014Definitions
     procedure :: concentration                  => duttonMaccio2014Concentration
     procedure :: densityContrastDefinition      => duttonMaccio2014DensityContrastDefinition
     procedure :: darkMatterProfileDMODefinition => duttonMaccio2014DarkMatterProfileDefinition
  end type darkMatterProfileConcentrationDuttonMaccio2014

  interface darkMatterProfileConcentrationDuttonMaccio2014
     !% Constructors for the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class.
     module procedure duttonMaccio2014ConstructorParameters
     module procedure duttonMaccio2014ConstructorInternalType
     module procedure duttonMaccio2014ConstructorInternalDefined
  end interface darkMatterProfileConcentrationDuttonMaccio2014

  ! Density contrast methods.
  !# <enumeration>
  !#  <name>duttonMaccio2014DensityContrastMethod</name>
  !#  <description>Enumeration of density contrast methods available in the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class.</description>
  !#  <visibility>private</visibility>
  !#  <entry label="virial"     />
  !#  <entry label="critical200"/>
  !# </enumeration>

  ! Density profile methods.
  !# <enumeration>
  !#  <name>duttonMaccio2014DensityProfileMethod</name>
  !#  <description>Enumeration of density profile methods available in the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class.</description>
  !#  <visibility>private</visibility>
  !#  <entry label="NFW"    />
  !#  <entry label="einasto"/>
  !# </enumeration>

contains

  function duttonMaccio2014ConstructorParameters(parameters) result(self)
    !% Default constructor for the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class.
    implicit none
    type            (darkMatterProfileConcentrationDuttonMaccio2014)                :: self
    type            (inputParameters                               ), intent(inout) :: parameters
    class           (cosmologyParametersClass                      ), pointer       :: cosmologyParameters_
    class           (cosmologyFunctionsClass                       ), pointer       :: cosmologyFunctions_
    type            (varying_string                                )                :: fitType
    double precision                                                                :: a1                  , a2, &
         &                                                                             a3                  , a4, &
         &                                                                             b1                  , b2

    ! Check and read parameters.
    !# <objectBuilder class="cosmologyParameters" name="cosmologyParameters_" source="parameters"/>
    !# <objectBuilder class="cosmologyFunctions"  name="cosmologyFunctions_"  source="parameters"/>
    !# <inputParameter>
    !#   <name>fitType</name>
    !#   <source>parameters</source>
    !#   <defaultValue>var_str('nfwVirial')</defaultValue>
    !#   <description>The type of halo definition for which the concentration-mass relation should be computed. Allowed values are {\normalfont \ttfamily nfwVirial}, {\normalfont \ttfamily nfwCritical200}, {\normalfont \ttfamily einastoCritical200}, and {\normalfont \ttfamily userDefined}.</description>
    !#   <type>string</type>
    !#   <cardinality>1</cardinality>
    !# </inputParameter>
    if (fitType == "userDefined") then
       !# <inputParameter>
       !#   <name>a1</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $a_1$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       !# <inputParameter>
       !#   <name>a2</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $a_2$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       !# <inputParameter>
       !#   <name>a3</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $a_3$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       !# <inputParameter>
       !#   <name>a4</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $a_4$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       !# <inputParameter>
       !#   <name>b1</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $b_1$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       !# <inputParameter>
       !#   <name>b2</name>
       !#   <source>parameters</source>
       !#   <description>Parameter $b_2$ in the \cite{dutton_cold_2014} halo concentration--mass relation.</description>
       !#   <type>real</type>
       !#   <cardinality>1</cardinality>
       !# </inputParameter>
       self=darkMatterProfileConcentrationDuttonMaccio2014(a1,a2,a3,a4,b1,b2,cosmologyParameters_,cosmologyFunctions_)
    else
       self=darkMatterProfileConcentrationDuttonMaccio2014(char(fitType),cosmologyParameters_,cosmologyFunctions_)
    end if
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="cosmologyParameters_"/>
    !# <objectDestructor name="cosmologyFunctions_" />
    return
  end function duttonMaccio2014ConstructorParameters

  function duttonMaccio2014ConstructorInternalType(fitType,cosmologyParameters_,cosmologyFunctions_) result(self)
    !% Constructor for the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    type     (darkMatterProfileConcentrationDuttonMaccio2014)                        :: self
    character(len=*                                         ), intent(in   )         :: fitType
    class    (cosmologyParametersClass                      ), intent(in   ), target :: cosmologyParameters_
    class    (cosmologyFunctionsClass                       ), intent(in   ), target :: cosmologyFunctions_
    !# <constructorAssign variables="*cosmologyParameters_, *cosmologyFunctions_"/>

    select case (fitType)
    case ('nfwVirial'         )
       self%a1                   =+0.537d0
       self%a2                   =+1.025d0
       self%a3                   =-0.718d0
       self%a4                   =+1.080d0
       self%b1                   =-0.097d0
       self%b2                   =+0.024d0
       self%densityContrastMethod=duttonMaccio2014DensityContrastMethodVirial
       self%densityProfileMethod =duttonMaccio2014DensityProfileMethodNFW
    case ('nfwCritical200'    )
       self%a1                   =+0.520d0
       self%a2                   =+0.905d0
       self%a3                   =-0.617d0
       self%a4                   =+1.210d0
       self%b1                   =-0.101d0
       self%b2                   =+0.026d0
       self%densityContrastMethod=duttonMaccio2014DensityContrastMethodCritical200
       self%densityProfileMethod =duttonMaccio2014DensityProfileMethodNFW
    case ('einastoCritical200')
       self%a1                   =+0.459d0
       self%a2                   =+0.977d0
       self%a3                   =-0.490d0
       self%a4                   =+1.303d0
       self%b1                   =-0.130d0
       self%b2                   =+0.029d0
       self%densityContrastMethod=duttonMaccio2014DensityContrastMethodCritical200
       self%densityProfileMethod =duttonMaccio2014DensityProfileMethodEinasto
    case default
       call Galacticus_Error_Report('unrecognized fit type [available types are: nfwVirial, nfwCritical200, einastoCritical200]'//{introspection:location})
    end select
    call self%definitions()
    return
  end function duttonMaccio2014ConstructorInternalType

  function duttonMaccio2014ConstructorInternalDefined(a1,a2,a3,a4,b1,b2,cosmologyParameters_,cosmologyFunctions_) result(self)
    !% Constructor for the {\normalfont \ttfamily duttonMaccio2014} dark matter halo profile concentration class with user defined
    !% parameters.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    type            (darkMatterProfileConcentrationDuttonMaccio2014)                        :: self
    double precision                                                , intent(in   )         :: a1                  , a2, &
         &                                                                                     a3                  , a4, &
         &                                                                                     b1                  , b2
    class           (cosmologyParametersClass                      ), intent(in   ), target :: cosmologyParameters_
    class           (cosmologyFunctionsClass                       ), intent(in   ), target :: cosmologyFunctions_
    !# <constructorAssign variables="a1,a2,a3,a4,b1,b2,*cosmologyParameters_, *cosmologyFunctions_"/>

    call self%definitions()
    return
  end function duttonMaccio2014ConstructorInternalDefined


  subroutine duttonMaccio2014Definitions(self)
    !% Establish virial density contrast and dark matter profile definitions.
    use :: Dark_Matter_Halo_Scales, only : darkMatterHaloScaleVirialDensityContrastDefinition
    use :: Virial_Density_Contrast, only : fixedDensityTypeCritical
    implicit none
    class(darkMatterProfileConcentrationDuttonMaccio2014    ), intent(inout), target  :: self
    type (darkMatterHaloScaleVirialDensityContrastDefinition)               , pointer :: darkMatterHaloScaleDefinition_

    select case (self%densityContrastMethod)
    case (duttonMaccio2014DensityContrastMethodCritical200)
       allocate(virialDensityContrastFixed                                      :: self%virialDensityContrastDefinition_)
       select type (virialDensityContrastDefinition_ => self%virialDensityContrastDefinition_)
       type is (virialDensityContrastFixed                                     )
          !# <referenceConstruct object="virialDensityContrastDefinition_" constructor="virialDensityContrastFixed                                     (200.0d0,fixedDensityTypeCritical,2.0d0,self%cosmologyParameters_,self%cosmologyFunctions_)"/>
       end select
    case (duttonMaccio2014DensityContrastMethodVirial    )
       allocate(virialDensityContrastSphericalCollapseClsnlssMttrCsmlgclCnstnt :: self%virialDensityContrastDefinition_)
       select type (virialDensityContrastDefinition_ => self%virialDensityContrastDefinition_)
       type is (virialDensityContrastSphericalCollapseClsnlssMttrCsmlgclCnstnt)
          !# <referenceConstruct object="virialDensityContrastDefinition_" constructor="virialDensityContrastSphericalCollapseClsnlssMttrCsmlgclCnstnt(.true. ,                                                         self%cosmologyFunctions_)"/>
       end select
    end select
    allocate(darkMatterHaloScaleDefinition_)
    !# <referenceConstruct object="darkMatterHaloScaleDefinition_"   constructor="darkMatterHaloScaleVirialDensityContrastDefinition(self%cosmologyParameters_,self%cosmologyFunctions_,self%virialDensityContrastDefinition_)"/>
    select case (self%densityProfileMethod)
    case (duttonMaccio2014DensityProfileMethodNFW    )
       allocate(darkMatterProfileDMONFW     :: self%darkMatterProfileDMODefinition_)
       select type (darkMatterProfileDMODefinition_ => self%darkMatterProfileDMODefinition_)
       type is (darkMatterProfileDMONFW    )
          !# <referenceConstruct object="darkMatterProfileDMODefinition_" constructor="darkMatterProfileDMONFW   (darkMatterHaloScaleDefinition_)"/>
       end select
    case (duttonMaccio2014DensityProfileMethodEinasto)
       allocate(darkMatterProfileDMOEinasto :: self%darkMatterProfileDMODefinition_)
       select type (darkMatterProfileDMODefinition_ => self%darkMatterProfileDMODefinition_)
       type is (darkMatterProfileDMOEinasto)
          !# <referenceConstruct object="darkMatterProfileDMODefinition_" constructor="darkMatterProfileDMOEinasto(darkMatterHaloScaleDefinition_)"/>
       end select
    end select
    !# <objectDestructor name="darkMatterHaloScaleDefinition_"  />
    return
  end subroutine duttonMaccio2014Definitions

  subroutine duttonMaccio2014Destructor(self)
    !% Destructor for the {\normalfont \ttfamily DuttonMaccio2014} dark matter profile concentration class.
    implicit none
    type(darkMatterProfileConcentrationDuttonMaccio2014), intent(inout) :: self

    !# <objectDestructor name="self%cosmologyParameters_"            />
    !# <objectDestructor name="self%cosmologyFunctions_"             />
    !# <objectDestructor name="self%virialDensityContrastDefinition_"/>
    !# <objectDestructor name="self%darkMatterProfileDMODefinition_"    />
    return
  end subroutine duttonMaccio2014Destructor

  double precision function duttonMaccio2014Concentration(self,node)
    !% Return the concentration of the dark matter halo profile of {\normalfont \ttfamily node} using the \cite{dutton_cold_2014}
    !% algorithm.
    use :: Galacticus_Nodes, only : nodeComponentBasic, treeNode
    implicit none
    class           (darkMatterProfileConcentrationDuttonMaccio2014), intent(inout), target  :: self
    type            (treeNode                                      ), intent(inout), target  :: node
    class           (nodeComponentBasic                            )               , pointer :: basic
    double precision                                                , parameter              :: littleHubbleConstantDuttonMaccio2014= 0.671d0
    double precision                                                , parameter              :: massNormalization                   =12.000d0
    double precision                                                                         :: redshift                                     , logarithmHaloMass, &
         &                                                                                      parameterA                                   , parameterB

    ! Get the basic component.
    basic               => node%basic()
    ! Compute the concentration.
    logarithmHaloMass            =+log10(                                      &
         &                                littleHubbleConstantDuttonMaccio2014 &
         &                               *basic%mass()                         &
         &                              )                                      &
         &                        -massNormalization
    redshift                     =max(                                                                     &
         &                            0.0d0                                                              , &
         &                            self%cosmologyFunctions_ %redshiftFromExpansionFactor(               &
         &                             self%cosmologyFunctions_%expansionFactor             (              &
         &                                                                                   basic%time()  &
         &                                                                                  )              &
         &                                                                                 )               &
         &                           )
    parameterA                   =self%a1+(self%a2-self%a1)*exp(self%a3*redshift**self%a4)
    parameterB                   =self%b1+self%b2*redshift
    duttonMaccio2014Concentration=10.0d0**(parameterA+parameterB*logarithmHaloMass)
    return
  end function duttonMaccio2014Concentration

  function duttonMaccio2014DensityContrastDefinition(self)
    !% Return a virial density contrast object defining that used in the definition of concentration in the \cite{dutton_cold_2014} algorithm.
    implicit none
    class(virialDensityContrastClass                    ), pointer       :: duttonMaccio2014DensityContrastDefinition
    class(darkMatterProfileConcentrationDuttonMaccio2014), intent(inout) :: self

    duttonMaccio2014DensityContrastDefinition => self%virialDensityContrastDefinition_
    return
  end function duttonMaccio2014DensityContrastDefinition

  function duttonMaccio2014DarkMatterProfileDefinition(self)
    !% Return a dark matter density profile object defining that used in the definition of concentration in the
    !% \cite{diemer_universal_2014} algorithm.
    implicit none
    class(darkMatterProfileDMOClass                     ), pointer       :: duttonMaccio2014DarkMatterProfileDefinition
    class(darkMatterProfileConcentrationDuttonMaccio2014), intent(inout) :: self

    duttonMaccio2014DarkMatterProfileDefinition => self%darkMatterProfileDMODefinition_
    return
  end function duttonMaccio2014DarkMatterProfileDefinition
