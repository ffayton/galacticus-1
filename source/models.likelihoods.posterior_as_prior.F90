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

  !% Implementation of a posterior sampling likelihood class which implements a likelihood using a given posterior distribution
  !% over the parameters in the form of a set of MCMC chains.

  use :: Nearest_Neighbors, only : nearestNeighbors

  !# <posteriorSampleLikelihood name="posteriorSampleLikelihoodPosteriorAsPrior">
  !#  <description>A posterior sampling likelihood class which implements a likelihood using a given posterior distribution over the parameters in the form of a set of MCMC chains.</description>
  !# </posteriorSampleLikelihood>
  type, extends(posteriorSampleLikelihoodClass) :: posteriorSampleLikelihoodPosteriorAsPrior
     !% Implementation of a posterior sampling likelihood class which implements a likelihood using a given posterior distribution
     !% over the parameters in the form of a set of MCMC chains.
     private
     class           (posteriorSampleLikelihoodClass), pointer                     :: posteriorSampleLikelihood_ => null()
     integer                                         , allocatable, dimension(:  ) :: neighborIndices           , exclusions
     logical                                         , allocatable, dimension(:  ) :: included
     double precision                                , allocatable, dimension(:  ) :: neighborDistances         , rootVariance
     double precision                                , allocatable, dimension(:,:) :: states
     class           (nearestNeighbors              ), allocatable                 :: searcher
     integer                                                                       :: dimCount                  , convergedStateCount  , &
          &                                                                           neighborCount
     double precision                                                              :: tolerance                 , logPriorNormalization
     logical                                                                       :: initialized
   contains
     !@ <objectMethods>
     !@   <object>posteriorSampleLikelihoodPosteriorAsPrior</object>
     !@   <objectMethod>
     !@     <method>initialize</method>
     !@     <type>\void</type>
     !@     <arguments>\textcolor{red}{\textless type(mappingList)[:]\textgreater} modelParametersActive_\argin</arguments>
     !@     <description>Initialize the posterior-as-prior likelihood.</description>
     !@   </objectMethod>
     !@ </objectMethods>
     final     ::                    posteriorAsPriorDestructor
     procedure :: evaluate        => posteriorAsPriorEvaluate
     procedure :: functionChanged => posteriorAsPriorFunctionChanged
     procedure :: initialize      => posteriorAsPriorInitialize
  end type posteriorSampleLikelihoodPosteriorAsPrior

  interface posteriorSampleLikelihoodPosteriorAsPrior
     !% Constructors for the {\normalfont \ttfamily posteriorAsPrior} posterior sampling likelihood class.
     module procedure posteriorAsPriorConstructorParameters
     module procedure posteriorAsPriorConstructorInternal
  end interface posteriorSampleLikelihoodPosteriorAsPrior

