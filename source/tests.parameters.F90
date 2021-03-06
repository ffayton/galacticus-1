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

!% Contains a program which tests parameter input.

program Test_Parameters
  !% Test reading of input parameters.
  use :: Cosmological_Density_Field, only : cosmologicalMassVariance      , cosmologicalMassVarianceClass
  use :: Cosmology_Parameters      , only : cosmologyParameters           , cosmologyParametersClass
  use :: Galacticus_Display        , only : Galacticus_Verbosity_Level_Set, verbosityStandard
  use :: IO_HDF5                   , only : hdf5Object
  use :: ISO_Varying_String        , only : varying_string                , assignment(=)                , var_str
  use :: Input_Parameters          , only : inputParameters
  use :: Unit_Tests                , only : Assert                        , Unit_Tests_Begin_Group       , Unit_Tests_End_Group, Unit_Tests_Finish
  implicit none
  type (hdf5Object                   )          :: outputFile
  type (varying_string               )          :: parameterFile            , parameterValue
  class(cosmologyParametersClass     ), pointer :: cosmologyParameters_
  class(cosmologicalMassVarianceClass), pointer :: cosmologicalMassVariance_
  type (inputParameters              ), target  :: testParameters

  ! Set verbosity level.
  call Galacticus_Verbosity_Level_Set(verbosityStandard)
  ! Open an output file.
  call outputFile%openFile("testSuite/outputs/testParameters.hdf5",overWrite=.true.)
  parameterFile  ='testSuite/parameters/testsParameters.xml'
  testParameters=inputParameters(parameterFile,outputParametersGroup=outputFile)
  call testParameters%markGlobal()
  ! Begin unit tests.
  call Unit_Tests_Begin_Group("Parameter input")
  ! Test retrieval of cosmology parameters (simple).
  cosmologyParameters_ => cosmologyParameters()
  call Unit_Tests_Begin_Group("Retrieve cosmological parameters (simple)")
  call Assert('Ωₘ  ',cosmologyParameters_%OmegaMatter    (), 0.2725d0,relTol=1.0d-6)
  call Assert('Ωb  ',cosmologyParameters_%OmegaBaryon    (), 0.0455d0,relTol=1.0d-6)
  call Assert('ΩΛ  ',cosmologyParameters_%OmegaDarkEnergy(), 0.7275d0,relTol=1.0d-6)
  call Assert('H₀  ',cosmologyParameters_%HubbleConstant (),70.2000d0,relTol=1.0d-6)
  call Assert('TCMB',cosmologyParameters_%temperatureCMB (),2.72548d0,relTol=1.0d-6)
  call Unit_Tests_End_Group()
  ! Test retrieval of cosmological mass variance through a reference.
  cosmologicalMassVariance_ => cosmologicalMassVariance()
  call Unit_Tests_Begin_Group("Parameter referencing")
  call Assert('σ₈ via reference'          ,cosmologicalMassVariance_%sigma8     (                                ),0.912d0,relTol=1.0d-6)
  call Assert('Test presence of reference',testParameters           %isPresent  ('cosmologicalMassVarianceMethod'),.true.               )
  call Assert('Test count of references'  ,testParameters           %copiesCount('cosmologicalMassVarianceMethod'),1                    )
  call Unit_Tests_End_Group()
  ! Test adding, retrieving, reseting, readding a parameter.
  call Unit_Tests_Begin_Group("Parameter adding")
  call testParameters%addParameter('addedParameter','qwertyuiop'  )
  call testParameters%value       ('addedParameter',parameterValue)
  call Assert('added parameter exists'                      ,testParameters%isPresent('addedParameter'),.true.               )
  call Assert('added parameter value is correct'            ,parameterValue                            ,var_str('qwertyuiop'))
  call testParameters%reset()
  call Assert('added parameter no longer exists after reset',testParameters%isPresent('addedParameter'),.false.              )
  call testParameters%addParameter('addedParameter','asdfghjkl'   )
  call testParameters%value       ('addedParameter',parameterValue)
  call Assert('re-added parameter exists'                   ,testParameters%isPresent('addedParameter'),.true.               )
  call Assert('re-added parameter value is correct'         ,parameterValue                            ,var_str('asdfghjkl' ))
  call Unit_Tests_End_Group()
  ! End unit tests.
  call Unit_Tests_End_Group()
  call Unit_Tests_Finish   ()
  ! Close down.
  call testParameters%destroy()
  call outputFile     %close ()
end program Test_Parameters
