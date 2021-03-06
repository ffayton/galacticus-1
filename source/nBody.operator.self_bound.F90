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

!% Contains a module which implements an N-body data operator which determines the subset of particles that are self-bound.

  use, intrinsic :: ISO_C_Binding           , only : c_size_t
  use            :: Numerical_Random_Numbers, only : randomNumberGeneratorClass

  !# <nbodyOperator name="nbodyOperatorSelfBound">
  !#  <description>An N-body data operator which determines the subset of particles that are self-bound.</description>
  !# </nbodyOperator>
  type, extends(nbodyOperatorClass) :: nbodyOperatorSelfBound
     !% An N-body data operator which determines the subset of particles that are self-bound.
     private
     class           (randomNumberGeneratorClass), pointer :: randomNumberGenerator_ => null()
     integer         (c_size_t                  )          :: bootstrapSampleCount
     double precision                                      :: tolerance                       , bootstrapSampleRate
     logical                                               :: analyzeAllParticles             , useVelocityMostBound
   contains
     final     ::            selfBoundDestructor
     procedure :: operate => selfBoundOperate
  end type nbodyOperatorSelfBound

  interface nbodyOperatorSelfBound
     !% Constructors for the ``selfBound'' N-body operator class.
     module procedure selfBoundConstructorParameters
     module procedure selfBoundConstructorInternal
  end interface nbodyOperatorSelfBound

