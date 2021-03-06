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

!% Contains a module which implements calculations of Bessel functions.

module Bessel_Functions
  !% Implements calculations of Bessel functions.
  use :: FGSL, only : FGSL_SF_Bessel_Jc0, FGSL_SF_Bessel_Jc1     , FGSL_SF_Bessel_Ic0     , FGSL_SF_Bessel_Ic1     , &
       &              FGSL_SF_Bessel_Kc0, FGSL_SF_Bessel_Kc1     , FGSL_SF_Bessel_Zero_Jc0, FGSL_SF_Bessel_Zero_Jc1, &
       &              FGSL_SF_Bessel_Jcn, FGSL_SF_Bessel_Zero_Jnu
  implicit none
  private
  public :: Bessel_Function_J0, Bessel_Function_J1     , Bessel_Function_K0     , Bessel_Function_K1     , &
       &    Bessel_Function_I0, Bessel_Function_I1     , Bessel_Function_J0_Zero, Bessel_Function_J1_Zero, &
       &    Bessel_Function_Jn, Bessel_Function_Jn_Zero

contains

  double precision function Bessel_Function_J0(argument)
    !% Computes the $J_0$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_J0=FGSL_SF_Bessel_Jc0(argument)
    return
  end function Bessel_Function_J0

  double precision function Bessel_Function_J1(argument)
    !% Computes the $J_1$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_J1=FGSL_SF_Bessel_Jc1(argument)
    return
  end function Bessel_Function_J1

  double precision function Bessel_Function_Jn(n,argument)
    !% Computes the $J_n$ Bessel function.
    implicit none
    integer         , intent(in   ) :: n
    double precision, intent(in   ) :: argument

    Bessel_Function_Jn=FGSL_SF_Bessel_Jcn(n,argument)
    return
  end function Bessel_Function_Jn

  double precision function Bessel_Function_J0_Zero(s)
    !% Computes the $s^\mathrm{th}$ zero of the $J_0$ Bessel function.
    implicit none
    integer, intent(in   ) :: s

    Bessel_Function_J0_Zero=FGSL_SF_Bessel_Zero_Jc0(s)
    return
  end function Bessel_Function_J0_Zero

  double precision function Bessel_Function_J1_Zero(s)
    !% Computes the $s^\mathrm{th}$ zero of the $J_1$ Bessel function.
    implicit none
    integer, intent(in   ) :: s

    Bessel_Function_J1_Zero=FGSL_SF_Bessel_Zero_Jc1(s)
    return
  end function Bessel_Function_J1_Zero

  double precision function Bessel_Function_Jn_Zero(n,s)
    !% Computes the $s^\mathrm{th}$ zero of the $J_1$ Bessel function.
    implicit none
    double precision, intent(in   ) :: n
    integer         , intent(in   ) :: s

    Bessel_Function_Jn_Zero=FGSL_SF_Bessel_Zero_Jnu(n,s)
    return
  end function Bessel_Function_Jn_Zero

  double precision function Bessel_Function_K0(argument)
    !% Computes the $K_0$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_K0=FGSL_SF_Bessel_Kc0(argument)
    return
  end function Bessel_Function_K0

  double precision function Bessel_Function_K1(argument)
    !% Computes the $K_1$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_K1=FGSL_SF_Bessel_Kc1(argument)
    return
  end function Bessel_Function_K1

  double precision function Bessel_Function_I0(argument)
    !% Computes the $I_0$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_I0=FGSL_SF_Bessel_Ic0(argument)
    return
  end function Bessel_Function_I0

  double precision function Bessel_Function_I1(argument)
    !% Computes the $I_1$ Bessel function.
    implicit none
    double precision, intent(in   ) :: argument

    Bessel_Function_I1=FGSL_SF_Bessel_Ic1(argument)
    return
  end function Bessel_Function_I1

end module Bessel_Functions
