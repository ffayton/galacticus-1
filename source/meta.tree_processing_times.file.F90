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

!% Contains a module which implements a merger tree processing time estimator using a polynomial relation read from file.

  !# <metaTreeProcessingTime name="metaTreeProcessingTimeFile">
  !#  <description>A merger tree processing time estimator using a polynomial relation read from file.</description>
  !# </metaTreeProcessingTime>
  type, extends(metaTreeProcessingTimeClass) :: metaTreeProcessingTimeFile
     !% A merger tree processing time estimator using a polynomial relation read from file.
     private
     double precision, dimension(0:2) :: fitCoefficient
   contains
     procedure :: time => fileTime
  end type metaTreeProcessingTimeFile

  interface metaTreeProcessingTimeFile
     !% Constructors for the ``file'' merger tree processing time estimator.
     module procedure fileConstructorParameters
     module procedure fileConstructorInternal
  end interface metaTreeProcessingTimeFile

contains

  function fileConstructorParameters(parameters) result(self)
    !% Constructor for the ``file'' merger tree processing time estimator class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type(metaTreeProcessingTimeFile)                :: self
    type(inputParameters           ), intent(inout) :: parameters
    type(varying_string            )                :: fileName

    !# <inputParameter>
    !#   <name>fileName</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The name of the file which contains fit coefficients for the time per tree fitting function.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    self=metaTreeProcessingTimeFile(fileName)
    return
  end function fileConstructorParameters

  function fileConstructorInternal(fileName) result(self)
    !% Internal constructor for the ``file'' merger tree processing time estimator class.
    use :: FoX_DOM         , only : node                   , parseFile
    use :: Galacticus_Error, only : Galacticus_Error_Report
    use :: IO_XML          , only : XML_Array_Read_Static  , XML_Get_First_Element_By_Tag_Name
    implicit none
    type   (metaTreeProcessingTimeFile)                :: self
    type   (varying_string            ), intent(in   ) :: fileName
    type   (node                      ), pointer       :: doc     , fit
    integer                                            :: ioStatus

    ! Parse the fit file.
    !$omp critical (FoX_DOM_Access)
    doc => parseFile(char(fileName),iostat=ioStatus)
    if (ioStatus /= 0) call Galacticus_Error_Report('Unable to find or parse tree timing file'//{introspection:location})
    fit => XML_Get_First_Element_By_Tag_Name(doc,"fit")
    call XML_Array_Read_Static(fit,"coefficient",self%fitCoefficient)
    !$omp end critical (FoX_DOM_Access)
    return
  end function fileConstructorInternal

  double precision function fileTime(self,massTree)
    !% Return the units of the file property in the SI system.
    implicit none
    class           (metaTreeProcessingTimeFile), intent(inout) :: self
    double precision                            , intent(in   ) :: massTree
    integer                                                     :: i
    double precision                                            :: massTreeLogarithmic

    massTreeLogarithmic=log10(massTree)
    fileTime=0.0d0
    do i=0,2
       fileTime=fileTime+self%fitCoefficient(i)*massTreeLogarithmic**i
    end do
    fileTime=10.0d0**fileTime
    return
  end function fileTime

