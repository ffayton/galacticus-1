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

!% Contains a module which implements storage and recovery of the Galacticus internal state. Used for restoring random number
!% generator sequences for example.

module Galacticus_State
  !% Implements storage and recovery of the Galacticus internal state. Used for restoring random number
  !% generator sequences for example.
  use, intrinsic :: ISO_C_Binding     , only : c_size_t
  use            :: ISO_Varying_String, only : varying_string
  implicit none
  private
  public :: Galacticus_State_Store, Galacticus_State_Retrieve

  ! Flag indicating if we have retrieved the internal state already.
  logical                 :: stateHasBeenRetrieved=.false.

  ! Root name for state files.
  type   (varying_string) :: stateFileRoot                  , stateRetrieveFileRoot

  ! Active status of store and retrieve.
  logical                 :: stateStoreActive               , stateRetrieveActive

  ! Flag indicating if module has been initialized.
  logical                 :: stateInitialized     =.false.

  ! Counter which tracks state operators, used to ensure objects are stored to file only once per operation.
  integer(c_size_t      ) :: stateOperatorID      =0_c_size_t

contains

  !# <functionGlobal>
  !#  <unitName>Galacticus_State_Store</unitName>
  !#  <type>void</type>
  !#  <module>ISO_Varying_String, only : varying_string</module>
  !#  <arguments>type(varying_string) , intent(in   ), optional :: logMessage</arguments>
  !# </functionGlobal>
  subroutine Galacticus_State_Store(logMessage)
    !% Store the internal state.
    use    :: FGSL              , only : FGSL_Close        , FGSL_Open      , fgsl_file
#ifdef USEMPI
    use    :: MPI_Utilities     , only : mpiSelf
