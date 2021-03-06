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

!% Contains a module which implements a sequence output analysis distribution operator class.

  type, public :: distributionOperatorList
     class(outputAnalysisDistributionOperatorClass), pointer :: operator_
     type (distributionOperatorList               ), pointer :: next     => null()
  end type distributionOperatorList

  !# <outputAnalysisDistributionOperator name="outputAnalysisDistributionOperatorSequence">
  !#  <description>A sequence output analysis distribution operator class.</description>
  !# </outputAnalysisDistributionOperator>
  type, extends(outputAnalysisDistributionOperatorClass) :: outputAnalysisDistributionOperatorSequence
     !% A sequence output distribution operator class.
     private
     type(distributionOperatorList), pointer :: operators => null()
   contains
     !@ <objectMethods>
     !@   <object>outputAnalysisDistributionOperatorSequence</object>
     !@   <objectMethod>
     !@     <method>prepend</method>
     !@     <arguments>\textcolor{red}{\textless class(outputAnalysisDistributionOperatorClass)\textgreater} operator\_\argin</arguments>
     !@     <type>\void</type>
     !@     <description>Prepend an operator to a sequence of distribution operators.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::                        sequenceDestructor
     procedure :: operateScalar       => sequenceOperateScalar
     procedure :: operateDistribution => sequenceOperateDistribution
     procedure :: prepend             => sequencePrepend
     procedure :: deepCopy            => sequenceDeepCopy
  end type outputAnalysisDistributionOperatorSequence

  interface outputAnalysisDistributionOperatorSequence
     !% Constructors for the ``sequence'' output analysis class.
     module procedure sequenceConstructorParameters
     module procedure sequenceConstructorInternal
  end interface outputAnalysisDistributionOperatorSequence

