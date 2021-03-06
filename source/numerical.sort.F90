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

!% Contains a module which implements sorting sequences.

module Sort
  !% Implements sorting.
  use :: FGSL              , only : FGSL_HeapSort , FGSL_HeapSort_Index, FGSL_SizeOf
  use :: ISO_Varying_String, only : varying_string
  implicit none
  private
  public :: Sort_Do, Sort_Index_Do, sortByIndex

  !# <generic identifier="Type">
  !#  <instance label="integer" intrinsic="integer"             />
  !#  <instance label="double"  intrinsic="double precision"    />
  !#  <instance label="varstr"  intrinsic="type(varying_string)"/>
  !# </generic>

  interface Sort_Index_Do
     !% Generic interface to index sort routines.
     module procedure Sort_Index_Do_Double
     module procedure Sort_Index_Do_Integer8
     module procedure Sort_Index_Do_Integer
  end interface Sort_Index_Do

  interface Sort_Do
     !% Generic interface to in-place sort routines.
     module procedure Sort_Do_Double
     module procedure Sort_Do_Double_Both
     module procedure Sort_Do_Integer
     module procedure Sort_Do_Integer8
     module procedure Sort_Do_Integer8_Both
  end interface Sort_Do

  interface sortByIndex
     !% Generic interface to in-place sort routines using a supplied index.
     module procedure sortIndex{Type¦label}
  end interface sortByIndex