#endif
    !$ use :: OMP_Lib           , only : omp_get_thread_num, omp_in_parallel
    use    :: ISO_Varying_String, only : operator(//)      , char
    use    :: String_Handling   , only : operator(//)
    !# <include directive="galacticusStateStoreTask" type="moduleUse">
    include 'galacticus.state.store.modules.inc'
    !# </include>
    implicit none
    type   (varying_string), intent(in   ), optional :: logMessage
    integer                                          :: iError          , stateUnit
    integer(c_size_t      )                          :: stateOperatorID_
    type   (fgsl_file     )                          :: fgslStateFile
    type   (varying_string)                          :: fileName        , fileNameFGSL, &
         &                                              fileNameLog

    ! Ensure that module is initialized.
    call State_Initialize

    ! Check if state store is active.
    if (stateStoreActive) then

       ! Open a file in which to store the state and an additional file for FGSL state.
       fileName    =stateFileRoot//'.state'
       fileNameFGSL=stateFileRoot//'.fgsl.state'
       fileNameLog =stateFileRoot//'.state.log'
       !$ if (omp_in_parallel()) then
       !$    fileName    =fileName    //':openMP'//omp_get_thread_num()
       !$    fileNameFGSL=fileNameFGSL//':openMP'//omp_get_thread_num()
       !$    fileNameLog =fileNameLog //':openMP'//omp_get_thread_num()
       !$ end if
#ifdef USEMPI
       fileName    =fileName    //':MPI'//mpiSelf%rankLabel()
       fileNameFGSL=fileNameFGSL//':MPI'//mpiSelf%rankLabel()
       fileNameLog =fileNameLog //':MPI'//mpiSelf%rankLabel()
#endif
       if (present(logMessage)) then
          open(newunit=stateUnit,file=char(fileNameLog),form='formatted',status='unknown',access='append')
          write (stateUnit,*) char(logMessage)
          close(stateUnit)
       end if

       open(newunit=stateUnit,file=char(fileName),form='unformatted',status='unknown')
       fgslStateFile=FGSL_Open(char(fileNameFGSL),'w')

       !$omp critical(stateOperationID)
       stateOperatorID =stateOperatorID+1_c_size_t
       stateOperatorID_=stateOperatorID
       !$omp end critical(stateOperationID)
       !# <include directive="galacticusStateStoreTask" type="functionCall" functionType="void">
       !#  <functionArgs>stateUnit,fgslStateFile,stateOperatorID_</functionArgs>
       include 'galacticus.state.store.inc'
       !# </include>
       !# <eventHook name="stateStore">
       !#  <callWith>stateUnit,fgslStateFile,stateOperatorID_</callWith>
       !# </eventHook>

       ! Close the state files.
       close(stateUnit)
       iError=FGSL_Close(fgslStateFile)

       ! Flush standard output to ensure that any output log has a record of where the code reached at the last state store.
       call Flush(0)

    end if
    return
  end subroutine Galacticus_State_Store

  !# <functionGlobal>
  !#  <unitName>Galacticus_State_Retrieve</unitName>
  !#  <type>void</type>
  !# </functionGlobal>
  subroutine Galacticus_State_Retrieve
    !% Retrieve the internal state.
    use    :: FGSL              , only : FGSL_Close        , FGSL_Open      , fgsl_file
#ifdef USEMPI
    use    :: MPI_Utilities     , only : mpiSelf
#endif
    !$ use :: OMP_Lib           , only : omp_get_thread_num, omp_in_parallel
    use    :: ISO_Varying_String, only : operator(//)      , char
    use    :: String_Handling   , only : operator(//)
    !# <include directive="galacticusStateRetrieveTask" type="moduleUse">
    include 'galacticus.state.retrieve.modules.inc'
    !# </include>
    implicit none
    integer                 :: iError          , stateUnit
    integer(c_size_t      ) :: stateOperatorID_
    type   (fgsl_file     ) :: fgslStateFile
    type   (varying_string) :: fileName        , fileNameFGSL

    ! Check if we have already retrieved the internal state.
    if (.not.stateHasBeenRetrieved) then

       ! Ensure that module is initialized.
       call State_Initialize

       ! Check if state retrieve is active.
       if (stateRetrieveActive) then

          ! Open a file in which to retrieve the state and an additional file for FGSL state.
          fileName    =stateRetrieveFileRoot//'.state'
          fileNameFGSL=stateRetrieveFileRoot//'.fgsl.state'
          !$ if (omp_in_parallel()) then
          !$    fileName    =fileName    //':openMP'//omp_get_thread_num()
          !$    fileNameFGSL=fileNameFGSL//':openMP'//omp_get_thread_num()
          !$ end if
#ifdef USEMPI
          fileName    =fileName    //':MPI'//mpiSelf%rankLabel()
          fileNameFGSL=fileNameFGSL//':MPI'//mpiSelf%rankLabel()
#endif
          open(newunit=stateUnit,file=char(fileName),form='unformatted',status='old')
          fgslStateFile=FGSL_Open(char(fileNameFGSL),'r')

          !$omp critical(stateOperationID)
          stateOperatorID =stateOperatorID+1_c_size_t
          stateOperatorID_=stateOperatorID
          !$omp end critical(stateOperationID)
          !# <include directive="galacticusStateRetrieveTask" type="functionCall" functionType="void">
          !#  <functionArgs>stateUnit,fgslStateFile,stateOperatorID_</functionArgs>
          include 'galacticus.state.retrieve.inc'
          !# </include>
          !# <eventHook name="stateRestore">
          !#  <callWith>stateUnit,fgslStateFile,stateOperatorID_</callWith>
          !# </eventHook>

          ! Close the state files.
          close(stateUnit)
          iError=FGSL_Close(fgslStateFile)

       end if

       ! Flag that internal state has been retrieved
       stateHasBeenRetrieved=.true.
    end if

    return
  end subroutine Galacticus_State_Retrieve

  subroutine State_Initialize
    !% Initialize the state module by getting the name of the file to which states should be stored and whether or not we are to
    !% retrieve a state.
    use :: Input_Parameters  , only : globalParameters, inputParameter
    use :: ISO_Varying_String, only : var_str         , operator(/=)
    implicit none

    if (.not.stateInitialized) then
       !$omp critical(Galacticus_State_Initialize)
       if (.not.stateInitialized) then
          ! Get the base name of the state files.
          !# <inputParameter>
          !#   <name>stateFileRoot</name>
          !#   <cardinality>1</cardinality>
          !#   <defaultValue>var_str('none')</defaultValue>
          !#   <description>The root name of files to which the internal state is written (to permit restarts).</description>
          !#   <source>globalParameters</source>
          !#   <type>string</type>
          !# </inputParameter>
          ! Get the base name of the files to retrieve from.
          !# <inputParameter>
          !#   <name>stateRetrieveFileRoot</name>
          !#   <cardinality>1</cardinality>
          !#   <defaultValue>var_str('none')</defaultValue>
          !#   <description>The root name of files to which the internal state is retrieved from (to restart).</description>
          !#   <source>globalParameters</source>
          !#   <type>string</type>
          !# </inputParameter>
          ! Record active status of store and retrieve.
          stateStoreActive   =(stateFileRoot         /= "none")
          stateRetrieveActive=(stateRetrieveFileRoot /= "none")
          ! Flag that module is now initialized.
          stateInitialized=.true.
       end if
       !$omp end critical(Galacticus_State_Initialize)
    end if
    return
  end subroutine State_Initialize

end module Galacticus_State
