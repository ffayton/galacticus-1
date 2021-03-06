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

  use :: Cosmology_Functions    , only : cosmologyFunctions  , cosmologyFunctionsClass
  use :: Halo_Spin_Distributions, only : haloSpinDistribution, haloSpinDistributionClass
  use :: Output_Times           , only : outputTimes         , outputTimesClass

  !# <task name="taskHaloSpinDistribution">
  !#  <description>A task which computes and outputs the halo spin distribution.</description>
  !# </task>
  type, extends(taskClass) :: taskHaloSpinDistribution
     !% Implementation of a task which computes and outputs the halo spin distribution.
     private
     class           (haloSpinDistributionClass), pointer :: haloSpinDistribution_ => null()
     class           (outputTimesClass         ), pointer :: outputTimes_          => null()
     class           (cosmologyFunctionsClass  ), pointer :: cosmologyFunctions_   => null()
     double precision                                     :: spinMinimum                    , spinMaximum    , &
          &                                                  spinPointsPerDecade            , haloMassMinimum
     type            (varying_string           )          :: outputGroup
   contains
     final     ::            haloSpinDistributionDestructor
     procedure :: perform => haloSpinDistributionPerform
  end type taskHaloSpinDistribution

  interface taskHaloSpinDistribution
     !% Constructors for the {\normalfont \ttfamily haloSpinDistribution} task.
     module procedure haloSpinDistributionConstructorParameters
     module procedure haloSpinDistributionConstructorInternal
  end interface taskHaloSpinDistribution

