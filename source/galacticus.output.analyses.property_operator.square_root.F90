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

!% Contains a module which implements an square root output analysis property operator class.

  !# <outputAnalysisPropertyOperator name="outputAnalysisPropertyOperatorSquareRoot">
  !#  <description>An squareRoot output analysis property operator class.</description>
  !# </outputAnalysisPropertyOperator>
  type, extends(outputAnalysisPropertyOperatorClass) :: outputAnalysisPropertyOperatorSquareRoot
     !% An square root output property operator class.
     private
   contains
     procedure :: operate  => squareRootOperate
  end type outputAnalysisPropertyOperatorSquareRoot

  interface outputAnalysisPropertyOperatorSquareRoot
     !% Constructors for the ``squareRoot'' output analysis class.
     module procedure squareRootConstructorParameters
  end interface outputAnalysisPropertyOperatorSquareRoot

contains

  function squareRootConstructorParameters(parameters)
    !% Constructor for the ``squareRoot'' output analysis property operateor class which takes a parameter set as input.
    use Input_Parameters2
    implicit none
    type(outputAnalysisPropertyOperatorSquareRoot)                :: squareRootConstructorParameters
    type(inputParameters                         ), intent(inout) :: parameters
    !GCC$ attributes unused :: parameters

    squareRootConstructorParameters=outputAnalysisPropertyOperatorSquareRoot()
    return
  end function squareRootConstructorParameters

  double precision function squareRootOperate(self,propertyValue,propertyType,outputIndex)
    !% Implement an square root output analysis property operator.
    use, intrinsic :: ISO_C_Binding
    use            :: Galacticus_Error
    implicit none
    class           (outputAnalysisPropertyOperatorSquareRoot), intent(inout)           :: self
    double precision                                          , intent(in   )           :: propertyValue
    integer                                                   , intent(inout), optional :: propertyType
    integer         (c_size_t                                ), intent(in   ), optional :: outputIndex
    !GCC$ attributes unused :: self, outputIndex, propertyType

    if (propertyValue < 0.0d0) call Galacticus_Error_Report('squareRootOperate','domain error: x∈[0,∞)')
    squareRootOperate=sqrt(propertyValue)
    return
  end function squareRootOperate