contains

  subroutine Sort_Do_Double(array)
    !% Given an unsorted double precision {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    implicit none
    double precision, dimension(:), intent(inout) :: array

    call Sort_Do_Double_C(size(array,kind=c_size_t),array)
    return
  end subroutine Sort_Do_Double

  subroutine Sort_Do_Double_Both(array,array2)
    !% Given an unsorted double precision {\normalfont \ttfamily array}, sorts it in place while also rearranging {\normalfont \ttfamily array2} in the same way.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    implicit none
    double precision                , dimension(:          )              , intent(inout) :: array    , array2
    integer         (kind=c_size_t ), dimension(size(array,kind=c_size_t))                :: sortIndex
    double precision                , dimension(size(array,kind=c_size_t))                :: tmp
    integer         (kind=c_size_t )                                                      :: i

    sortIndex=Sort_Index_Do(array)
    forall(i=1:size(array,kind=c_size_t))
       tmp(i)=array(sortIndex(i))
    end forall
    array=tmp
    forall(i=1:size(array,kind=c_size_t))
       tmp(i)=array2(sortIndex(i))
    end forall
    array2=tmp
    return
  end subroutine Sort_Do_Double_Both

  subroutine Sort_Do_Integer(array)
    !% Given an unsorted integer {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    implicit none
    integer, dimension(:), intent(inout) :: array

    call Sort_Do_Integer_C(size(array,kind=c_size_t),array)
    return
  end subroutine Sort_Do_Integer

  subroutine Sort_Do_Integer8(array)
    !% Given an unsorted long integer {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    use            :: Kind_Numbers , only : kind_int8
    implicit none
    integer(kind=kind_int8), dimension(:), intent(inout) :: array

    call Sort_Do_Integer8_C(size(array,kind=c_size_t),array)
    return
  end subroutine Sort_Do_Integer8

  subroutine Sort_Do_Integer8_Both(array,array2)
    !% Given an unsorted long integer {\normalfont \ttfamily array}, sorts it in place while also rearraning {\normalfont \ttfamily array2} in the same way.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    use            :: Kind_Numbers , only : kind_int8
    implicit none
    integer(kind=kind_int8), dimension(:          )              , intent(inout) :: array    , array2
    integer(kind=c_size_t ), dimension(size(array,kind=c_size_t))                :: sortIndex
    integer(kind=kind_int8), dimension(size(array,kind=c_size_t))                :: tmp
    integer(kind=c_size_t )                                                      :: i

    sortIndex=Sort_Index_Do(array)
    forall(i=1:size(array,kind=c_size_t))
       tmp(i)=array(sortIndex(i))
    end forall
    array=tmp
    forall(i=1:size(array,kind=c_size_t))
       tmp(i)=array2(sortIndex(i))
    end forall
    array2=tmp
    return
  end subroutine Sort_Do_Integer8_Both

  function Sort_Index_Do_Integer8(array)
    !% Given an unsorted integer {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    use            :: Kind_Numbers , only : kind_int8
    implicit none
    integer(kind=kind_int8), dimension(:)                        , intent(in   ) :: array
    integer(kind=c_size_t ), dimension(size(array,kind=c_size_t))                :: Sort_Index_Do_Integer8

    call Sort_Index_Do_Integer8_C(size(array,kind=c_size_t),array,Sort_Index_Do_Integer8)
    Sort_Index_Do_Integer8=Sort_Index_Do_Integer8+1
    return
  end function Sort_Index_Do_Integer8

  function Sort_Index_Do_Integer(array)
    !% Given an unsorted integer {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    use            :: Kind_Numbers , only : kind_int4
    implicit none
    integer(kind=kind_int4), dimension(:)          , intent(in   ) :: array
    integer(kind=c_size_t ), dimension(size(array))                :: Sort_Index_Do_Integer

    call Sort_Index_Do_Integer_C(size(array),array,Sort_Index_Do_Integer)
    Sort_Index_Do_Integer=Sort_Index_Do_Integer+1
    return
  end function Sort_Index_Do_Integer

  function Sort_Index_Do_Double(array)
    !% Given an unsorted double {\normalfont \ttfamily array}, sorts it in place.
    use, intrinsic :: ISO_C_Binding, only : c_double, c_size_t
    implicit none
    real   (kind=c_double), dimension(:                        ), intent(in   ) :: array
    integer(kind=c_size_t), dimension(size(array,kind=c_size_t))                :: Sort_Index_Do_Double

    call Sort_Index_Do_Double_C(size(array,kind=c_size_t),array,Sort_Index_Do_Double)
    Sort_Index_Do_Double=Sort_Index_Do_Double+1
    return
  end function Sort_Index_Do_Double

  subroutine Sort_Do_Double_C(arraySize,array)
    !% Do a double precision sort.
    use, intrinsic :: ISO_C_Binding, only : c_double, c_loc, c_ptr, c_size_t
    implicit none
    integer(kind=c_size_t), intent(in   )         :: arraySize
    real   (kind=c_double), intent(inout), target :: array       (arraySize)
    integer(kind=c_size_t)                        :: arraySizeC
    type   (c_ptr        )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    call FGSL_HeapSort(arrayPointer,arraySizeC,FGSL_SizeOf(1.0d0),Compare_Double)
    return
  end subroutine Sort_Do_Double_C

  subroutine Sort_Do_Integer_C(arraySize,array)
    !% Do a integer sort.
    use, intrinsic :: ISO_C_Binding, only : c_int, c_loc, c_ptr, c_size_t
    implicit none
    integer(kind=c_size_t), intent(in   )         :: arraySize
    integer(kind=c_int   ), intent(inout), target :: array       (arraySize)
    integer(kind=c_size_t)                        :: arraySizeC
    type   (c_ptr        )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    call FGSL_HeapSort(arrayPointer,arraySizeC,FGSL_SizeOf(1),Compare_Integer)
    return
  end subroutine Sort_Do_Integer_C

  subroutine Sort_Do_Integer8_C(arraySize,array)
    !% Do a long integer sort.
    use, intrinsic :: ISO_C_Binding, only : c_loc    , c_long_long, c_ptr, c_size_t
    use            :: Kind_Numbers , only : kind_int8
    implicit none
    integer(kind=c_size_t   ), intent(in   )         :: arraySize
    integer(kind=c_long_long), intent(inout), target :: array       (arraySize)
    integer(kind=c_size_t   )                        :: arraySizeC
    type   (c_ptr           )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    call FGSL_HeapSort(arrayPointer,arraySizeC,FGSL_SizeOf(1_kind_int8),Compare_Integer8)
    return
  end subroutine Sort_Do_Integer8_C

  subroutine Sort_Index_Do_Integer8_C(arraySize,array,idx)
    !% Do a integer sort.
    use, intrinsic :: ISO_C_Binding, only : c_loc    , c_ptr, c_size_t
    use            :: Kind_Numbers , only : kind_int8
    implicit none
    integer(kind=c_size_t ), intent(in   )         :: arraySize
    integer(kind=kind_int8), intent(in   ), target :: array       (arraySize)
    integer(kind=c_size_t ), intent(inout)         :: idx         (arraySize)
    integer(kind=c_size_t )                        :: arraySizeC
    integer                                        :: status
    type   (c_ptr         )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    status=FGSL_HeapSort_Index(idx,arrayPointer,arraySizeC,sizeof(1_kind_int8),Compare_Integer8)
    return
  end subroutine Sort_Index_Do_Integer8_C

  subroutine Sort_Index_Do_Integer_C(arraySize,array,idx)
    !% Do an integer sort.
    use, intrinsic :: ISO_C_Binding, only : c_loc    , c_ptr, c_size_t
    use            :: Kind_Numbers , only : kind_int4
    implicit none
    integer                , intent(in   )         :: arraySize
    integer(kind=kind_int4), intent(in   ), target :: array       (arraySize)
    integer(kind=c_size_t ), intent(inout)         :: idx         (arraySize)
    integer(kind=c_size_t )                        :: arraySizeC
    integer                                        :: status
    type   (c_ptr         )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    status=FGSL_HeapSort_Index(idx,arrayPointer,arraySizeC,sizeof(1_kind_int4),Compare_Integer)
    return
  end subroutine Sort_Index_Do_Integer_C

  subroutine Sort_Index_Do_Double_C(arraySize,array,idx)
    !% Do an double sort.
    use, intrinsic :: ISO_C_Binding, only : c_double, c_loc, c_ptr, c_size_t
    implicit none
    integer(kind=c_size_t), intent(in   )         :: arraySize
    real   (c_double     ), intent(in   ), target :: array       (arraySize)
    integer(kind=c_size_t), intent(inout)         :: idx         (arraySize)
    integer(kind=c_size_t)                        :: arraySizeC
    integer                                       :: status
    type   (c_ptr        )                        :: arrayPointer

    arrayPointer=c_loc(array)
    arraySizeC=arraySize
    status=FGSL_HeapSort_Index(idx,arrayPointer,arraySizeC,sizeof(1_c_double),Compare_Double)
    return
  end subroutine Sort_Index_Do_Double_C

  function Compare_Double(x,y) bind(c)
    !% Comparison function for double precision data.
    use, intrinsic :: ISO_C_Binding, only : c_double, c_f_pointer, c_int, c_ptr
    type   (c_ptr        ), value   :: x             , y
    integer(kind=c_int   )          :: Compare_Double
    real   (kind=c_double), pointer :: rx            , ry

    call c_f_pointer(x,rx)
    call c_f_pointer(y,ry)
    if      (rx > ry) then
       Compare_Double=+1
    else if (rx < ry) then
       Compare_Double=-1
    else
       Compare_Double= 0
    end if
    return
  end function Compare_Double

  function Compare_Integer(x,y) bind(c)
    !% Comparison function for integer data.
    use, intrinsic :: ISO_C_Binding, only : c_f_pointer, c_int, c_ptr
    type   (c_ptr     ), value   :: x              , y
    integer(kind=c_int)          :: Compare_Integer
    integer(kind=c_int), pointer :: rx             , ry

    call c_f_pointer(x,rx)
    call c_f_pointer(y,ry)
    if      (rx > ry) then
       Compare_Integer=+1
    else if (rx < ry) then
       Compare_Integer=-1
    else
       Compare_Integer= 0
    end if
    return
  end function Compare_Integer

  function Compare_Integer8(x,y) bind(c)
    !% Comparison function for integer data.
    use, intrinsic :: ISO_C_Binding, only : c_f_pointer, c_int, c_long_long, c_ptr
    type   (c_ptr           ), value   :: x               , y
    integer(kind=c_int      )          :: Compare_Integer8
    integer(kind=c_long_long), pointer :: rx              , ry

    call c_f_pointer(x,rx)
    call c_f_pointer(y,ry)
    if      (rx > ry) then
       Compare_Integer8=+1
    else if (rx < ry) then
       Compare_Integer8=-1
    else
       Compare_Integer8= 0
    end if
    return
  end function Compare_Integer8

  subroutine sortIndex{Type¦label}(array,index)
    !% Given an {\normalfont \ttfamily array}, sort it in place using the supplied index.
    use, intrinsic :: ISO_C_Binding, only : c_size_t
    implicit none
    {Type¦intrinsic}                , dimension(:          ), intent(inout) :: array
    integer         (kind=c_size_t ), dimension(:          ), intent(in   ) :: index
    {Type¦intrinsic}                , dimension(size(array))                :: arrayTmp
    integer         (kind=c_size_t )                                        :: i

    forall(i=1:size(array))
       arrayTmp(i)=array(index(i))
    end forall
    array=arrayTmp
    return
  end subroutine sortIndex{Type¦label}

end module Sort
