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

  !% An implementation of dark matter halo virial density contrasts based on a friends-of-friends linking length.

  !# <virialDensityContrast name="virialDensityContrastFriendsOfFriends">
  !#  <description>Dark matter halo virial density contrasts based on the friends-of-friends algorithm linking length.</description>
  !# </virialDensityContrast>
  type, extends(virialDensityContrastClass) :: virialDensityContrastFriendsOfFriends
     !% A dark matter halo virial density contrast class based on the friends-of-friends algorithm linking length.
     private
     double precision :: linkingLength, densityRatio
   contains
     procedure :: densityContrast             => friendsOfFriendsDensityContrast
     procedure :: densityContrastRateOfChange => friendsOfFriendsDensityContrastRateOfChange
  end type virialDensityContrastFriendsOfFriends

  interface virialDensityContrastFriendsOfFriends
     !% Constructors for the {\normalfont \ttfamily friendsOfFriends} dark matter halo virial density contrast class.
     module procedure friendsOfFriendsConstructorParameters
     module procedure friendsOfFriendsConstructorInternal
  end interface virialDensityContrastFriendsOfFriends

contains

  function friendsOfFriendsConstructorParameters(parameters) result(self)
    !% Default constructor for the {\normalfont \ttfamily friendsOfFriends} dark matter halo virial density contrast class.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (virialDensityContrastFriendsOfFriends)                :: self
    type            (inputParameters                      ), intent(inout) :: parameters
    double precision                                                       :: linkingLength, densityRatio

    !# <inputParameter>
    !#  <name>linkingLength</name>
    !#  <source>parameters</source>
    !#  <defaultValue>0.2d0</defaultValue>
    !#  <description>The friends-of-friends linking length algorithm to use in computing virial density contrast.</description>
    !#  <type>real</type>
    !#  <cardinality>1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#  <name>densityRatio</name>
    !#  <source>parameters</source>
    !#  <defaultValue>4.688d0</defaultValue>
    !#  <defaultSource>Value appropriate for an \gls{nfw} profile with concentration $c=6.88$ which is the concentration found by \cite{prada_halo_2011} for halos with $\sigma=1.686$ which is the approximate critical overdensity for collapse.</defaultSource>
    !#  <description>The ratio of mean virial density to density at the virial radius to assume when setting virial density contrasts in the friends-of-friends model.</description>
    !#  <type>real</type>
    !#  <cardinality>1</cardinality>
    !# </inputParameter>
    self=virialDensityContrastFriendsOfFriends(linkingLength,densityRatio)
    return
  end function friendsOfFriendsConstructorParameters

  function friendsOfFriendsConstructorInternal(linkingLength,densityRatio) result(self)
    !% Generic constructor for the {\normalfont \ttfamily friendsOfFriends} dark matter halo virial density contrast class.
    implicit none
    type            (virialDensityContrastFriendsOfFriends), target        :: self
    double precision                                       , intent(in   ) :: linkingLength, densityRatio
    !# <constructorAssign variables="linkingLength, densityRatio"/>

    return
  end function friendsOfFriendsConstructorInternal

  double precision function friendsOfFriendsDensityContrast(self,mass,time,expansionFactor,collapsing)
    !% Return the virial density contrast at the given epoch, based on the friends-of-friends algorithm linking length.
    use :: Numerical_Constants_Math, only : Pi
    implicit none
    class           (virialDensityContrastFriendsOfFriends), intent(inout)           :: self
    double precision                                       , intent(in   )           :: mass
    double precision                                       , intent(in   ), optional :: time                          , expansionFactor
    logical                                                , intent(in   ), optional :: collapsing
    double precision                                                                 :: boundingSurfaceDensityContrast
    !GCC$ attributes unused :: mass, time, expansionFactor, collapsing

    boundingSurfaceDensityContrast =3.0d0/2.0d0/Pi/self%linkingLength**3
    friendsOfFriendsDensityContrast=self%densityRatio*boundingSurfaceDensityContrast
    return
  end function friendsOfFriendsDensityContrast

  double precision function friendsOfFriendsDensityContrastRateOfChange(self,mass,time,expansionFactor,collapsing)
    !% Return the virial density contrast at the given epoch, based on the friends-of-friends algorithm linking length.
    implicit none
    class           (virialDensityContrastFriendsOfFriends), intent(inout)           :: self
    double precision                                       , intent(in   )           :: mass
    double precision                                       , intent(in   ), optional :: time      , expansionFactor
    logical                                                , intent(in   ), optional :: collapsing
    !GCC$ attributes unused :: self, mass, time, expansionFactor, collapsing

    friendsOfFriendsDensityContrastRateOfChange=0.0d0
    return
  end function friendsOfFriendsDensityContrastRateOfChange
