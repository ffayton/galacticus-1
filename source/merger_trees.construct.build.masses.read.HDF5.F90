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

  !% Implementation of a merger tree masses class which reads masses from an HDF5 file.

  !# <mergerTreeBuildMasses name="mergerTreeBuildMassesReadHDF5">
  !#  <description>A merger tree masses class which reads masses from an HDF5 file.</description>
  !# </mergerTreeBuildMasses>
  type, extends(mergerTreeBuildMassesRead) :: mergerTreeBuildMassesReadHDF5
     !% Implementation of a merger tree masses class which reads masses from an HDF5 file.
     private
   contains
     procedure :: read => readHDF5Read
  end type mergerTreeBuildMassesReadHDF5

  interface mergerTreeBuildMassesReadHDF5
     module procedure readHDF5ConstructorParameters
     module procedure readHDF5ConstructorInternal
  end interface mergerTreeBuildMassesReadHDF5

contains

  function readHDF5ConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily readHDF5} merger tree masses class which takes a parameter set
    !% as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (mergerTreeBuildMassesReadHDF5)                :: self
    type            (inputParameters              ), intent(inout) :: parameters
    type            (varying_string               )                :: fileName
    double precision                                              :: massIntervalFractional

    !# <inputParameter>
    !#   <name>fileName</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The name of the file from which to read merger tree masses.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>massIntervalFractional</name>
    !#   <cardinality>1</cardinality>
    !#   <defaultValue>0.1d0</defaultValue>
    !#   <description>The fractional mass interval occupied by the trees. Where the intervals of trees of different mass would overlap this interval will be truncated.</description>
    !#   <source>parameters</source>
    !#   <type>float</type>
    !# </inputParameter>
    self=mergerTreeBuildMassesReadHDF5(fileName,massIntervalFractional)
    !# <inputParametersValidate target="self" source="parameters"/>
    return
  end function readHDF5ConstructorParameters

  function readHDF5ConstructorInternal(fileName,massIntervalFractional) result(self)
    !% Internal constructor for the {\normalfont \ttfamily readHDF5} merger tree masses class.
    implicit none
    type            (mergerTreeBuildMassesReadHDF5)                :: self
    type            (varying_string               ), intent(in   ) :: fileName
    double precision                               , intent(in   ) :: massIntervalFractional
    !# <constructorAssign variables="fileName, massIntervalFractional"/>

    return
  end function readHDF5ConstructorInternal

  subroutine readHDF5Read(self,mass,weight)
    !% Read merger tree masses from file.
    use :: Galacticus_Error, only : Galacticus_Error_Report
    use :: IO_HDF5         , only : hdf5Access             , hdf5Object
    implicit none
    class           (mergerTreeBuildMassesReadHDF5), intent(inout)                            :: self
    double precision                               , intent(  out), allocatable, dimension(:) :: mass    , weight
    type            (hdf5Object                   )                                           :: treeFile

    call        hdf5Access%set        (                                                     )
    call        treeFile  %openFile   (char(self%fileName),overWrite=.false.,readOnly=.true.)
    call        treeFile  %readDataset('treeRootMass'     ,          mass                   )
    if (treeFile%hasDataset('treeWeight'))                                                    &
         & call treeFile  %readDataset('treeWeight'       ,          weight                 )
    call        treeFile  %close      (                                                     )
    call        hdf5Access%unset      (                                                     )
    return
  end subroutine readHDF5Read