contains

  function sequenceConstructorParameters(parameters) result (self)
    !% Constructor for the ``sequence'' output analysis distribution operator class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type   (outputAnalysisDistributionOperatorSequence)                :: self
    type   (inputParameters                           ), intent(inout) :: parameters
    type   (distributionOperatorList                  ), pointer       :: operator_
    integer                                                            :: i

    self     %operators => null()
    operator_           => null()
    do i=1,parameters%copiesCount('outputAnalysisDistributionOperatorMethod',zeroIfNotPresent=.true.)
       if (associated(operator_)) then
          allocate(operator_%next)
          operator_ => operator_%next
       else
          allocate(self%operators)
          operator_ => self%operators
       end if
       !# <objectBuilder class="outputAnalysisDistributionOperator" name="operator_%operator_" source="parameters" copy="i" />
    end do
    return
  end function sequenceConstructorParameters

  function sequenceConstructorInternal(operators) result (self)
    !% Internal constructor for the sequence merger tree normalizer class.
    implicit none
    type(outputAnalysisDistributionOperatorSequence)                        :: self
    type(distributionOperatorList                  ), target, intent(in   ) :: operators
    type(distributionOperatorList                  ), pointer               :: operator_

    self     %operators => operators
    operator_           => operators
    do while (associated(operator_))
       !# <referenceCountIncrement owner="operator_" object="operator_"/>
       operator_ => operator_%next
    end do
    return
  end function sequenceConstructorInternal

  subroutine sequenceDestructor(self)
    !% Destructor for the sequence distribution operator class.
    implicit none
    type(outputAnalysisDistributionOperatorSequence), intent(inout) :: self
    type(distributionOperatorList                  ), pointer       :: operator_, operatorNext

    if (associated(self%operators)) then
       operator_ => self%operators
       do while (associated(operator_))
          operatorNext => operator_%next
          !# <objectDestructor name="operator_%operator_"/>
          deallocate(operator_)
          operator_ => operatorNext
       end do
    end if
    return
  end subroutine sequenceDestructor

  function sequenceOperateScalar(self,propertyValue,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
    !% Implement an sequence output analysis distribution operator.
    implicit none
    class           (outputAnalysisDistributionOperatorSequence), intent(inout)                                        :: self
    double precision                                            , intent(in   )                                        :: propertyValue
    integer                                                     , intent(in   )                                        :: propertyType
    double precision                                            , intent(in   ), dimension(:)                          :: propertyValueMinimum , propertyValueMaximum
    integer         (c_size_t                                  ), intent(in   )                                        :: outputIndex
    type            (treeNode                                  ), intent(inout)                                        :: node
    double precision                                                           , dimension(size(propertyValueMinimum)) :: sequenceOperateScalar
    type            (distributionOperatorList                  ), pointer                                              :: operator_

    operator_  => self%operators
    do while (associated(operator_))
       ! For first operator, apply to a scalar. Subsequent operators are applied to the distribution.
       if (associated(operator_,self%operators)) then
          sequenceOperateScalar=operator_%operator_%operateScalar      (propertyValue        ,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
       else
          sequenceOperateScalar=operator_%operator_%operateDistribution(sequenceOperateScalar,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
       end if
       operator_ => operator_%next
    end do
    return
  end function sequenceOperateScalar

  function sequenceOperateDistribution(self,distribution,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
    !% Implement a random error output analysis distribution operator.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class           (outputAnalysisDistributionOperatorSequence), intent(inout)                                        :: self
    double precision                                            , intent(in   ), dimension(:)                          :: distribution
    integer                                                     , intent(in   )                                        :: propertyType
    double precision                                            , intent(in   ), dimension(:)                          :: propertyValueMinimum       , propertyValueMaximum
    integer         (c_size_t                                  ), intent(in   )                                        :: outputIndex
    type            (treeNode                                  ), intent(inout)                                        :: node
    double precision                                                           , dimension(size(propertyValueMinimum)) :: sequenceOperateDistribution
    type            (distributionOperatorList                  ), pointer                                              :: operator_

    operator_                   => self        %operators
    sequenceOperateDistribution =  distribution
    do while (associated(operator_))
       sequenceOperateDistribution=operator_%operator_%operateDistribution(sequenceOperateDistribution,propertyType,propertyValueMinimum,propertyValueMaximum,outputIndex,node)
       operator_ => operator_%next
    end do
   return
  end function sequenceOperateDistribution

  subroutine sequencePrepend(self,operator_)
    !% Prepend an operator to the sequence.
    implicit none
    class(outputAnalysisDistributionOperatorSequence), intent(inout)          :: self
    class(outputAnalysisDistributionOperatorClass   ), intent(in   ), target  :: operator_
    type (distributionOperatorList                  )               , pointer :: operatorNew

    allocate(operatorNew)
    operatorNew%operator_ => operator_
    operatorNew%next      => self       %operators
    self       %operators => operatorNew
    return
  end subroutine sequencePrepend

  subroutine sequenceDeepCopy(self,destination)
    !% Perform a deep copy for the {\normalfont \ttfamily sequence} output analysis distribution operator class.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    implicit none
    class(outputAnalysisDistributionOperatorSequence), intent(inout) :: self
    class(outputAnalysisDistributionOperatorClass   ), intent(inout) :: destination
    type (distributionOperatorList                  ), pointer       :: operator_   , operatorDestination_, &
         &                                                              operatorNew_

    call self%outputAnalysisDistributionOperatorClass%deepCopy(destination)
    select type (destination)
    type is (outputAnalysisDistributionOperatorSequence)
       destination%operators => null          ()
       operatorDestination_  => null          ()
       operator_             => self%operators
       do while (associated(operator_))
          allocate(operatorNew_)
          if (associated(operatorDestination_)) then
             operatorDestination_%next       => operatorNew_
             operatorDestination_            => operatorNew_
          else
             destination          %operators => operatorNew_
             operatorDestination_            => operatorNew_
          end if
          allocate(operatorNew_%operator_,mold=operator_%operator_)
          !# <deepCopy source="operator_%operator_" destination="operatorNew_%operator_"/>
          operator_ => operator_%next
       end do
    class default
       call Galacticus_Error_Report('destination and source types do not match'//{introspection:location})
    end select
    return
  end subroutine sequenceDeepCopy