contains

  function selfBoundConstructorParameters(parameters) result (self)
    !% Constructor for the ``selfBound'' N-body operator class which takes a parameter set as input.
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (nbodyOperatorSelfBound    )                :: self
    type            (inputParameters           ), intent(inout) :: parameters
    class           (randomNumberGeneratorClass), pointer       :: randomNumberGenerator_
    integer         (c_size_t                  )                :: bootstrapSampleCount
    double precision                                            :: tolerance           , bootstrapSampleRate
    logical                                                     :: analyzeAllParticles , useVelocityMostBound

    !# <inputParameter>
    !#   <name>bootstrapSampleCount</name>
    !#   <source>parameters</source>
    !#   <defaultValue>30_c_size_t</defaultValue>
    !#   <description>The number of bootstrap resamples of the particles that should be used.</description>
    !#   <type>integer</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>tolerance</name>
    !#   <source>parameters</source>
    !#   <defaultValue>1.0d-2</defaultValue>
    !#   <description>The tolerance in the summed weight of bound particles which must be attained to declare convergence.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>bootstrapSampleRate</name>
    !#   <source>parameters</source>
    !#   <defaultValue>1.0d0</defaultValue>
    !#   <description>The sampling rate for particles.</description>
    !#   <type>float</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>analyzeAllParticles</name>
    !#   <source>parameters</source>
    !#   <defaultValue>.true.</defaultValue>
    !#   <description>If true, all particles are assumed to be self-bound at the beginning of the analysis. Unbound particles at previous times are allowed to become bound in the current snapshot. If false and the self-bound information from the previous snapshot is available, only the particles that are self-bound at the previous snapshot are assumed to be bound at the begnning of the anlysis.</description>
    !#   <type>boolean</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <inputParameter>
    !#   <name>useVelocityMostBound</name>
    !#   <source>parameters</source>
    !#   <defaultValue>.false.</defaultValue>
    !#   <description>If true, the velocity of the most bound particle in velocity space is used as the representative velocity of the satellite. If false, use the mass weighted mean velocity (center-of-mass velocity) of self-bounf particles instead.</description>
    !#   <type>boolean</type>
    !#   <cardinality>0..1</cardinality>
    !# </inputParameter>
    !# <objectBuilder class="randomNumberGenerator" name="randomNumberGenerator_" source="parameters"/>
    self=nbodyOperatorSelfBound(tolerance,bootstrapSampleCount,bootstrapSampleRate,analyzeAllParticles,useVelocityMostBound,randomNumberGenerator_)
    !# <inputParametersValidate source="parameters"/>
    !# <objectDestructor name="randomNumberGenerator_"/>
    return
  end function selfBoundConstructorParameters

  function selfBoundConstructorInternal(tolerance,bootstrapSampleCount,bootstrapSampleRate,analyzeAllParticles,useVelocityMostBound,randomNumberGenerator_) result (self)
    !% Internal constructor for the ``selfBound'' N-body operator class
    implicit none
    type            (nbodyOperatorSelfBound    )                        :: self
    double precision                            , intent(in   )         :: tolerance             , bootstrapSampleRate
    integer         (c_size_t                  ), intent(in   )         :: bootstrapSampleCount
    logical                                     , intent(in   )         :: analyzeAllParticles   , useVelocityMostBound
    class           (randomNumberGeneratorClass), intent(in   ), target :: randomNumberGenerator_
    !# <constructorAssign variables="tolerance, bootstrapSampleCount, bootstrapSampleRate, analyzeAllParticles, useVelocityMostBound, *randomNumberGenerator_"/>

    return
  end function selfBoundConstructorInternal

  subroutine selfBoundDestructor(self)
    !% Destructor for the ``selfBound'' N-body operator class.
    implicit none
    type(nbodyOperatorSelfBound), intent(inout) :: self

    !# <objectDestructor name="self%randomNumberGenerator_"/>
    return
  end subroutine selfBoundDestructor
  
  subroutine selfBoundOperate(self,simulation)
    !% Determine the subset of N-body particles which are self-bound.
    use :: Galacticus_Display          , only : Galacticus_Display_Message
    use :: Galacticus_Error            , only : Galacticus_Error_Report
    use :: ISO_Varying_String          , only : varying_string
    use :: Memory_Management           , only : allocateArray                  , deallocateArray
    use :: Numerical_Constants_Physical, only : gravitationalConstantGalacticus
    implicit none
    class           (nbodyOperatorSelfBound), intent(inout)                          :: self
    type            (nBodyData             ), intent(inout)                          :: simulation
    integer                                 , parameter                              :: countIterationMaximum=30
    logical                                 , allocatable  , dimension(:,:)          :: isBound                 , isBoundNew             , &
         &                                                                              isBoundCompute          , isBoundComputeActual
    logical                                 , allocatable  , dimension(:  )          :: compute                 , computeActual
    integer                                 , allocatable  , dimension(:,:)          :: boundStatus
    double precision                        , allocatable  , dimension(:,:)          :: positionRelative        , positionOffset
    double precision                        , allocatable  , dimension(:  )          :: separation              , potential              , &
         &                                                                              separationSquared       , potentialActual
    double precision                        , allocatable  , dimension(:,:)          :: energyPotential         , velocityPotential      , &
         &                                                                              energyKinetic           , energyPotentialChange  , &
         &                                                                              velocityPotentialChange , sampleWeight
    double precision                        , allocatable  , dimension(:,:)          :: velocityCenterOfMass
    double precision                                       , dimension(3  )          :: velocityRepresentative
    integer         (c_size_t              ), allocatable  , dimension(:  )          :: indexMostBound          , indexVelocityMostBound
    integer         (c_size_t              )                                         :: particleCount           , i                      , &
         &                                                                              k                       , iSample
    integer         (c_size_t              ), allocatable  , dimension(:  )          :: countBound              , countBoundPrevious
    double precision                        , allocatable  , dimension(:  )          :: weightBound             , weightBoundPrevious
    logical                                 , allocatable  , dimension(:  )          :: isConverged
    logical                                                                          :: isPreviousSnapshotAvail
    integer                                                                          :: addSubtract             , countIteration
    type            (varying_string        )                                         :: message

    ! Allocate workspaces.
    particleCount=size(simulation%position,dim=2)
    call allocateArray(isBound                ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(isBoundNew             ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(isBoundCompute         ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(energyKinetic          ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(energyPotential        ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(velocityPotential      ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(compute                ,[           particleCount                          ])
    call allocateArray(energyPotentialChange  ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(velocityPotentialChange,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(sampleWeight           ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(velocityCenterOfMass   ,[3_c_size_t              ,self%bootstrapSampleCount])
    call allocateArray(positionOffset         ,[3_c_size_t,particleCount                          ])
    call allocateArray(boundStatus            ,[           particleCount,self%bootstrapSampleCount])
    call allocateArray(indexMostBound         ,[                         self%bootstrapSampleCount])
    call allocateArray(indexVelocityMostBound ,[                         self%bootstrapSampleCount])
    call allocateArray(countBound             ,[                         self%bootstrapSampleCount])
    call allocateArray(countBoundPrevious     ,[                         self%bootstrapSampleCount])
    call allocateArray(weightBound            ,[                         self%bootstrapSampleCount])
    call allocateArray(weightBoundPrevious    ,[                         self%bootstrapSampleCount])
    call allocateArray(isConverged            ,[                         self%bootstrapSampleCount])
    ! Iterate over bootstrap samplings.
    message='Performing self-bound analysis on bootstrap samples.'
    call Galacticus_Display_Message(message)
    isPreviousSnapshotAvail=.false.
    ! Check whether the self-bound status from the previous snapshot is available. If it is, read in the self-bound status
    ! and sanpling weights. If not, generate new values.
    if (allocated(simulation%boundStatusPrevious)) then
       ! Read in the self-bound status from the previous snapshot.
       isPreviousSnapshotAvail=.true.
       if (self%bootstrapSampleCount /= size(simulation%boundStatusPrevious,dim=2)) then
          call Galacticus_Error_Report('The number of bootstrap samples is not consistent with the previous snapshot.'//{introspection:location})
       end if
       !$omp parallel do private(i,k)
       do i=1,particleCount
          do k=1,particleCount
             if (simulation%ParticleIDs(i)==simulation%ParticleIDsPrevious(k)) then
                sampleWeight(i,:) = dble(simulation%sampleWeightPrevious(k,:))
                isBound     (i,:) =      simulation% boundStatusPrevious(k,:) > 0
             end if
          end do
       end do
       !$omp end parallel do
    else
       ! Generate new sampling weights.
       do iSample=1,self%bootstrapSampleCount
          ! Determine weights for particles.
          do i=1,particleCount
             sampleWeight(i,iSample)=dble(self%randomNumberGenerator_%poissonSample(self%bootstrapSampleRate))
          end do
          isBound(:,iSample)=sampleWeight(:,iSample) > 0.0d0
       end do
    end if
    compute=.false.
    do iSample=1,self%bootstrapSampleCount
       ! Initialize count of bound particles.
       countBoundPrevious (iSample)=count(                             isBound(:,iSample))
       weightBoundPrevious(iSample)=sum  (sampleWeight(:,iSample),mask=isBound(:,iSample))
       ! Compute the center-of-mass velocity.
       forall(k=1:3)
          velocityCenterOfMass(k,iSample)=sum(simulation%velocity(k,:)*sampleWeight(:,iSample),mask=isBound(:,iSample)) &
               &                          /weightBoundPrevious(iSample)
       end forall
       ! If the self-bound status from the previous snapshot is used, reset the self-boud status. All particles in the
       ! sample are assumed to be self-bound at the beginning of the first iteration.
       if (isPreviousSnapshotAvail .and. self%analyzeAllParticles) then
         isBound        (:,iSample)      =sampleWeight(:,iSample) > 0.0d0
       end if
       ! Initialize potentials.
       energyPotential  (:,iSample)      =0.0d0
       velocityPotential(:,iSample)      =0.0d0
       isBoundCompute   (:,iSample)      =             isBound(:,iSample)
       compute                           =compute .or. isBound(:,iSample)
    end do
    addSubtract =+1
    isConverged = .false.
    ! Begin iterations.
    countIteration=0
    do while (.true.)
       countIteration         =countIteration+1
       velocityPotentialChange=0.0d0
       energyPotentialChange  =0.0d0
       !$omp parallel private(i,k,positionRelative,separationSquared,separation,potential,potentialActual,computeActual,isBoundComputeActual,velocityRepresentative)
       call allocateArray(positionRelative    ,[3_c_size_t,particleCount                          ])
       call allocateArray(separation          ,[           particleCount                          ])
       call allocateArray(separationSquared   ,[           particleCount                          ])
       call allocateArray(potential           ,[           particleCount                          ])
       call allocateArray(potentialActual     ,[           particleCount                          ])
       call allocateArray(computeActual       ,[           particleCount                          ])
       call allocateArray(isBoundComputeActual,[           particleCount,self%bootstrapSampleCount])
       separation       =0.0d0
       separationSquared=0.0d0
       positionRelative =0.0d0
       potential        =0.0d0
       potentialActual  =0.0d0
       !$omp do schedule(dynamic) reduction(+: energyPotentialChange, velocityPotentialChange)
       do i=1,particleCount-1
          ! Skip particles we do not need to compute.
          if (.not.compute(i)) cycle
          ! Check how to accumulate changes to potentials.
          if (addSubtract == +1) then
             ! Recomute potentials for all self-bound partiles.
             computeActual        = compute
             isBoundComputeActual = isBoundCompute
          else
             ! Subtract potentials due to particles which are marked as unbound in the previous iteration.
             computeActual = .false.
             do iSample=1,self%bootstrapSampleCount
                where(isBoundCompute(:,iSample))
                   isBoundComputeActual(:,iSample) = isBound(:,iSample) .neqv. isBound(i,iSample)
                else where
                   isBoundComputeActual(:,iSample) = .false.
                end where
                computeActual = computeActual .or. isBoundComputeActual(:,iSample)
             end do
          end if
          ! Compute "potentials" in velocity space in order to find a particle which best represents the velocity of the particles.
          ! Find particle velocity separations.
          forall(k=1:3)
             where(computeActual(i+1:particleCount))
                positionRelative(k,i+1:particleCount)=+simulation%velocity(k,i+1:particleCount) &
                     &                                -simulation%velocity(k,i                )
             end where
          end forall
          where(computeActual(i+1:particleCount))
             separationSquared(i+1:particleCount)=+sum (positionRelative (:,i+1:particleCount)**2,dim=1)
             separation       (i+1:particleCount)=+sqrt(separationSquared(  i+1:particleCount)         )
             ! Compute potentials.
             potential        (i+1:particleCount)=+selfBoundPotential(                                      &
                  &                                                   separation       (i+1:particleCount), &
                  &                                                   separationSquared(i+1:particleCount)  &
                  &                                                  )
          elsewhere
             ! For particles not participating in this computation, set potential to zero.
             potential        (i+1:particleCount)=0.0d0
          end where
          do iSample=1,self%bootstrapSampleCount
             ! Skip bootstrap samples for which we have already got converged results.
             if (isConverged(iSample)) cycle
             if (isBoundCompute(i,iSample)) then
                ! Compute "potentials" needed in the analysis of a particular sample.
                where(isBoundComputeActual(i+1:particleCount,iSample))
                   potentialActual(i+1:particleCount) = potential(i+1:particleCount)
                else where
                   potentialActual(i+1:particleCount) = 0.0d0
                end where
                ! Accumulate potential energy.
                velocityPotentialChange(i                ,iSample)=+velocityPotentialChange(i                ,iSample)                             &
                     &                                             +sum(potentialActual(i+1:particleCount)*sampleWeight(i+1:particleCount,iSample))
                velocityPotentialChange(i+1:particleCount,iSample)=+velocityPotentialChange(i+1:particleCount,iSample)                             &
                     &                                             +    potentialActual(i+1:particleCount)*sampleWeight(i                ,iSample)
             end if
          end do
          ! Compute gravitational potential energies.
          ! Find particle separations.
          forall(k=1:3)
             where(computeActual(i+1:particleCount))
                positionRelative(k,i+1:particleCount)=+simulation%position(k,i+1:particleCount) &
                     &                                -simulation%position(k,i                )
             end where
          end forall
          where(computeActual(i+1:particleCount))
             separationSquared(i+1:particleCount)=+sum (positionRelative (:,i+1:particleCount)**2,dim=1) &
                  &                               /simulation%lengthSoftening**2
             separation       (i+1:particleCount)=+sqrt(separationSquared(  i+1:particleCount)         )
             ! Compute potentials.
             potential        (i+1:particleCount)=+selfBoundPotential(                                      &
                  &                                                   separation       (i+1:particleCount), &
                  &                                                   separationSquared(i+1:particleCount)  &
                  &                                                  )
          elsewhere
             ! For particles not participating in this computation, set potential to zero.
             potential        (i+1:particleCount)=0.0d0
          end where
          do iSample=1,self%bootstrapSampleCount
             ! Skip bootstrap samples for which we have already got converged results.
             if (isConverged(iSample)) cycle
             if (isBoundCompute(i,iSample)) then
                ! Compute potentials needed in the analysis of a particular sample.
                where(isBoundComputeActual(i+1:particleCount,iSample))
                   potentialActual(i+1:particleCount) = potential(i+1:particleCount)
                else where
                   potentialActual(i+1:particleCount) = 0.0d0
                end where
                ! Accumulate potential energy.
                energyPotentialChange(i                ,iSample)=+energyPotentialChange(i                ,iSample)                               &
                     &                                           +sum(potentialActual(i+1:particleCount)*sampleWeight(i+1:particleCount,iSample))
                energyPotentialChange(i+1:particleCount,iSample)=+energyPotentialChange(i+1:particleCount,iSample)                               &
                     &                                           +    potentialActual(i+1:particleCount)*sampleWeight(i                ,iSample)
             end if
          end do
       end do
       !$omp end do
       !$omp workshare
       ! Apply constant multipliers to potential energy.
       where(isBoundCompute)
          energyPotentialChange=+energyPotentialChange                                     &
               &                *gravitationalConstantGalacticus                           &
               &                *simulation%massParticle                                   &
               &                /self%bootstrapSampleRate                                  &
               &                /simulation%lengthSoftening                                &
               &                * dble(particleCount)                                      &
               &                /(dble(particleCount-1_c_size_t)-self%bootstrapSampleRate)
       end where
       !$omp end workshare
       ! Accumulate changes to potentials.
       if (addSubtract == +1) then
          !$omp workshare
          where(isBoundCompute)
             energyPotential  =  energyPotential+  energyPotentialChange
             velocityPotential=velocityPotential+velocityPotentialChange
          end where
          !$omp end workshare
       else
          !$omp workshare
          where(isBoundCompute)
             energyPotential  =  energyPotential-  energyPotentialChange
             velocityPotential=velocityPotential-velocityPotentialChange
          end where
          !$omp end workshare
       end if
       do iSample=1,self%bootstrapSampleCount
          ! Skip bootstrap samples for which we have already got converged results.
          if (isConverged(iSample)) cycle
          !$omp workshare
          ! Find the index of the most bound particle.
          indexMostBound        (iSample) =minloc(energyPotential  (:,iSample),dim=1,mask=isBound(:,iSample))
          ! Find the index of the most bound particle in velocity space.
          indexVelocityMostBound(iSample) =minloc(velocityPotential(:,iSample),dim=1,mask=isBound(:,iSample))
          !$omp end workshare
          ! Check whether we should use the velocity of the most bound particle in velocity space as the
          ! representative velocity of the satellite. If not, use the center-of-mass velocity instead.
          if (self%useVelocityMostBound) then
             velocityRepresentative=simulation%velocity (:,indexVelocityMostBound(iSample))
          else
             velocityRepresentative=velocityCenterOfMass(:,iSample)
          end if
          !$omp workshare
          ! Compute kinetic energies.
          forall(k=1:3)
             where(isBound(:,iSample))
                positionOffset(k,:)=+simulation%velocity(k,:)-velocityRepresentative(k)
             end where
          end forall
          where(isBound(:,iSample))
             energyKinetic(:,iSample)=0.5d0*sum(positionOffset**2,dim=1)
          end where
          ! Determine which particles are bound.
          where (isBound(:,iSample))
             isBoundNew(:,iSample)=(energyKinetic(:,iSample)+energyPotential(:,iSample) < 0.0d0)
          elsewhere
             isBoundNew(:,iSample)=.false.
          end where
          ! Count bound particles.
          countBound (iSample)=count(                             isBoundNew(:,iSample))
          weightBound(iSample)=sum  (sampleWeight(:,iSample),mask=isBoundNew(:,iSample))
          ! Compute the center-of-mass velocity.
          forall(k=1:3)
             velocityCenterOfMass(k,iSample)=sum(simulation%velocity(k,:)*sampleWeight(:,iSample),mask=isBoundNew(:,iSample)) &
                  &                          /weightBound(iSample)
          end forall
          !$omp end workshare
       end do
       ! Free workspaces.
       call deallocateArray(positionRelative    )
       call deallocateArray(separation          )
       call deallocateArray(separationSquared   )
       call deallocateArray(potential           )
       call deallocateArray(potentialActual     )
       call deallocateArray(computeActual       )
       call deallocateArray(isBoundComputeActual)
       !$omp end parallel
       ! Decide if it is faster to recompute potentials fully for the new bound set, or to subtract potential due
       ! to particles which are now unbound.
       if (2*sum(countBoundPrevious-countBound) < sum(countBound+1)) then
          addSubtract   =-1
       else
          addSubtract   =+1
       end if
       ! Test for convergence.
       compute = .false.
       do iSample=1,self%bootstrapSampleCount
          if (abs(weightBound(iSample)-weightBoundPrevious(iSample)) < 0.5d0*self%tolerance                 &
               &                                                            *(                              &
               &                                                              +weightBound        (iSample) &
               &                                                              +weightBoundPrevious(iSample) &
               &                                                             )) then
             ! Converged.
             isBound       (:,iSample)=isBoundNew(:,iSample)
             isBoundCompute(:,iSample)=.false.
             isConverged   (  iSample)=.true.
          else
             ! Not converged.
             if (addSubtract==-1) then
                ! Number of particles that have become unbound is sufficiently small that it is faster to simply subtract off their
                ! contribution to the potential.
                compute                     =compute .or. isBound(:,iSample)
                isBoundCompute(:,iSample)   =             isBound(:,iSample)
             else
                ! Number of particles that have become unbound is sufficiently large that it will be faster to simply recompute
                ! potentials completely.
                compute                     =compute .or. isBoundNew(:,iSample)
                isBoundCompute(:,iSample)   =             isBoundNew(:,iSample)
                ! Reset potentials.
                energyPotential  (:,iSample)=0.0d0
                velocityPotential(:,iSample)=0.0d0
             end if
             ! Update bound status.
             isBound            (:,iSample)=isBoundNew (:,iSample)
             countBoundPrevious (  iSample)=countBound (  iSample)
             weightBoundPrevious(  iSample)=weightBound(  iSample)
          end if
          ! Check for excess iterations.
          if (countIteration > countIterationMaximum) call Galacticus_Error_Report('maximum iterations exceeded'//{introspection:location})
       end do
       if (count(isConverged)==self%bootstrapSampleCount) exit
    end do
    ! Write bound status to file.
    !$omp parallel workshare
    where (isBound)
       boundStatus=nint(sampleWeight)
    elsewhere
       boundStatus=0
    end where
    !$omp end parallel workshare
    ! Write indices of most bound particles to file.
    call simulation%analysis%writeDataset(indexMostBound        ,'indexMostBound'        )
    call simulation%analysis%writeDataset(indexVelocityMostBound,'indexVelocityMostBound')
    ! Write bound status to file.
    call simulation%analysis%writeDataset(boundStatus           ,'selfBoundStatus'       )
    call simulation%analysis%writeDataset(nint(sampleWeight)    ,'weight'                )
    ! Free workspaces.
    call deallocateArray(compute                )
    call deallocateArray(isBound                )
    call deallocateArray(isBoundNew             )
    call deallocateArray(isBoundCompute         )
    call deallocateArray(energyKinetic          )
    call deallocateArray(energyPotential        )
    call deallocateArray(velocityPotential      )
    call deallocateArray(boundStatus            )
    call deallocateArray(energyPotentialChange  )
    call deallocateArray(velocityPotentialChange)
    call deallocateArray(sampleWeight           )
    call deallocateArray(velocityCenterOfMass   )
    call deallocateArray(indexMostBound         )
    call deallocateArray(indexVelocityMostBound )
    call deallocateArray(positionOffset         )
    call deallocateArray(countBound             )
    call deallocateArray(countBoundPrevious     )
    call deallocateArray(weightBound            )
    call deallocateArray(weightBoundPrevious    )
    call deallocateArray(isConverged            )
    return
  end subroutine selfBoundOperate

  pure function selfBoundPotential(separation,separationSquared)
    !% Compute the potential for an array of particle separations. Currently assumes the functional form of the softening used by
    !% Gadget.
    implicit none
    double precision, intent(in   ), dimension(:               ) :: separation        , separationSquared
    double precision               , dimension(size(separation)) :: selfBoundPotential

    where     (separation == 0.0d0)
       selfBoundPotential=0.0d0 ! No self-energy.
    elsewhere (separation <= 0.5d0)
       selfBoundPotential=-14.0d0              &
            &             /5.0d0               &
            &             +separationSquared   &
            &             *(                   &
            &               +16.0d0            &
            &               /3.0d0             &
            &               +separationSquared &
            &               *(                 &
            &                 -48.0d0          &
            &                 / 5.0d0          &
            &                 +32.0d0          &
            &                 *separation      &
            &                 /5.0d0           &
            &                )                 &
            &              )
    elsewhere (separation <= 1.0d0)
       selfBoundPotential=-1.0d0                 &
            &             +(                     &
            &               +1.0d0               &
            &               +separation          &
            &               *(                   &
            &                 -33.0d0            &
            &                 +separationSquared &
            &                 *(                 &
            &                   +160.0d0         &
            &                   +separation      &
            &                   *(               &
            &                     -240.0d0       &
            &                     +separation    &
            &                     *(             &
            &                       +144.0d0     &
            &                       -32.0d0      &
            &                       *separation  &
            &                      )             &
            &                    )               &
            &                  )                 &
            &                )                   &
            &              )                     &
            &             /15.0d0                &
            &             /separation
    elsewhere
       selfBoundPotential=-1.0d0                &
            &             /separation
    end where
    return
  end function selfBoundPotential

