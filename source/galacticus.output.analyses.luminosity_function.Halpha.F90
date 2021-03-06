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

!% Contains a module which implements a luminosity function output analysis class.

  use :: Cosmology_Functions              , only : cosmologyFunctionsClass
  use :: Geometry_Surveys                 , only : surveyGeometryClass
  use :: Stellar_Spectra_Dust_Attenuations, only : stellarSpectraDustAttenuationClass

  !# <outputAnalysis name="outputAnalysisLuminosityFunctionHalpha">
  !#  <description>A luminosity function output analysis class.</description>
  !# </outputAnalysis>
  type, extends(outputAnalysisVolumeFunction1D) :: outputAnalysisLuminosityFunctionHalpha
     !% A luminosity function output analysis class.
     private
     class(surveyGeometryClass               ), pointer :: surveyGeometry_                => null()
     class(cosmologyFunctionsClass           ), pointer :: cosmologyFunctions_            => null(), cosmologyFunctionsData => null()
     class(stellarSpectraDustAttenuationClass), pointer :: stellarSpectraDustAttenuation_ => null()
   contains
     final :: luminosityFunctionHalphaDestructor
  end type outputAnalysisLuminosityFunctionHalpha

  interface outputAnalysisLuminosityFunctionHalpha
     !% Constructors for the ``luminosityFunctionHalpha'' output analysis class.
     module procedure luminosityFunctionHalphaConstructorParameters
     module procedure luminosityFunctionHalphaConstructorInternal
     module procedure luminosityFunctionHalphaConstructorFile
  end interface outputAnalysisLuminosityFunctionHalpha