contains

  function haloSpinDistributionConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily haloSpinDistribution} task class which takes a parameter set as input.
    use :: Galacticus_Nodes, only : nodeClassHierarchyInitialize, treeNode
    use :: Input_Parameters, only : inputParameter              , inputParameters
    use :: Node_Components , only : Node_Components_Initialize  , Node_Components_Thread_Initialize
    implicit none
    type            (taskHaloSpinDistribution )                :: self
    type            (inputParameters          ), intent(inout) :: parameters
    class           (haloSpinDistributionClass), pointer       :: haloSpinDistribution_
    class           (outputTimesClass         ), pointer       :: outputTimes_
    class           (cosmologyFunctionsClass  ), pointer       :: cosmologyFunctions_
    type            (inputParameters          ), pointer       :: parametersRoot
    type            (varying_string           )                :: outputGroup
    double precision                                           :: spinMinimum          , spinMaximum    , &
         &                                                        spinPointsPerDecade  , haloMassMinimum

    ! Ensure the nodes objects are initialized.
    if (associated(parameters%parent)) then
       parametersRoot => parameters%parent
       do while (associated(parametersRoot%parent))
          parametersRoot => parametersRoot%parent
       end do
       call nodeClassHierarchyInitialize     (parametersRoot)
       call Node_Components_Initialize       (parametersRoot)
       call Node_Components_Thread_Initialize(parametersRoot)
    else
       parametersRoot => null()
       call nodeClassHierarchyInitialize     (parameters    )
       call Node_Components_Initialize       (parameters    )
       call Node_Components_Thread_Initialize(parameters    )
    end if
    !# <inputParameter>
    !#   <name>spinMinimum</name>
    !#   <variable>spinMinimum</variable>
    !#   <defaultValue>3.0d-4</defaultValue>
    !#   <description>Minimum spin for which the distribution function should be calculated.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>spinMaximum</name>
    !#   <variable>spinMaximum</variable>
    !#   <defaultValue>0.5d0</defaultValue>
    !#   <description>Maximum spin for which the distribution function should be calculated.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>spinPointsPerDecade</name>
    !#   <variable>spinPointsPerDecade</variable>
    !#   <defaultValue>10.0d0</defaultValue>
    !#   <description>Number of points per decade of spin at which to calculate the distribution.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>haloMassMinimum</name>
    !#   <variable>haloMassMinimum</variable>
    !#   <defaultValue>0.0d0</defaultValue>
    !#   <description>Minimum halo mass above which spin distribution should be averaged.</description>
    !#   <source>parameters</source>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>outputGroup</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>var_str('.')</defaultValue>
    !#   <description>The HDF5 output group within which to write spin distribution data.</description>
    !#   <source>parameters</source>
    !#   <type>integer</type>
    !# </inputParameter>
    !# <objectBuilder class="haloSpinDistribution" name="haloSpinDistribution_" source="parameters"/>
    !# <objectBuilder class="outputTimes"          name="outputTimes_"          source="parameters"/>
    !# <objectBuilder class="cosmologyFunctions"   name="cosmologyFunctions_"   source="parameters"/>
    self=taskHaloSpinDistribution(spinMinimum,spinMaximum,spinPointsPerDecade,haloMassMinimum,outputGroup,haloSpinDistribution_,outputTimes_,cosmologyFunctions_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="haloSpinDistribution_"/>
    !# <objectDestructor name="outputTimes_"         />
    !# <objectDestructor name="cosmologyFunctions_"  />
    return
  end function haloSpinDistributionConstructorParameters

  function haloSpinDistributionConstructorInternal(spinMinimum,spinMaximum,spinPointsPerDecade,haloMassMinimum,outputGroup,haloSpinDistribution_,outputTimes_,cosmologyFunctions_) result(self)
    !% Constructor for the {\normalfont \ttfamily haloSpinDistribution} task class which takes a parameter set as input.
    implicit none
    type            (taskHaloSpinDistribution )                        :: self
    class           (haloSpinDistributionClass), intent(in   ), target :: haloSpinDistribution_
    class           (outputTimesClass         ), intent(in   ), target :: outputTimes_
    class           (cosmologyFunctionsClass  ), intent(in   ), target :: cosmologyFunctions_
    type            (varying_string           ), intent(in   )         :: outputGroup
    double precision                           , intent(in   )         :: spinMinimum          , spinMaximum    , &
         &                                                                spinPointsPerDecade  , haloMassMinimum
    !# <constructorAssign variables="spinMinimum, spinMaximum, spinPointsPerDecade, haloMassMinimum, outputGroup, *haloSpinDistribution_, *outputTimes_, *cosmologyFunctions_"/>

    return
  end function haloSpinDistributionConstructorInternal

  subroutine haloSpinDistributionDestructor(self)
    !% Destructor for the {\normalfont \ttfamily haloSpinDistribution} task class.
    use :: Node_Components, only : Node_Components_Thread_Uninitialize, Node_Components_Uninitialize
    implicit none
    type(taskHaloSpinDistribution), intent(inout) :: self

    !# <objectDestructor name="self%haloSpinDistribution_"/>
    !# <objectDestructor name="self%outputTimes_"         />
    !# <objectDestructor name="self%cosmologyFunctions_"  />
    call Node_Components_Uninitialize       ()
    call Node_Components_Thread_Uninitialize()
    return
  end subroutine haloSpinDistributionDestructor

  subroutine haloSpinDistributionPerform(self,status)
    !% Compute and output the halo spin distribution.
    use            :: Galacticus_Display     , only : Galacticus_Display_Indent      , Galacticus_Display_Unindent
    use            :: Galacticus_Error       , only : Galacticus_Error_Report        , errorStatusSuccess
    use            :: Galacticus_HDF5        , only : galacticusOutputFile
    use            :: Galacticus_Nodes       , only : nodeComponentBasic             , nodeComponentDarkMatterProfile, nodeComponentSpin, treeNode
    use            :: Halo_Spin_Distributions, only : haloSpinDistributionNbodyErrors
    use            :: IO_HDF5                , only : hdf5Object
    use, intrinsic :: ISO_C_Binding          , only : c_size_t
    use            :: String_Handling        , only : operator(//)
    implicit none
    class           (taskHaloSpinDistribution      ), intent(inout), target       :: self
    integer                                         , intent(  out), optional     :: status
    type            (treeNode                      ), pointer                     :: node
    class           (nodeComponentBasic            ), pointer                     :: nodeBasic
    class           (nodeComponentSpin             ), pointer                     :: nodeSpin
    class           (nodeComponentDarkMatterProfile), pointer                     :: nodeDarkMatterProfile
    double precision                                , allocatable  , dimension(:) :: spin                 , spinDistribution
    integer         (c_size_t                      )                              :: iOutput
    integer                                                                       :: iSpin                , spinCount
    type            (hdf5Object                    )                              :: outputsGroup         , outputGroup     , &
         &                                                                           containerGroup
    type            (varying_string                )                              :: groupName            , commentText

    call Galacticus_Display_Indent('Begin task: halo spin distribution')
    ! Create a tree node.
    node                  => treeNode                  (                 )
    nodeBasic             => node    %basic            (autoCreate=.true.)
    nodeSpin              => node    %spin             (autoCreate=.true.)
    nodeDarkMatterProfile => node    %darkMatterProfile(autoCreate=.true.)
    ! Compute number of spin points to tabulate.
    spinCount=int(log10(self%spinMaximum/self%spinMinimum)*self%spinPointsPerDecade)+1
    allocate(spin            (spinCount))
    allocate(spinDistribution(spinCount))
    ! Open the group for output time information.
    if (self%outputGroup == ".") then
       outputsGroup  =galacticusOutputFile%openGroup(     'Outputs'        ,'Group containing datasets relating to output times.')
    else
       containerGroup=galacticusOutputFile%openGroup(char(self%outputGroup),'Group containing halo mass function data.'          )
       outputsGroup  =containerGroup      %openGroup(     'Outputs'        ,'Group containing datasets relating to output times.')
    end if
    ! Iterate over output redshifts.
    do iOutput=1,self%outputTimes_%count()
       ! Set the epoch for the node.
       call nodeBasic%timeSet(self%outputTimes_%time(iOutput))
       ! Iterate over spins.
       do iSpin=1,spinCount
          spin(iSpin)=exp(log(self%spinMinimum)+log(self%spinMaximum/self%spinMinimum)*dble(iSpin-1)/dble(spinCount-1))
          call nodeSpin%spinSet(spin(iSpin))
          ! Evaluate the distribution.
          if (self%haloMassMinimum <= 0.0d0) then
             ! No minimum halo mass specified - simply evaluate the spin distribution.
             spinDistribution(iSpin)=self%haloSpinDistribution_%distribution(node)
          else
             ! A minimum halo mass was specified. Evaluate the spin distribution averaged over halo mass, if the distribution class
             ! supports this.
             select type (haloSpinDistribution_ => self%haloSpinDistribution_)
             class is (haloSpinDistributionNbodyErrors)
                spinDistribution(iSpin)=haloSpinDistribution_%distributionAveraged(node,self%haloMassMinimum)
             class default
                call Galacticus_Error_Report('halo spin distribution class does not support averaging over halo mass'//{introspection:location})
             end select
          end if
       end do
       ! Open the output group.
       groupName  ='Output'
       commentText='Data for output number '
       groupName  =groupName  //iOutput
       commentText=commentText//iOutput
       outputGroup=outputsGroup%openGroup(char(groupName),char(commentText))
       ! Store the distribution, redshifts, and spins.
       call outputGroup%writeAttribute(                                                                                              self%outputTimes_%time(iOutput)  ,'outputTime'                                                                )
       call outputGroup%writeAttribute(                                                     self%cosmologyFunctions_%expansionFactor(self%outputTimes_%time(iOutput)) ,'outputExpansionFactor'                                                     )
       call outputGroup%writeAttribute(self%cosmologyFunctions_%redshiftFromExpansionFactor(self%cosmologyFunctions_%expansionFactor(self%outputTimes_%time(iOutput))),'outputRedshift'                                                            )
       call outputGroup%writeDataset  (spin                                                                                                                           ,'spin'                 ,'Spins at which the spin distribution is tabulated.')
       call outputGroup%writeDataset  (spinDistribution                                                                                                               ,'spinDistribution'     ,'Spin parameter distribution.'                      )
       call outputGroup%close         (                                                                                                                                                                                                            )
    end do
    call outputsGroup%close()
    if (containerGroup%isOpen()) call containerGroup%close()
    if (present(status)) status=errorStatusSuccess
    call Galacticus_Display_Unindent('Done task: halo spin distribution' )
    return
  end subroutine haloSpinDistributionPerform
