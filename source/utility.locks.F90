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

  !% Contains a module which implements advanced locks.

module Locks
  !% Provides advanced locks.
  use   , intrinsic :: ISO_C_Binding, only : c_size_t
  !$ use            :: OMP_Lib      , only : omp_lock_kind
  implicit none
  private
  public :: ompLock, ompReadWriteLock, ompIncrementalLock

  type :: ompLock
     !% OpenMP lock type which allows querying based on thread number.
     private
     !$ integer(omp_lock_kind) :: lock
     integer                   :: ownerThread=-2
   contains
     !@ <objectMethods>
     !@   <object>ompLock</object>
     !@   <objectMethod>
     !@     <method>set</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Obtain a lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>unset</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Release a lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>initialize</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>(Re)initialize an OpenMP lock object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>ownedByThread</method>
     !@     <type>\logicalzero</type>
     !@     <arguments></arguments>
     !@     <description>Return true if the current thread already owns this lock.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::                  ompLockDestructor
     procedure :: initialize    => ompLockInitialize
     procedure :: set           => ompLockSet
     procedure :: unset         => ompLockUnset
     procedure :: ownedByThread => ompLockOwnedByThread
  end type ompLock

  interface ompLock
     !% Interface to constructors for OpenMP locks.
     module procedure :: ompLockConstructor
  end interface ompLock

  type :: ompReadWriteLock
     !% OpenMP lock type which supports read/write locking.
     private
     !$ integer(omp_lock_kind), allocatable, dimension(:) :: locks
   contains
     !@ <objectMethods>
     !@   <object>ompReadWriteLock</object>
     !@   <objectMethod>
     !@     <method>setRead</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Obtain a read (non-blocking) lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>unsetRead</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Release a read (non-blocking) lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>setWrite</method>
     !@     <type>\void</type>
     !@     <arguments>\logicalzero\ [haveReadLock]\argin</arguments>
     !@     <description>Obtain a write (blocking) lock on the object. The lock will block until all other read/write locks on the object are released and while held will prevent any read locks from being obtained. If the thread requesting the write lock already has a read lock it should set {\normalfont \ttfamily haveReadLock=.true.} when calling this function.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>unsetWrite</method>
     !@     <type>\void</type>
     !@     <arguments>\logicalzero\ [haveReadLock]\argin</arguments>
     !@     <description>Release a write (blocking) lock on the object. If the thread releasing the write lock already had a read lock it should set {\normalfont \ttfamily haveReadLock=.true.} when calling this function to ensure that read locked is retained.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>initialize</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>(Re)initialize an OpenMP read/write lock object</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::               ompReadWriteLockDestructor
     procedure :: initialize => ompReadWriteLockInitialize
     procedure :: setRead    => ompReadWriteLockSetRead
     procedure :: unsetRead  => ompReadWriteLockUnsetRead
     procedure :: setWrite   => ompReadWriteLockSetWrite
     procedure :: unsetWrite => ompReadWriteLockUnsetWrite
  end type ompReadWriteLock

  interface ompReadWriteLock
     !% Interface to constructors for OpenMP read/write locks.
     module procedure :: ompReadWriteLockConstructor
  end interface ompReadWriteLock

  type :: ompIncrementalLock
     !% OpenMP lock type which requires (and forces) locking to proceed in order.
     private
     !$ integer(omp_lock_kind) :: lock
     integer   (c_size_t     ) :: lockValue
   contains
     !@ <objectMethods>
     !@   <object>ompIncrementalLock</object>
     !@   <objectMethod>
     !@     <method>set</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Obtain a lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>unset</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>Release a lock on the object.</description>
     !@   </objectMethod>
     !@   <objectMethod>
     !@     <method>initialize</method>
     !@     <type>\void</type>
     !@     <arguments></arguments>
     !@     <description>(Re)initialize an OpenMP incremental lock object.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::               ompIncrementalLockDestructor
     procedure :: initialize => ompIncrementalLockInitialize
     procedure :: set        => ompIncrementalLockSet
     procedure :: unset      => ompIncrementalLockUnset
  end type ompIncrementalLock

  interface ompIncrementalLock
     !% Interface to constructors for OpenMP incremental locks.
     module procedure :: ompIncrementalLockConstructor
  end interface ompIncrementalLock