contains

  function luminosityFunctionHalphaConstructorParameters(parameters) result (self)
    !% Constructor for the ``luminosityFunctionHalpha'' output analysis class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha )                              :: self
    type            (inputParameters                        ), intent(inout)               :: parameters
    class           (galacticFilterClass                    ), pointer                     :: galacticFilter_
    class           (surveyGeometryClass                    ), pointer                     :: surveyGeometry_
    class           (cosmologyFunctionsClass                ), pointer                     :: cosmologyFunctions_                , cosmologyFunctionsData
    class           (outputTimesClass                       ), pointer                     :: outputTimes_
    class           (outputAnalysisDistributionOperatorClass), pointer                     :: outputAnalysisDistributionOperator_
    class           (outputAnalysisPropertyOperatorClass    ), pointer                     :: outputAnalysisPropertyOperator_
    class           (stellarSpectraDustAttenuationClass     ), pointer                     :: stellarSpectraDustAttenuation_
    double precision                                         , dimension(:  ), allocatable :: luminosities                       , functionValueTarget              , &
         &                                                                                    functionCovarianceTarget1D
    double precision                                         , dimension(:,:), allocatable :: functionCovarianceTarget
    double precision                                                                       :: depthOpticalISMCoefficient
    integer                                                                                :: covarianceBinomialBinsPerDecade
    double precision                                                                       :: covarianceBinomialMassHaloMinimum  , covarianceBinomialMassHaloMaximum
    type            (inputParameters                        )                              :: dataAnalysisParameters
    type            (varying_string                         )                              :: label                              , comment                          , &
         &                                                                                    targetLabel
    logical                                                                                :: includeNitrogenII

    ! Check and read parameters.
    dataAnalysisParameters=parameters%subParameters('dataAnalysis',requirePresent=.false.,requireValue=.false.)
    allocate(luminosities(parameters%count('luminosities')))
    !# <inputParameter>
    !#   <name>label</name>
    !#   <source>parameters</source>
    !#   <description>A label for the luminosity function.</description>
    !#   <type>string</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>comment</name>
    !#   <source>parameters</source>
    !#   <description>A descriptive comment for the luminosity function.</description>
    !#   <type>string</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>luminosities</name>
    !#   <source>parameters</source>
    !#   <description>The luminosities corresponding to bin centers.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>covarianceBinomialBinsPerDecade</name>
    !#   <source>parameters</source>
    !#   <defaultValue>10</defaultValue>
    !#   <description>The number of bins per decade of halo mass to use when constructing luminosity function covariance matrices for main branch galaxies.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>covarianceBinomialMassHaloMinimum</name>
    !#   <source>parameters</source>
    !#   <defaultValue>1.0d8</defaultValue>
    !#   <description>The minimum halo mass to consider when constructing luminosity function covariance matrices for main branch galaxies.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>covarianceBinomialMassHaloMaximum</name>
    !#   <source>parameters</source>
    !#   <defaultValue>1.0d16</defaultValue>
    !#   <description>The maximum halo mass to consider when constructing luminosity function covariance matrices for main branch galaxies.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>includeNitrogenII</name>
    !#   <defaultValue>.false.</defaultValue>
    !#   <description>If true, include contimination by the [NII] (6548\AA $+$ 6584\AA) doublet.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>depthOpticalISMCoefficient</name>
    !#   <defaultValue>1.0d0</defaultValue>
    !#   <source>parameters</source>
    !#   <description>Multiplicative coefficient for optical depth in the ISM.</description>
    !#   <type>string</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    if (parameters%isPresent('targetLabel')) then
       !# <inputParameter>
       !#   <name>targetLabel</name>
       !#   <source>parameters</source>
       !#   <description>Label for the target dataset.</description>
       !#   <type>real</type>
       !#   <cardinality>0..1</cardinality>
       !# </inputParameter>
    end if
    if (parameters%isPresent('functionValueTarget')) then
       if (parameters%isPresent('functionCovarianceTarget')) then
          !# <inputParameter>
          !#   <name>functionValueTarget</name>
          !#   <source>parameters</source>
          !#   <description>The target function for likelihood calculations.</description>
          !#   <type>real</type>
          !#   <cardinality>0..1</cardinality>
          !# </inputParameter>
          !# <inputParameter>
          !#   <name>functionCovarianceTarget</name>
          !#   <source>parameters</source>
          !#   <variable>functionCovarianceTarget1D</variable>
          !#   <description>The target function covariance for likelihood calculations.</description>
          !#   <type>real</type>
          !#   <cardinality>0..1</cardinality>
          !# </inputParameter>
          if (size(functionCovarianceTarget1D) == size(functionValueTarget)**2) then
             allocate(functionCovarianceTarget(size(functionValueTarget),size(functionValueTarget)))
             functionCovarianceTarget=reshape(functionCovarianceTarget1D,shape(functionCovarianceTarget))
          else
             call Galacticus_Error_Report('functionCovariance has wrong size'//{introspection:location})
          end if
       else
          call Galacticus_Error_Report('functionCovariance must be specified if functionTarget is present'//{introspection:location})
       end if
    else
       if (parameters%isPresent('functionCovariance')) call Galacticus_Error_Report('functionTarget must be specified if functionCovariance is present'//{introspection:location})
    end if
    !# <objectBuilder class="galacticFilter"                     name="galacticFilter_"                     source="parameters"            />
    !# <objectBuilder class="outputTimes"                        name="outputTimes_"                        source="parameters"            />
    !# <objectBuilder class="cosmologyFunctions"                 name="cosmologyFunctions_"                 source="parameters"            />
    !# <objectBuilder class="cosmologyFunctions"                 name="cosmologyFunctionsData"              source="dataAnalysisParameters"/>
    !# <objectBuilder class="outputAnalysisPropertyOperator"     name="outputAnalysisPropertyOperator_"     source="parameters"            />
    !# <objectBuilder class="outputAnalysisDistributionOperator" name="outputAnalysisDistributionOperator_" source="parameters"            />
    !# <objectBuilder class="surveyGeometry"                     name="surveyGeometry_"                     source="parameters"            />
    !# <objectBuilder class="stellarSpectraDustAttenuation"      name="stellarSpectraDustAttenuation_"      source="parameters"            />
    !# <conditionalCall>
    !#  <call>self=outputAnalysisLuminosityFunctionHalpha(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,stellarSpectraDustAttenuation_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,outputTimes_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum{conditions})</call>
    !#  <argument name="targetLabel"              value="targetLabel"              parameterPresent="parameters"/>
    !#  <argument name="functionValueTarget"      value="functionValueTarget"      parameterPresent="parameters"/>
    !#  <argument name="functionCovarianceTarget" value="functionCovarianceTarget" parameterPresent="parameters"/>
    !# </conditionalCall>
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="galacticFilter_"                    />
    !# <objectDestructor name="outputTimes_"                       />
    !# <objectDestructor name="cosmologyFunctions_"                />
    !# <objectDestructor name="cosmologyFunctionsData"             />
    !# <objectDestructor name="outputAnalysisPropertyOperator_"    />
    !# <objectDestructor name="outputAnalysisDistributionOperator_"/>
    !# <objectDestructor name="surveyGeometry_"                    />
    !# <objectDestructor name="stellarSpectraDustAttenuation_"     />
    return
  end function luminosityFunctionHalphaConstructorParameters

  function luminosityFunctionHalphaConstructorFile(label,comment,fileName,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,stellarSpectraDustAttenuation_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,outputTimes_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum) result (self)
    !% Constructor for the ``luminosityFunctionHalpha'' output analysis class which reads bin information from a standard format file.
    use :: IO_HDF5, only : hdf5Access, hdf5Object
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha )                              :: self
    type            (varying_string                         ), intent(in   )               :: label                              , comment
    character       (len=*                                  ), intent(in   )               :: fileName
    logical                                                  , intent(in   )               :: includeNitrogenII
    double precision                                         , intent(in   )               :: depthOpticalISMCoefficient
    class           (galacticFilterClass                    ), intent(in   ) , target      :: galacticFilter_
    class           (surveyGeometryClass                    ), intent(in   ) , target      :: surveyGeometry_
    class           (cosmologyFunctionsClass                ), intent(in   ) , target      :: cosmologyFunctions_                , cosmologyFunctionsData
    class           (outputTimesClass                       ), intent(in   ) , target      :: outputTimes_
    class           (outputAnalysisPropertyOperatorClass    ), intent(inout) , target      :: outputAnalysisPropertyOperator_
    class           (outputAnalysisDistributionOperatorClass), intent(in   ) , target      :: outputAnalysisDistributionOperator_
    class           (stellarSpectraDustAttenuationClass     ), intent(in   ) , target      :: stellarSpectraDustAttenuation_
    double precision                                         , dimension(:  ), allocatable :: luminosities                       , functionValueTarget              , &
         &                                                                                    functionErrorTarget
    double precision                                         , dimension(:,:), allocatable :: functionCovarianceTarget
    integer                                                  , intent(in   )               :: covarianceBinomialBinsPerDecade
    double precision                                         , intent(in   )               :: covarianceBinomialMassHaloMinimum  , covarianceBinomialMassHaloMaximum
    integer                                                                                :: i
    type            (hdf5Object                             )                              :: dataFile
    type            (varying_string                         )                              :: targetLabel
    logical                                                                                :: haveTarget

    !$ call hdf5Access%set()
    call dataFile%openFile   (fileName    ,readOnly=.true.)
    call dataFile%readDataset('luminosity',luminosities   )
    haveTarget=dataFile%hasDataset('luminosityFunction').and.dataFile%hasDataset('luminosityFunctionError')
    if (haveTarget) then
       call dataFile%readAttribute('label'                  ,targetLabel        )
       call dataFile%readDataset  ('luminosityFunction'     ,functionValueTarget)
       call dataFile%readDataset  ('luminosityFunctionError',functionErrorTarget)
    end if
    call dataFile%close      (                            )
    !$ call hdf5Access%unset()
    if (haveTarget) then
       allocate(functionCovarianceTarget(size(functionErrorTarget),size(functionErrorTarget)))
       functionCovarianceTarget=0.0d0
       do i=1,size(functionErrorTarget)
          functionCovarianceTarget(i,i)=functionErrorTarget(i)**2
       end do
    end if
    ! Construct the object.
    !# <conditionalCall>
    !#  <call>self=outputAnalysisLuminosityFunctionHalpha(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,stellarSpectraDustAttenuation_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,outputTimes_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum{conditions})</call>
    !#  <argument name="targetLabel"              value="targetLabel"              condition="haveTarget"/>
    !#  <argument name="functionValueTarget"      value="functionValueTarget"      condition="haveTarget"/>
    !#  <argument name="functionCovarianceTarget" value="functionCovarianceTarget" condition="haveTarget"/>
    !# </conditionalCall>
    return
  end function luminosityFunctionHalphaConstructorFile

  function luminosityFunctionHalphaConstructorInternal(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,stellarSpectraDustAttenuation_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,outputTimes_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum,targetLabel,functionValueTarget,functionCovarianceTarget) result(self)
    !% Constructor for the ``luminosityFunctionHalpha'' output analysis class which takes a parameter set as input.
    use :: Cosmology_Functions                     , only : cosmologyFunctionsClass
    use :: Galactic_Filters                        , only : galacticFilterClass
    use :: Galacticus_Error                        , only : Galacticus_Error_Report
    use :: Geometry_Surveys                        , only : surveyGeometryClass
    use :: ISO_Varying_String                      , only : var_str                                    , varying_string
    use :: Memory_Management                       , only : allocateArray
    use :: Node_Property_Extractors                , only : nodePropertyExtractorLmnstyEmssnLine
    use :: Numerical_Constants_Astronomical        , only : megaParsec
    use :: Numerical_Constants_Units               , only : ergs
    use :: Output_Analyses_Options                 , only : outputAnalysisCovarianceModelBinomial
    use :: Output_Analysis_Distribution_Normalizers, only : normalizerList                             , outputAnalysisDistributionNormalizerBinWidth, outputAnalysisDistributionNormalizerLog10ToLog , outputAnalysisDistributionNormalizerSequence
    use :: Output_Analysis_Distribution_Operators  , only : outputAnalysisDistributionOperatorClass
    use :: Output_Analysis_Property_Operators      , only : outputAnalysisPropertyOperatorAntiLog10    , outputAnalysisPropertyOperatorClass         , outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc, outputAnalysisPropertyOperatorLog10         , &
          &                                                 outputAnalysisPropertyOperatorSequence     , propertyOperatorList
    use :: Output_Analysis_Utilities               , only : Output_Analysis_Output_Weight_Survey_Volume
    use :: Output_Analysis_Weight_Operators        , only : outputAnalysisWeightOperatorCsmlgyVolume
    use :: Output_Times                            , only : outputTimesClass
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha         )                                          :: self
    type            (varying_string                                 ), intent(in   )                           :: label                                                 , comment
    logical                                                          , intent(in   )                           :: includeNitrogenII
    double precision                                                 , intent(in   )          , dimension(:  ) :: luminosities
    double precision                                                 , intent(in   )                           :: depthOpticalISMCoefficient
    class           (galacticFilterClass                            ), intent(in   ), target                   :: galacticFilter_
    class           (surveyGeometryClass                            ), intent(in   ), target                   :: surveyGeometry_
    class           (cosmologyFunctionsClass                        ), intent(in   ), target                   :: cosmologyFunctions_                                   , cosmologyFunctionsData
    class           (outputTimesClass                               ), intent(in   ), target                   :: outputTimes_
    class           (outputAnalysisPropertyOperatorClass            ), intent(inout), target                   :: outputAnalysisPropertyOperator_
    class           (outputAnalysisDistributionOperatorClass        ), intent(in   ), target                   :: outputAnalysisDistributionOperator_
    class           (stellarSpectraDustAttenuationClass             ), intent(in   ), target                   :: stellarSpectraDustAttenuation_
    integer                                                          , intent(in   )                           :: covarianceBinomialBinsPerDecade
    double precision                                                 , intent(in   )                           :: covarianceBinomialMassHaloMinimum                     , covarianceBinomialMassHaloMaximum
    type            (varying_string                                 ), intent(in   ), optional                 :: targetLabel
    double precision                                                 , intent(in   ), optional, dimension(:  ) :: functionValueTarget
    double precision                                                 , intent(in   ), optional, dimension(:,:) :: functionCovarianceTarget
    type            (nodePropertyExtractorLmnstyEmssnLine )               , pointer                  :: nodePropertyExtractor_
    type            (outputAnalysisPropertyOperatorLog10            )               , pointer                  :: outputAnalysisPropertyOperatorLog10_
    type            (outputAnalysisPropertyOperatorAntiLog10        )               , pointer                  :: outputAnalysisPropertyOperatorAntiLog10_
    type            (outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc)               , pointer                  :: outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_
    type            (outputAnalysisPropertyOperatorSequence         )               , pointer                  :: outputAnalysisPropertyOperatorSequence_
    type            (outputAnalysisWeightOperatorCsmlgyVolume       )               , pointer                  :: outputAnalysisWeightOperator_
    type            (outputAnalysisDistributionNormalizerSequence   )               , pointer                  :: outputAnalysisDistributionNormalizer_
    type            (normalizerList                                 )               , pointer                  :: normalizerSequence                                    , normalizer_
    type            (propertyOperatorList                           )               , pointer                  :: propertyOperatorSequence
    double precision                                                 , allocatable            , dimension(:,:) :: outputWeight
    type            (varying_string                                 ), allocatable            , dimension(:  ) :: lineNames
    double precision                                                 , parameter                               :: bufferWidth                                     =1.0d0
    integer         (c_size_t                                       ), parameter                               :: bufferCountMinimum                              =5
    integer         (c_size_t                                       )                                          :: iBin                                                  , bufferCount
    !# <constructorAssign variables="*surveyGeometry_, *cosmologyFunctions_, *cosmologyFunctionsData, *outputTimes_"/>

    ! Compute weights that apply to each output redshift.
    self%binCount=size(luminosities,kind=c_size_t)
    call allocateArray(outputWeight,[self%binCount,self%outputTimes_%count()])
    do iBin=1,self%binCount
       outputWeight(iBin,:)=Output_Analysis_Output_Weight_Survey_Volume(self%surveyGeometry_,self%cosmologyFunctions_,self%outputTimes_,luminosity=luminosities(iBin))
    end do
    ! Create a luminosity property extractor.
    allocate(nodePropertyExtractor_)
    if (includeNitrogenII) then
       allocate(lineNames(3))
       lineNames=[var_str('balmerAlpha6563'),var_str('nitrogenII6548'),var_str('nitrogenII6584')]
    else
       allocate(lineNames(1))
       lineNames=[var_str('balmerAlpha6563')                                                    ]
    end if
    !# <referenceConstruct object="nodePropertyExtractor_"                 constructor="nodePropertyExtractorLmnstyEmssnLine (stellarSpectraDustAttenuation_,outputTimes_           ,lineNames,depthOpticalISMCoefficient,outputMask=sum(outputWeight,dim=1) > 0.0d0)"/>
    ! Prepend log10 and cosmological luminosity distance property operators.
    allocate(outputAnalysisPropertyOperatorLog10_            )
    !# <referenceConstruct object="outputAnalysisPropertyOperatorLog10_"             constructor="outputAnalysisPropertyOperatorLog10            (                                                                                                                                      )"/>
    allocate(outputAnalysisPropertyOperatorAntiLog10_        )
    !# <referenceConstruct object="outputAnalysisPropertyOperatorAntiLog10_"         constructor="outputAnalysisPropertyOperatorAntiLog10        (                                                                                                                                      )"/>
    allocate(outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_)
    !# <referenceConstruct object="outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_" constructor="outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc(cosmologyFunctions_           ,cosmologyFunctionsData,outputTimes_                                                                    )"/>
    select type (outputAnalysisPropertyOperator_)
    type is (outputAnalysisPropertyOperatorSequence)
       ! Existing property operator is a sequence operator - simply prepend our magnitude and cosmological luminosity distance operators to it.
       call outputAnalysisPropertyOperator_%prepend(outputAnalysisPropertyOperatorLog10_            )
       call outputAnalysisPropertyOperator_%prepend(outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_)
       !# <referenceAcquire target="outputAnalysisPropertyOperatorSequence_" source="outputAnalysisPropertyOperator_"/>
    class default
       ! Existing operator is some other type - combine with our operators into a sequence operator.
       allocate(propertyOperatorSequence          )
       allocate(propertyOperatorSequence%next     )
       allocate(propertyOperatorSequence%next%next)
       propertyOperatorSequence          %operator_ => outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_
       propertyOperatorSequence%next     %operator_ => outputAnalysisPropertyOperatorLog10_
       propertyOperatorSequence%next%next%operator_ => outputAnalysisPropertyOperator_
       allocate(outputAnalysisPropertyOperatorSequence_)
       !# <referenceConstruct object="outputAnalysisPropertyOperatorSequence_" constructor="outputAnalysisPropertyOperatorSequence(propertyOperatorSequence)"/>
    end select
    ! Create a cosmological volume correction weight operator.
    allocate(outputAnalysisWeightOperator_)
    !# <referenceConstruct object="outputAnalysisWeightOperator_"                    constructor="outputAnalysisWeightOperatorCsmlgyVolume       (cosmologyFunctions_,cosmologyFunctionsData                    ,surveyGeometry_)"/>
    ! Create a bin width distribution normalizer.
    allocate(normalizerSequence)
    normalizer_ => normalizerSequence
    allocate(outputAnalysisDistributionNormalizerBinWidth   :: normalizer_%normalizer_)
    select type (normalizer_ => normalizer_%normalizer_)
    type is (outputAnalysisDistributionNormalizerBinWidth  )
       !# <referenceConstruct object="normalizer_" constructor="outputAnalysisDistributionNormalizerBinWidth  ()"/>
    end select
    allocate(normalizer_%next)
    normalizer_ => normalizer_%next
    allocate(outputAnalysisDistributionNormalizerLog10ToLog :: normalizer_%normalizer_)
    select type (normalizer_ => normalizer_%normalizer_)
    type is (outputAnalysisDistributionNormalizerLog10ToLog)
       !# <referenceConstruct object="normalizer_" constructor="outputAnalysisDistributionNormalizerLog10ToLog()"/>
    end select
    allocate(outputAnalysisDistributionNormalizer_)
    !# <referenceConstruct object="outputAnalysisDistributionNormalizer_"            constructor="outputAnalysisDistributionNormalizerSequence(normalizerSequence)"/>
    ! Compute the number of buffer bins to add to either side of the luminosity function - these are needed to ensure that, e.g.,
    ! convolution operations on the distribution function are unaffected by edge effects.
    bufferCount=max(int(bufferWidth/log10(luminosities(2)/luminosities(1)))+1,bufferCountMinimum)
    ! Construct the object.
    self%outputAnalysisVolumeFunction1D=                                                                                               &
         & outputAnalysisVolumeFunction1D(                                                                                             &
         &                                'luminosityFunctionHalpha'//label                                                          , &
         &                                comment                                                                                    , &
         &                                var_str('luminosity'                                                                      ), &
         &                                var_str('Hα luminosity at the bin center'                                                 ), &
         &                                var_str('ergs/s'                                                                          ), &
         &                                ergs                                                                                       , &
         &                                var_str('luminosityFunction'                                                              ), &
         &                                var_str('luminosity function averaged over each bin'                                      ), &
         &                                var_str('ᵪMpc⁻³'                                                                          ), &
         &                                megaParsec**(-3)                                                                           , &
         &                                log10(luminosities)                                                                        , &
         &                                bufferCount                                                                                , &
         &                                outputWeight                                                                               , &
         &                                nodePropertyExtractor_                                                                     , &
         &                                outputAnalysisPropertyOperatorSequence_                                                    , &
         &                                outputAnalysisPropertyOperatorAntiLog10_                                                   , &
         &                                outputAnalysisWeightOperator_                                                              , &
         &                                outputAnalysisDistributionOperator_                                                        , &
         &                                outputAnalysisDistributionNormalizer_                                                      , &
         &                                galacticFilter_                                                                            , &
         &                                outputTimes_                                                                               , &
         &                                outputAnalysisCovarianceModelBinomial                                                      , &
         &                                covarianceBinomialBinsPerDecade                                                            , &
         &                                covarianceBinomialMassHaloMinimum                                                          , &
         &                                covarianceBinomialMassHaloMaximum                                                          , &
         &                                .false.                                                                                    , &
         &                                var_str('$L_{\mathrm{H}\alpha}$ [ergs/s]'                                                 ), &
         &                                var_str('$\mathrm{d}n/\mathrm{d}\log_\mathrm{e} L_{\mathrm{H}\alpha}$ [$_\chi$Mpc$^{-3}$]'), &
         &                                .true.                                                                                     , &
         &                                .true.                                                                                     , &
         &                                targetLabel                                                                                , &
         &                                functionValueTarget                                                                        , &
         &                                functionCovarianceTarget                                                                     &
         &                               )
    ! Clean up.
    !# <objectDestructor name="nodePropertyExtractor_"                />
    !# <objectDestructor name="outputAnalysisPropertyOperatorLog10_"            />
    !# <objectDestructor name="outputAnalysisPropertyOperatorAntiLog10_"        />
    !# <objectDestructor name="outputAnalysisPropertyOperatorSequence_"         />
    !# <objectDestructor name="outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_"/>
    !# <objectDestructor name="outputAnalysisDistributionNormalizer_"           />
    !# <objectDestructor name="outputAnalysisWeightOperator_"                   />
    nullify(propertyOperatorSequence)
    return
  end function luminosityFunctionHalphaConstructorInternal

  subroutine luminosityFunctionHalphaDestructor(self)
    !% Destructor for  the ``luminosityFunctionHalpha'' output analysis class.
    type(outputAnalysisLuminosityFunctionHalpha), intent(inout) :: self

    !# <objectDestructor name="self%surveyGeometry_"               />
    !# <objectDestructor name="self%stellarSpectraDustAttenuation_"/>
    !# <objectDestructor name="self%cosmologyFunctions_"           />
    !# <objectDestructor name="self%cosmologyFunctionsData"        />
    return
  end subroutine luminosityFunctionHalphaDestructor