contains

  function posteriorAsPriorConstructorParameters(parameters) result(self)
    !% Constructor for the {\normalfont \ttfamily posteriorAsPrior} posterior sampling likelihood class which builds the object
    !% from a parameter set.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (posteriorSampleLikelihoodPosteriorAsPrior)                              :: self
    type            (inputParameters                          ), intent(inout)               :: parameters
    class           (posteriorSampleLikelihoodClass           ), pointer                     :: posteriorSampleLikelihood_
    type            (varying_string                           )                              :: chainBaseName
    integer                                                                                  :: neighborCount
    integer                                                    , allocatable  , dimension(:) :: exclusions
    double precision                                                                         :: tolerance

    !# <inputParameter>
    !#   <name>chainBaseName</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The base name of the MCMC chain files to read.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>neighborCount</name>
    !#   <cardinality>1</cardinality>
    !#   <description>The number of nearest neighbors to use when estimating the posterior likelihood.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>tolerance</name>
    !#   <cardinality>1</cardinality>
    !#   <description>Tolerance to use when estimating the posterior likelihood.</description>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>exclusions</name>
    !#   <cardinality>1</cardinality>
    !#   <description>List of parameter indices to exclude from the posterior likelihood calculation.</description>
    !#   <defaultValue>[integer :: ]</defaultValue>
    !#   <source>parameters</source>
    !#   <type>string</type>
    !# </inputParameter>
    !# <objectBuilder class="posteriorSampleLikelihood" name="posteriorSampleLikelihood_" source="parameters"/>
    self=posteriorSampleLikelihoodPosteriorAsPrior(char(chainBaseName),neighborCount,tolerance,exclusions,posteriorSampleLikelihood_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="posteriorSampleLikelihood_"/>
    return
  end function posteriorAsPriorConstructorParameters

  function posteriorAsPriorConstructorInternal(chainBaseName,neighborCount,tolerance,exclusions,posteriorSampleLikelihood_) result(self)
    !% Constructor for ``posteriorAsPrior'' posterior sampling likelihood class.
    use :: File_Utilities    , only : File_Exists
    use :: ISO_Varying_String, only : varying_string
    use :: Memory_Management , only : allocateArray
    use :: String_Handling   , only : String_Count_Words, char
    implicit none
    type            (posteriorSampleLikelihoodPosteriorAsPrior)                                        :: self
    class           (posteriorSampleLikelihoodClass           ), intent(in   ), target                 :: posteriorSampleLikelihood_
    character       (len=*                                    ), intent(in   )                         :: chainBaseName
    integer                                                    , intent(in   )                         :: neighborCount
    integer                                                    , intent(in   ), optional, dimension(:) :: exclusions
    double precision                                           , intent(in   )                         :: tolerance
    double precision                                           , allocatable            , dimension(:) :: state
    character       (len=1024                                 )                                        :: line
    integer                                                                                            :: chainCount                , iChain    , &
         &                                                                                                chainUnit                 , ioStatus  , &
         &                                                                                                i                         , j
    type            (varying_string                           )                                        :: chainFileName
    character       (len=4                                    )                                        :: label
    logical                                                                                            :: converged
    double precision                                                                                   :: time                      , likelihood
    !# <constructorAssign variables="tolerance, neighborCount, *posteriorSampleLikelihood_"/>

    self%initialized=.false.
    if (present(exclusions)) then
       call allocateArray(self%exclusions,shape(exclusions))
       self%exclusions=exclusions
    else
       call allocateArray(self%exclusions,[0])
    end if
    call allocateArray(self%neighborIndices  ,[neighborCount])
    call allocateArray(self%neighborDistances,[neighborCount])
    ! Read MCMC chains.
    iChain=-1
    do while (iChain < 10000)
       iChain=iChain+1
       write (label,'(i4.4)') iChain
       chainFileName=chainBaseName//"_"//trim(adjustl(label))//".log"
       if (.not.File_Exists(chainFileName)) then
          iChain=iChain-1
          exit
       end if
       if (iChain == 0) then
          open(newUnit=chainUnit,file=char(chainFileName),status='old',form='formatted',iostat=ioStatus)
          read (chainUnit,'(a)') line
          self%dimCount=String_Count_Words(line)-5
          call allocateArray(self%included,[self%dimCount])
          self%dimCount=self%dimCount-size(self%exclusions)
          close(chainUnit)
       end if
    end do
    ! Construct inclusion mask.
    self%included=.true.
    do i=1,size(self%exclusions)
       self%included(self%exclusions(i))=.false.
    end do
    chainCount=iChain+1
    i         = 0
    do iChain=0,chainCount-1
       write (label,'(i4.4)') iChain
       chainFileName=chainBaseName//"_"//trim(adjustl(label))//".log"
       if (iChain == 0) then
          ! Count number of converged states in the file.
          self%convergedStateCount=0
          open(newUnit=chainUnit,file=char(chainFileName),status='old',form='formatted',iostat=ioStatus)
          do while (ioStatus == 0)
             read (chainUnit,*,iostat=ioStatus) j,j,time,converged
             if (ioStatus /= 0) cycle
             if (converged) self%convergedStateCount=self%convergedStateCount+1
          end do
          close(chainUnit)
          ! Allocate storage for all converged points.
          self%convergedStateCount=self%convergedStateCount*chainCount
          call allocateArray(self%states,[self%convergedStateCount,self%dimCount])
          call allocateArray(     state ,shape(self%included)                    )
       end if
       open(newUnit=chainUnit,file=char(chainFileName),status='old',form='formatted',iostat=ioStatus)
       do while (ioStatus == 0)
          read (chainUnit,*,iostat=ioStatus) j,j,time,converged,likelihood,state
          if (ioStatus /= 0) cycle
          if (converged) then
             i=i+1
             self%states(i,:)=pack(state,self%included)
          end if
       end do
       close(chainUnit)
    end do
    return
  end function posteriorAsPriorConstructorInternal

  subroutine posteriorAsPriorDestructor(self)
    !% Destructor for ``posterior as prior'' posterior sampling likelihood class.
    implicit none
    type(posteriorSampleLikelihoodPosteriorAsPrior), intent(inout) :: self

    !# <objectDestructor name="self%posteriorSampleLikelihood_"/>
    return
  end subroutine posteriorAsPriorDestructor

  subroutine posteriorAsPriorInitialize(self,modelParametersActive_)
    !% Initialize a ``posterior as prior'' likelihood object.
    use :: Memory_Management, only : allocateArray
    implicit none
    class           (posteriorSampleLikelihoodPosteriorAsPrior), intent(inout)               :: self
    type            (modelParameterList                       ), intent(in   ), dimension(:) :: modelParametersActive_
    double precision                                           , allocatable  , dimension(:) :: mean                  , meanSquared
    integer                                                                                  :: i                     , j          , &
         &                                                                                      k

    ! Set initialization state.
    if (self%initialized) return
    self%initialized=.true.
    ! Map states.
    do i=1,self%convergedStateCount
       k=0
       do j=1,size(self%included)
          if (self%included(j)) then
             k=k+1
             self%states(i,k)=modelParametersActive_(j)%modelParameter_%map(self%states(i,k))
          end if
       end do
    end do
    ! Estimate variance in each dimension.
    call allocateArray(mean             ,[self%dimCount])
    call allocateArray(meanSquared      ,[self%dimCount])
    call allocateArray(self%rootVariance,[self%dimCount])
    mean             =sum(self%states   ,dim=1)/dble(self%convergedStateCount)
    meanSquared      =sum(self%states**2,dim=1)/dble(self%convergedStateCount)
    self%rootVariance=sqrt(meanSquared-mean**2)
    ! Scale states by root-variance.
    forall(i=1:self%convergedStateCount)
       self%states(i,:)=self%states(i,:)/self%rootVariance
    end forall
    ! Evaluate normalization factor for prior. Includes normalization for
    ! number of states used and conversion back to unscaled parameters.
    self%logPriorNormalization=-log(dble(self%convergedStateCount))-log(product(self%rootVariance))
    ! Construct the search object.
    allocate(self%searcher)
    select type (s => self%searcher)
    type is (nearestNeighbors)
       s=nearestNeighbors(self%states)
    end select
    return
  end subroutine posteriorAsPriorInitialize

  double precision function posteriorAsPriorEvaluate(self,simulationState,modelParametersActive_,modelParametersInactive_,simulationConvergence,temperature,logLikelihoodCurrent,logPriorCurrent,logPriorProposed,timeEvaluate,logLikelihoodVariance,forceAcceptance)
    !% Return the log-likelihood for a ``posterior as prior'' likelihood function.
    use :: Numerical_Constants_Math      , only : Pi
    use :: Posterior_Sampling_Convergence, only : posteriorSampleConvergenceClass
    use :: Posterior_Sampling_State      , only : posteriorSampleStateClass
    implicit none
    class           (posteriorSampleLikelihoodPosteriorAsPrior), intent(inout)               :: self
    class           (posteriorSampleStateClass                ), intent(inout)               :: simulationState
    type            (modelParameterList                       ), intent(in   ), dimension(:) :: modelParametersActive_, modelParametersInactive_
    class           (posteriorSampleConvergenceClass          ), intent(inout)               :: simulationConvergence
    double precision                                           , intent(in   )               :: temperature           , logLikelihoodCurrent    , &
         &                                                                                      logPriorCurrent       , logPriorProposed
    real                                                       , intent(inout)               :: timeEvaluate
    double precision                                           , intent(  out), optional     :: logLikelihoodVariance
    logical                                                    , intent(inout), optional     :: forceAcceptance
    double precision                                           , allocatable  , dimension(:) :: stateVector           , stateVectorPacked
    double precision                                                                         :: kernelScale           , weight
    integer                                                                                  :: i
    !GCC$ attributes unused :: forceAcceptance

    ! Initialize.
    call self%initialize(modelParametersActive_)
    ! Get the simulation state.
    stateVector=simulationState%get()
    ! Scale the state vector.
    stateVectorPacked=pack(stateVector,self%included)/self%rootVariance
    ! Search for nearest neighbors.
    call self%searcher%search(stateVectorPacked,self%neighborCount,self%tolerance,self%neighborIndices,self%neighborDistances)
    ! Evaluate kernel density estimate of log-prior.
    kernelScale=self%neighborDistances(self%neighborCount)
    weight=0.0d0
    do i=1,self%neighborCount
       weight=weight+exp(-0.5d0*self%neighborDistances(i)/kernelScale)
    end do
    posteriorAsPriorEvaluate=                                                  &
         & +self%logPriorNormalization                                         &
         & +log(weight)                                                        &
         & -0.5d0                                                              &
         & *dble(self%dimCount)                                                &
         & *log(2.0d0*Pi*kernelScale)                                          &
         & +self%posteriorSampleLikelihood_%evaluate(                          &
         &                                           simulationState         , &
         &                                           modelParametersActive_  , &
         &                                           modelParametersInactive_, &
         &                                           simulationConvergence   , &
         &                                           temperature             , &
         &                                           logLikelihoodCurrent    , &
         &                                           logPriorCurrent         , &
         &                                           logPriorProposed        , &
         &                                           timeEvaluate            , &
         &                                           logLikelihoodVariance     &
         &                                          )
    return
  end function posteriorAsPriorEvaluate

  subroutine posteriorAsPriorFunctionChanged(self)
    !% Respond to possible changes in the likelihood function.
    implicit none
    class(posteriorSampleLikelihoodPosteriorAsPrior), intent(inout) :: self
    !GCC$ attributes unused :: self

    return
  end subroutine posteriorAsPriorFunctionChanged