contains

  function ompLockConstructor() result (self)
    !% Constructor for OpenMP lock objects.
    implicit none
    type(ompLock) :: self

    call self%initialize()
    return
  end function ompLockConstructor

  subroutine ompLockDestructor(self)
    !% Destructor for OpenMP lock objects.
    !$ use :: OMP_Lib, only : OMP_Destroy_Lock
    implicit none
    type   (ompLock), intent(inout) :: self

    ! Destroy the lock.
    !$ call OMP_Destroy_Lock(self%lock)
    return
  end subroutine ompLockDestructor

  subroutine ompLockInitialize(self)
    !% (Re)initialize an OpenMP lock object.
    !$ use :: OMP_Lib, only : OMP_Init_Lock
    implicit none
    class  (ompLock), intent(inout) :: self

    ! Initialize the lock.
    !$ call OMP_Init_Lock(self%lock)
    self%ownerThread=-1
    return
  end subroutine ompLockInitialize

  subroutine ompLockSet(self)
    !% Get a lock on an OpenMP lock objects.
    !$ use :: OMP_Lib, only : OMP_Get_Thread_Num, OMP_Set_Lock
    implicit none
    class(ompLock), intent(inout) :: self

    if (self%ownerThread == -2) call self%initialize()
    !$ call OMP_Set_Lock(self%lock)
    !$ self%ownerThread=OMP_Get_Thread_Num()
    return
  end subroutine ompLockSet

  subroutine ompLockUnset(self)
    !% Release a lock on an OpenMP lock objects.
    !$ use :: OMP_Lib, only : OMP_Unset_Lock
    implicit none
    class(ompLock), intent(inout) :: self

    !$ call OMP_Unset_Lock(self%lock)
    self%ownerThread=-1
    return
  end subroutine ompLockUnset

  logical function ompLockOwnedByThread(self)
    !% Return true if the lock is owend by the current thread.
    !$ use :: OMP_Lib, only : OMP_Get_Thread_Num
    implicit none
    class(ompLock), intent(inout) :: self

    ompLockOwnedByThread=.true.
    !$ ompLockOwnedByThread=self%ownerThread == OMP_Get_Thread_Num()
    return
  end function ompLockOwnedByThread

  function ompReadWriteLockConstructor() result (self)
    !% Constructor for OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : omp_get_max_threads
    implicit none
    type(ompReadWriteLock) :: self

    ! Allocate a lock for each thread in the current scope.
    !$ allocate(self%locks(0:omp_get_max_threads()-1))
    call self%initialize()
    return
  end function ompReadWriteLockConstructor

  subroutine ompReadWriteLockDestructor(self)
    !% Destructor for OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : OMP_Destroy_Lock
    implicit none
    type   (ompReadWriteLock), intent(inout) :: self
    integer                                  :: i

    ! Check if initialized.
    !$ if (.not.allocated(self%locks)) return
    ! Destroy each lock.
    !$ do i=0,ubound(self%locks,dim=1)
    !$    call OMP_Destroy_Lock(self%locks(i))
    !$ end do
    ! Deallocate the locks.
    !$ deallocate(self%locks)
    return
  end subroutine ompReadWriteLockDestructor

  subroutine ompReadWriteLockInitialize(self)
    !% (Re)initialize an OpenMP read/write lock object.
    !$ use :: OMP_Lib, only : OMP_Init_Lock
    implicit none
    class  (ompReadWriteLock), intent(inout) :: self
    integer                                  :: i

    ! Initialize each lock.
    !$ do i=0,ubound(self%locks,dim=1)
    !$    call OMP_Init_Lock(self%locks(i))
    !$ end do
    return
  end subroutine ompReadWriteLockInitialize

  subroutine ompReadWriteLockSetRead(self)
    !% Get a read lock on an OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : OMP_Set_Lock, omp_get_thread_num
    implicit none
    class(ompReadWriteLock), intent(inout) :: self

    !$ call OMP_Set_Lock(self%locks(omp_get_thread_num()))
    return
  end subroutine ompReadWriteLockSetRead

  subroutine ompReadWriteLockUnsetRead(self)
    !% Release a read lock on an OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : OMP_Unset_Lock, omp_get_thread_num
    implicit none
    class(ompReadWriteLock), intent(inout) :: self

    !$ call OMP_Unset_Lock(self%locks(omp_get_thread_num()))
    return
  end subroutine ompReadWriteLockUnsetRead

  subroutine ompReadWriteLockSetWrite(self,haveReadLock)
    !% Get a write lock on an OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : OMP_Set_Lock
    implicit none
    class  (ompReadWriteLock), intent(inout)               :: self
    logical                  , intent(in   ), optional     :: haveReadLock
    integer                                                :: i
    !# <optionalArgument name="haveReadLock" defaultsTo=".true." />

    ! If we have a read lock, release it to avoid deadlocks.
    !$ if (haveReadLock_) call self%unsetRead()
    ! We must obtain all locks in sequence to avoid the possibility of deadlocking against another thread attempting to obtain a
    ! write lock.
    !$ do i=0,ubound(self%locks,dim=1)
    !$    call OMP_Set_Lock(self%locks(i))
    !$ end do
    return
  end subroutine ompReadWriteLockSetWrite

  subroutine ompReadWriteLockUnsetWrite(self,haveReadLock)
    !% Release a write lock on an OpenMP read/write lock objects.
    !$ use :: OMP_Lib, only : OMP_Unset_Lock
    implicit none
    class  (ompReadWriteLock), intent(inout)           :: self
    logical                  , intent(in   ), optional :: haveReadLock
    integer                                            :: i
    !# <optionalArgument name="haveReadLock" defaultsTo=".true." />

    !$ do i=0,ubound(self%locks,dim=1)
    !$    call OMP_Unset_Lock(self%locks(i))
    !$ end do
    ! Reobtain a read lock if we had one previously.
    !$ if (haveReadLock_) call self%setRead()
    return
  end subroutine ompReadWriteLockUnsetWrite

  function ompIncrementalLockConstructor() result (self)
    !% Constructor for OpenMP incremental lock objects.
    implicit none
    type(ompIncrementalLock) :: self

    call self%initialize()
    return
  end function ompIncrementalLockConstructor

  subroutine ompIncrementalLockDestructor(self)
    !% Destructor for OpenMP incremental lock objects.
    !$ use :: OMP_Lib, only : OMP_Destroy_Lock
    implicit none
    type   (ompIncrementalLock), intent(inout) :: self

    ! Destroy the lock.
    !$ call OMP_Destroy_Lock(self%lock)
    return
  end subroutine ompIncrementalLockDestructor

  subroutine ompIncrementalLockInitialize(self)
    !% (Re)initialize an OpenMP incremental lock object.
    !$ use :: OMP_Lib, only : OMP_Init_Lock
    implicit none
    class  (ompIncrementalLock), intent(inout) :: self

    ! Initialize the lock.
    !$ call OMP_Init_Lock(self%lock)
    self%lockValue=0_c_size_t
    return
  end subroutine ompIncrementalLockInitialize

  subroutine ompIncrementalLockSet(self,lockValue)
    !% Get a lock on an OpenMP incremental lock object.
    !$ use :: OMP_Lib, only : OMP_Set_Lock
    implicit none
    class  (ompIncrementalLock), intent(inout) :: self
    integer(c_size_t          ), intent(in   ) :: lockValue

    do while (self%lockValue /= lockValue-1_c_size_t)
       ! Spin. We sleep for zero seconds - without this sleep() this loop gets optimized out, such that if the check fails the
       ! first time it never gets rechecked.
       call Sleep(0)
    end do
    !$ call OMP_Set_Lock(self%lock)
    self%lockValue=self%lockValue+1_c_size_t
    return
  end subroutine ompIncrementalLockSet

  subroutine ompIncrementalLockUnset(self)
    !% Release a lock on an OpenMP incremental lock object.
    !$ use :: OMP_Lib, only : OMP_Unset_Lock
    implicit none
    class(ompIncrementalLock), intent(inout) :: self

    !$ call OMP_Unset_Lock(self%lock)
    return
  end subroutine ompIncrementalLockUnset

end module Locks
