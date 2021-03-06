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

!% Contains a module which implements calculations of dark matter halo formation times.

module Dark_Matter_Halo_Formation_Times
  !% Implements calculations of dark matter halo formation times.
  implicit none
  private
  public :: Dark_Matter_Halo_Formation_Time

contains

  double precision function Dark_Matter_Halo_Formation_Time(node,formationMassFraction,darkMatterHaloMassAccretionHistory_)
    !% Returns the time at which the main branch progenitor of {\normalfont \ttfamily node} first had a mass equal to {\normalfont \ttfamily
    !% formationMassFraction} of the current mass.
    use :: Dark_Matter_Halo_Mass_Accretion_Histories, only : darkMatterHaloMassAccretionHistoryClass
    use :: Galacticus_Nodes                         , only : nodeComponentBasic                     , treeNode
    implicit none
    type            (treeNode                               ), intent(inout), target :: node
    double precision                                         , intent(in   )         :: formationMassFraction
    class           (darkMatterHaloMassAccretionHistoryClass), intent(inout)         :: darkMatterHaloMassAccretionHistory_
    type            (treeNode                               ), pointer               :: formationNode                      , workNode
    class           (nodeComponentBasic                     ), pointer               :: basicParent                        , basic   , &
         &                                                                              basicWork
    double precision                                                                 :: massNode                           , timeNode

    basic    => node %basic()
    timeNode =  basic%time ()
    massNode =  basic%mass ()
    workNode => node
    do while (associated(workNode))
       formationNode => workNode
       basicWork => workNode%basic()
       if (basicWork%mass() <= formationMassFraction*massNode) exit
       workNode => workNode%firstChild
    end do
    if (.not.associated(workNode)) then
       ! Find the formation time based on the mass accretion history.
       Dark_Matter_Halo_Formation_Time=darkMatterHaloMassAccretionHistory_%time(formationNode,formationMassFraction*massNode)
    else
       ! Interpolate to get the exact time of formation.
       basicParent => workNode%parent%basic()
       Dark_Matter_Halo_Formation_Time=                                 basicWork%time()  &
            &                          +(basicParent%time()            -basicWork%time()) &
            &                          *(formationMassFraction*massNode-basicWork%mass()) &
            &                          /(basicParent%mass()            -basicWork%mass())
    end if
    return
  end function Dark_Matter_Halo_Formation_Time

end module Dark_Matter_Halo_Formation_Times
