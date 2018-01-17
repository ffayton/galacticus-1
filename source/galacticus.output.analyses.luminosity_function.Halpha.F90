!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018
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

  use Geometry_Surveys
  use Cosmology_Functions

  !# <outputAnalysis name="outputAnalysisLuminosityFunctionHalpha" defaultThreadPrivate="yes">
  !#  <description>A luminosity function output analysis class.</description>
  !# </outputAnalysis>
  type, extends(outputAnalysisVolumeFunction1D) :: outputAnalysisLuminosityFunctionHalpha
     !% A luminosity function output analysis class.
     private
     class(surveyGeometryClass    ), pointer :: surveyGeometry_     => null()
     class(cosmologyFunctionsClass), pointer :: cosmologyFunctions_ => null(), cosmologyFunctionsData => null()
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
    use Input_Parameters
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha )                             :: self
    type            (inputParameters                        ), intent(inout)              :: parameters
    class           (galacticFilterClass                    ), pointer                    :: galacticFilter_
    class           (surveyGeometryClass                    ), pointer                    :: surveyGeometry_
    class           (cosmologyFunctionsClass                ), pointer                    :: cosmologyFunctions_                , cosmologyFunctionsData
    class           (outputAnalysisDistributionOperatorClass), pointer                    :: outputAnalysisDistributionOperator_
    class           (outputAnalysisPropertyOperatorClass    ), pointer                    :: outputAnalysisPropertyOperator_
    double precision                                         , dimension(:) , allocatable :: luminosities
    double precision                                                                      :: depthOpticalISMCoefficient
    integer                                                                               :: covarianceBinomialBinsPerDecade
    double precision                                                                      :: covarianceBinomialMassHaloMinimum  , covarianceBinomialMassHaloMaximum
    type            (inputParameters                        )                             :: dataAnalysisParameters
    type            (varying_string                         )                             :: label                              , comment
    logical                                                                               :: includeNitrogenII

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
    !#   <defaultValue>10</defaultValue>
    !#   <description>The number of bins per decade of halo mass to use when constructing luminosity function covariance matrices for main branch galaxies.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>covarianceBinomialMassHaloMinimum</name>
    !#   <defaultValue>1.0d8</defaultValue>
    !#   <description>The minimum halo mass to consider when constructing luminosity function covariance matrices for main branch galaxies.</description>
    !#   <type>real</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>covarianceBinomialMassHaloMaximum</name>
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
    !# <objectBuilder class="galacticFilter"                     name="galacticFilter_"                     source="parameters"            />
    !# <objectBuilder class="cosmologyFunctions"                 name="cosmologyFunctions_"                 source="parameters"            />
    !# <objectBuilder class="cosmologyFunctions"                 name="cosmologyFunctionsData"              source="dataAnalysisParameters"/>
    !# <objectBuilder class="outputAnalysisPropertyOperator"     name="outputAnalysisPropertyOperator_"     source="parameters"            />
    !# <objectBuilder class="outputAnalysisDistributionOperator" name="outputAnalysisDistributionOperator_" source="parameters"            />
    surveyGeometry_ => surveyGeometry()
    self=outputAnalysisLuminosityFunctionHalpha(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum)
    !# <inputParametersValidate source="parameters"/>
    return
  end function luminosityFunctionHalphaConstructorParameters

  function luminosityFunctionHalphaConstructorFile(label,comment,fileName,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum) result (self)
    !% Constructor for the ``luminosityFunctionHalpha'' output analysis class which reads bin information from a standard format file.
    use IO_HDF5
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha )                             :: self
    type            (varying_string                         ), intent(in   )              :: label                              , comment
    character       (len=*                                  ), intent(in   )              :: fileName
    logical                                                  , intent(in   )              :: includeNitrogenII
    double precision                                         , intent(in   )              :: depthOpticalISMCoefficient
    class           (galacticFilterClass                    ), intent(in   ), target      :: galacticFilter_
    class           (surveyGeometryClass                    ), intent(in   ), target      :: surveyGeometry_
    class           (cosmologyFunctionsClass                ), intent(in   ), target      :: cosmologyFunctions_                , cosmologyFunctionsData
    class           (outputAnalysisPropertyOperatorClass    ), intent(in   ), target      :: outputAnalysisPropertyOperator_
    class           (outputAnalysisDistributionOperatorClass), intent(in   ), target      :: outputAnalysisDistributionOperator_
    double precision                                         , dimension(:) , allocatable :: luminosities
    integer                                                                               :: covarianceBinomialBinsPerDecade
    double precision                                                                      :: covarianceBinomialMassHaloMinimum  , covarianceBinomialMassHaloMaximum
    type            (hdf5Object                             )                             :: dataFile
    
    !$omp critical(HDF5_Access)
    call dataFile%openFile   (fileName    ,readOnly=.true.)
    call dataFile%readDataset('luminosity',luminosities   )
    call dataFile%close      (                            )
    !$omp end critical(HDF5_Access)
    ! Construct the object.
    self=outputAnalysisLuminosityFunctionHalpha(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum)
    return
  end function luminosityFunctionHalphaConstructorFile

  function luminosityFunctionHalphaConstructorInternal(label,comment,luminosities,includeNitrogenII,depthOpticalISMCoefficient,galacticFilter_,surveyGeometry_,cosmologyFunctions_,cosmologyFunctionsData,outputAnalysisPropertyOperator_,outputAnalysisDistributionOperator_,covarianceBinomialBinsPerDecade,covarianceBinomialMassHaloMinimum,covarianceBinomialMassHaloMaximum) result(self)
    !% Constructor for the ``luminosityFunctionHalpha'' output analysis class which takes a parameter set as input.
    use ISO_Varying_String
    use Memory_Management
    use Galacticus_Output_Times
    use String_Handling
    use Galacticus_Error
    use Numerical_Constants_Astronomical
    use Output_Analyses_Options
    use Output_Analysis_Utilities
    use Numerical_Constants_Units
    implicit none
    type            (outputAnalysisLuminosityFunctionHalpha         )                                :: self
    type            (varying_string                                 ), intent(in   )                 :: label                                                 , comment
    logical                                                          , intent(in   )                 :: includeNitrogenII
    double precision                                                 , intent(in   ), dimension(:  ) :: luminosities
    double precision                                                 , intent(in   )                 :: depthOpticalISMCoefficient
    class           (galacticFilterClass                            ), intent(in   ), target         :: galacticFilter_
    class           (surveyGeometryClass                            ), intent(in   ), target         :: surveyGeometry_
    class           (cosmologyFunctionsClass                        ), intent(in   ), target         :: cosmologyFunctions_                                   , cosmologyFunctionsData
    class           (outputAnalysisPropertyOperatorClass            ), intent(in   ), target         :: outputAnalysisPropertyOperator_
    class           (outputAnalysisDistributionOperatorClass        ), intent(in   ), target         :: outputAnalysisDistributionOperator_
    integer                                                          , intent(in   )                 :: covarianceBinomialBinsPerDecade
    double precision                                                 , intent(in   )                 :: covarianceBinomialMassHaloMinimum                     , covarianceBinomialMassHaloMaximum
    type            (outputAnalysisPropertyExtractorLmnstyEmssnLine )               , pointer        :: outputAnalysisPropertyExtractor_
    type            (outputAnalysisPropertyOperatorLog10            )               , pointer        :: outputAnalysisPropertyOperatorLog10_
    type            (outputAnalysisPropertyOperatorAntiLog10        )               , pointer        :: outputAnalysisPropertyOperatorAntiLog10_
    type            (outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc)               , pointer        :: outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_
    type            (outputAnalysisPropertyOperatorSequence         )               , pointer        :: outputAnalysisPropertyOperatorSequence_
    type            (outputAnalysisWeightOperatorCsmlgyVolume       )               , pointer        :: outputAnalysisWeightOperator_
    type            (outputAnalysisDistributionNormalizerSequence   )               , pointer        :: outputAnalysisDistributionNormalizer_
    type            (normalizerList                                 )               , pointer        :: normalizerSequence                                    , normalizer_
    type            (propertyOperatorList                           )               , pointer        :: propertyOperatorSequence
    double precision                                                 , allocatable  , dimension(:,:) :: outputWeight
    type            (varying_string                                 ), allocatable  , dimension(:  ) :: lineNames
    double precision                                                 , parameter                     :: bufferWidth                                     =1.0d0
    integer         (c_size_t                                       ), parameter                     :: bufferCountMinimum                              =5
    integer         (c_size_t                                       )                                :: iBin                                                  , bufferCount
    !# <constructorAssign variables="*surveyGeometry_, *cosmologyFunctions_, *cosmologyFunctionsData"/>
    
    ! Compute weights that apply to each output redshift.
    self%binCount=size(luminosities,kind=c_size_t)
    call allocateArray(outputWeight,[self%binCount,Galacticus_Output_Time_Count()])
    do iBin=1,self%binCount
       outputWeight(iBin,:)=Output_Analysis_Output_Weight_Survey_Volume(self%surveyGeometry_,self%cosmologyFunctionsData,luminosity=luminosities(iBin))
    end do
    ! Create a luminosity property extractor.
    allocate(outputAnalysisPropertyExtractor_)
    if (includeNitrogenII) then
       allocate(lineNames(3))
       lineNames=[var_str('balmerAlpha6563'),var_str('nitrogenII6548'),var_str('nitrogenII6584')]
    else
       allocate(lineNames(1))
       lineNames=[var_str('balmerAlpha6563')                                                    ]
    end if
    outputAnalysisPropertyExtractor_                =outputAnalysisPropertyExtractorLmnstyEmssnLine (lineNames          ,depthOpticalISMCoefficient,outputMask=sum(outputWeight,dim=1) > 0.0d0)
    ! Prepend log10 and cosmological luminosity distance property operators.
    allocate(outputAnalysisPropertyOperatorLog10_            )
    outputAnalysisPropertyOperatorLog10_            =outputAnalysisPropertyOperatorLog10            (                                                                                         )
    allocate(outputAnalysisPropertyOperatorAntiLog10_        )
    outputAnalysisPropertyOperatorAntiLog10_        =outputAnalysisPropertyOperatorAntiLog10        (                                                                                         )
    allocate(outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_)
    outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_=outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc(cosmologyFunctions_,cosmologyFunctionsData                                               )
    select type (outputAnalysisPropertyOperator_)
    type is (outputAnalysisPropertyOperatorSequence)
       ! Existing property operator is a sequence operator - simply prepend our magnitude and cosmological luminosity distance operators to it.
       call outputAnalysisPropertyOperator_%prepend(outputAnalysisPropertyOperatorLog10_            )
       call outputAnalysisPropertyOperator_%prepend(outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_)
       outputAnalysisPropertyOperatorSequence_ => outputAnalysisPropertyOperator_
    class default
       ! Existing operator is some other type - combine with our operators into a sequence operator.
       allocate(propertyOperatorSequence          )
       allocate(propertyOperatorSequence%next     )
       allocate(propertyOperatorSequence%next%next)
       propertyOperatorSequence          %operator_ => outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_
       propertyOperatorSequence%next     %operator_ => outputAnalysisPropertyOperatorLog10_
       propertyOperatorSequence%next%next%operator_ => outputAnalysisPropertyOperator_
       allocate(outputAnalysisPropertyOperatorSequence_)
       outputAnalysisPropertyOperatorSequence_=outputAnalysisPropertyOperatorSequence(propertyOperatorSequence)
    end select
    ! Create a cosmological volume correction weight operator.
    allocate(outputAnalysisWeightOperator_)
    outputAnalysisWeightOperator_                   =outputAnalysisWeightOperatorCsmlgyVolume       (cosmologyFunctions_,cosmologyFunctionsData                    ,surveyGeometry_)
    ! Create a bin width distribution normalizer.
    allocate(normalizerSequence)
    normalizer_ => normalizerSequence
    allocate(outputAnalysisDistributionNormalizerBinWidth   :: normalizer_%normalizer_)
    select type (normalizer_ => normalizer_%normalizer_)
    type is (outputAnalysisDistributionNormalizerBinWidth  )
       normalizer_=outputAnalysisDistributionNormalizerBinWidth  ()
    end select
    allocate(normalizer_%next)
    normalizer_ => normalizer_%next
    allocate(outputAnalysisDistributionNormalizerLog10ToLog :: normalizer_%normalizer_)
    select type (normalizer_ => normalizer_%normalizer_)
    type is (outputAnalysisDistributionNormalizerLog10ToLog)
       normalizer_=outputAnalysisDistributionNormalizerLog10ToLog()
    end select
    allocate(outputAnalysisDistributionNormalizer_)
    outputAnalysisDistributionNormalizer_           =outputAnalysisDistributionNormalizerSequence(normalizerSequence)
    ! Compute the number of buffer bins to add to either side of the luminosity function - these are needed to ensure that, e.g.,
    ! convolution operations on the distribution function are unaffected by edge effects.
    bufferCount=max(int(bufferWidth/log10(luminosities(2)/luminosities(1)))+1,bufferCountMinimum)
    ! Construct the object.
    self%outputAnalysisVolumeFunction1D=                                                         &
         & outputAnalysisVolumeFunction1D(                                                       &
         &                                'luminosityFunctionHalpha'//label                    , &
         &                                comment                                              , &
         &                                var_str('luminosity'                                ), &
         &                                var_str('Hα luminosity at the bin center'           ), &
         &                                var_str('ergs/s'                                    ), &
         &                                ergs                                                 , &
         &                                var_str('luminosityFunction'                        ), &
         &                                var_str('luminosity function averaged over each bin'), &
         &                                var_str('ᵪMpc⁻³'                                    ), &
         &                                megaParsec**(-3)                                     , &
         &                                log10(luminosities)                                  , &
         &                                bufferCount                                          , &
         &                                outputWeight                                         , &
         &                                outputAnalysisPropertyExtractor_                     , &
         &                                outputAnalysisPropertyOperatorSequence_              , &
         &                                outputAnalysisPropertyOperatorAntiLog10_             , &
         &                                outputAnalysisWeightOperator_                        , &
         &                                outputAnalysisDistributionOperator_                  , &
         &                                outputAnalysisDistributionNormalizer_                , &
         &                                galacticFilter_                                      , &
         &                                outputAnalysisCovarianceModelBinomial                , &
         &                                covarianceBinomialBinsPerDecade                      , &
         &                                covarianceBinomialMassHaloMinimum                    , &
         &                                covarianceBinomialMassHaloMaximum                      &
         &                               )
    ! Clean up.
    nullify(outputAnalysisPropertyExtractor_                )
    nullify(outputAnalysisPropertyOperatorLog10_            )
    nullify(outputAnalysisPropertyOperatorAntiLog10_        )
    nullify(outputAnalysisPropertyOperatorSequence_         )
    nullify(outputAnalysisPropertyOperatorCsmlgyLmnstyDstnc_)
    nullify(outputAnalysisDistributionNormalizer_           )
    nullify(outputAnalysisWeightOperator_                   )
    nullify(propertyOperatorSequence                        )
    return
  end function luminosityFunctionHalphaConstructorInternal