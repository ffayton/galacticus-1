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

!% Contains a module of useful mathematical constants.

module Numerical_Constants_Math
  !% Contains various useful mathematical constants.
  use :: FGSL        , only : m_e      , m_euler, m_ln10, m_ln2, &
          &                   m_pi
  use :: Kind_Numbers, only : kind_quad
  implicit none
  public

  ! e.
  double precision                , parameter :: e              =m_e

  ! Pi.
  double precision                , parameter :: Pi             =m_pi
  real            (kind=kind_quad), parameter :: PiQuadPrecision=3.141592653589793238462643383279502884197_kind_quad

  ! Natural logarithm of 10.
  double precision                , parameter :: ln10           =m_ln10

  ! Natural logarithm of 2.
  double precision                , parameter :: ln2            =m_ln2

  ! Euler's constant.
  double precision                , parameter :: eulersConstant =m_euler

end module Numerical_Constants_Math
