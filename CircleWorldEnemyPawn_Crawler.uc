class CircleWorldEnemyPawn_Crawler extends CircleWorldEnemyPawn
	ClassGroup(CircleWorld)
	placeable;

var ParticleSystem StompDeathParticleSystem;
var SoundCue StompDeathSound;
var DecalMaterial StompDeathDecal;
var name StompDeathAnimationName;

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldPawn(Other) != none && Normal(Other.Velocity) dot Normal(Location - Other.Location) >= 0.5)
	{
		// Player landed on us from above. Take a large amount of damage and flag that we were stomped
		self.TakeDamage(500, Pawn(Other).Controller, Other.Location, Other.Velocity, class'CircleWorldDamageType_Stomp');
		Stomped = true;
		// Bump player up
		Pawn(Other).SetPhysics(PHYS_Falling);
		Pawn(Other).Velocity.Z = Pawn(Other).JumpZ;
	}
	else
	{	
		super.Touch(Other, OtherComp, HitLocation, HitNormal);
	}
}

function Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local CircleWorldItem_Emitter DeathSystem;
	local rotator DecalRot;

	if (!PlayedDeath)
	{	
		CanDamagePlayer = false;
		EnemyPawnVelocity = 0;
		
		// Spawn and activate a particle system for death
		DeathSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
		if (DeathSystem != none)
		{
			if (DamageType == class'CircleWorldDamageType_Stomp')
			{
				DeathSystem.ParticleSystemComponent.SetTemplate(StompDeathParticleSystem);
				DeathSystem.ParticleSystemComponent.ActivateSystem();	
				PlaySound(StompDeathSound);
			}
			else
			{
				DeathSystem.ParticleSystemComponent.SetTemplate(DeathParticleSystem);
				DeathSystem.ParticleSystemComponent.ActivateSystem();
				PlaySound(DeathSound);
			}
		}
		
		// Spawn death decal if applicable
		if (DeathDecal != none)
		{
			if (DamageType == class'CircleWorldDamageType_Stomp')
			{
				DecalRot = Rotator(vect(0,0,0) - Location);
				CircleWorldGameInfo(WorldInfo.Game).CircleDecalManager.SpawnDecal(StompDeathDecal, Location, DecalRot, 20, DeathDecalSize);		
			}
			else
			{
				DecalRot = Rotator(vect(0,0,0) - Location);
				CircleWorldGameInfo(WorldInfo.Game).CircleDecalManager.SpawnDecal(DeathDecal, Location, DecalRot, 20, DeathDecalSize);
			}
		}
		
		SetTimer(DeathHideDelay, false, 'HideBody');
		
		SetCollision(false, false);
	}
}
	
defaultproperties
{
	Health = 50
	HealthMax = 50
	EnemyPawnGroundSpeed = 100
	Physics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	TickGroup=TG_PreAsyncWork
	
	PrePivot = (X=0, Y=0, Z=0)

	DeathParticleSystem = ParticleSystem'TheCircleWorld.FX.gore1'
	CanDamagePlayer = true 
	PlayerDamage = 10
	DeathHideDelay = 5

	HurtAnimationName = hurt
	AttackAnimationName = attack
	
	HurtSound = SoundCue'TheCircleWorld.Sounds.blobbyhurt'
	DeathSound = SoundCue'TheCircleWorld.Sounds.blobbydeath'
	AttackSound = SoundCue'TheCircleWorld.Sounds.blobbysnarl'

	DeathDecal = DecalMaterial'CircleDecal.decal2_mat'
	DeathDecalSize = 512
	
	StompDeathParticleSystem = ParticleSystem'TheCircleWorld.fx.turret_exp1'
	StompDeathSound = SoundCue'TheCircleWorld.Sounds.Efoot2'
	StompDeathDecal = DecalMaterial'TheCircleWorld.Decals.fireball_decal'
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=128.000000
		CollisionHeight=64.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent		
		SkeletalMesh = SkeletalMesh'TheCircleWorld.Pawns.blobby1'
		AnimTreeTemplate = AnimTree'TheCircleWorld.AnimTree.blobby_tree'
		AnimSets(0) = AnimSet'TheCircleWorld.AnimSet.blobby_anim'
		PhysicsAsset = PhysicsAsset'TheCircleWorld.Pawns.blobby1_Physics'		
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
        BlockRigidBody=true
        CollideActors=true
        BlockZeroExtent=true
		BlockNonZeroExtent=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateSkelWhenNotRendered=FALSE
		bHasPhysicsAssetInstance=true
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
}