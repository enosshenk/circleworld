class CircleWorldEnemyPawn extends Actor
	abstract;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;

var	CylinderComponent CylinderComponent;
var() SkeletalMeshComponent	Mesh;
var() float WaitTime;								// Time in seconds to wait before reversing direction after we get obstructed
var() float EnemyPawnGroundSpeed;					// Speed we should walk at
var() float Health;									// Current health
var() float HealthMax;								// Max health
var() enum EStartDirection
{
	D_Left,
	D_Right
} StartDirection;									// Initial direction

var bool EnemyPawnWalking;							// True if this enemy pawn is "moving"
var int EnemyPawnDirection;							// -1 for moving left, 1 for moving right
var float EnemyPawnVelocity;						// Our simulated velocity on the cylinder
var float ElapsedWaitTime;
var bool ObstructedForward;							// True if we're bumped into a wall
var bool HoleForward;								// True if we detect a hole in the floor ahead of us
var bool CanDamagePlayer;							// If true, damage player on touch
var float PlayerDamage;								// Amount of damage to cause to the player on touch

var ParticleSystem DeathParticleSystem;				// PS to use when killed
var name HurtAnimationName;							// Animation Sequence to play when hurt
var name AttackAnimationName;						// AnimSequence to play when we touch the player and do damage
var AnimNodeSlot PriorityAnimSlot;					// Ref to our priority anim slot

var SoundCue HurtSound;								// Sound to play when hurt
var SoundCue DeathSound;							// Sound to play when we die
var SoundCue AttackSound;							// Sound when we attack

var MaterialInterface DeathDecal;					// Decal to drop on ground when we die
var float DeathDecalSize;

var bool PlayedDeath;

var float DeathHideDelay;							// How long our corpse should remain before hiding it

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	
	
	InitialLocation = Location;
	
	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
	`log("Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;

	// Set initial facing
	if (StartDirection == D_Left)
	{
		EnemyPawnDirection = -1;
		// Start moving
		SetEnemyPawnVelocity(EnemyPawnGroundSpeed * -1);
	}
	else
	{
		EnemyPawnDirection = 1;
		// Start moving
		SetEnemyPawnVelocity(EnemyPawnGroundSpeed);
	}
	
	
	super.PostBeginPlay();
}

	
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	local vector TraceStart, TraceEnd, TraceExtent, TempVector;

	if (Health > 0)
	{
		// Trace for holes in the floor ahead of us.
		TraceStart = Location;
		TraceEnd = Location;
		
		TempVector.X = Mesh.Bounds.BoxExtent.X * 2;
		TempVector.Z = Mesh.Bounds.BoxExtent.Z * 2;
		TraceStart += TempVector >> Rotation;
		
		TempVector.X = Mesh.Bounds.BoxExtent.X * 2;
		TempVector.Z = Mesh.Bounds.BoxExtent.Z * 3 * -1;
		TraceEnd += TempVector >> Rotation;	
			
		if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
			DrawDebugLine(TraceStart, TraceEnd, 255, 255, 0, false);	
			
		if (FastTrace(TraceEnd, TraceStart))
		{
			// Trace hit no level geometry
			HoleForward = true;
		}
		else
		{
			HoleForward = false;
		}
		
		// Set up some trace extents
		TraceExtent.X = 32;
		TraceExtent.Y = 32;	
		
		// Trace in our direction of motion. This is used to detect if the pawn is colliding with a wall.
		TraceStart = Location;
		TraceEnd = Location;

		TempVector.X = Mesh.Bounds.BoxExtent.X / 2;
		TempVector.Z = Mesh.Bounds.BoxExtent.Z * 2;
		TraceStart += TempVector >> Rotation;
		
		TempVector.X = Mesh.Bounds.BoxExtent.X * 2;
		TempVector.Z = Mesh.Bounds.BoxExtent.Z * 2;
		TraceEnd += TempVector >> Rotation;
		
		if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
			DrawDebugLine(TraceStart, TraceEnd, 255, 255, 0, false);
			
		if (FastTrace(TraceEnd, TraceStart, TraceExtent))
		{
			// Trace did not hit the level mesh.
			ObstructedForward = false;
		}
		else
		{
			ObstructedForward = true;
		}
		
		// If we're blocked, set our speed to 0
		if (ObstructedForward || HoleForward)
		{
			EnemyPawnVelocity = 0;
		}
		
		// Flag us for motion
		if (Abs(EnemyPawnVelocity) >= 15)
			EnemyPawnWalking = true;
		else
			EnemyPawnWalking = false;
	}
	
	if (!ObstructedForward && !HoleForward)
	{
		// Modify our initial polar to simulate movement.
		InitialLocationPolar.Y += EnemyPawnVelocity / 50;
	}
	else
	{
		// We're blocked, update the wait timer
		ElapsedWaitTime += DeltaTime;
		if (ElapsedWaitTime >= WaitTime)
		{
			// Time is up, reverse direction
			if (EnemyPawnDirection == 1)
			{
				// Move left
				SetEnemyPawnVelocity(EnemyPawnGroundSpeed * -1);
			}
			else if (EnemyPawnDirection == -1)
			{
				// Move right
				SetEnemyPawnVelocity(EnemyPawnGroundSpeed);
			}
		}
	}
	
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	if (EnemyPawnDirection == 1)
	{
		NewRotation.Pitch = (LocationPolar.Y - 16384) * -1;
	}
	else
	{
		NewRotation.Pitch = LocationPolar.Y - 16384;
	}
	SetRotation(NewRotation);
	
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldPawn(Other) != none && CanDamagePlayer && Health > 0)
	{
		// Bumped the player. Play attack animation.
		PriorityAnimSlot.PlayCustomAnimByDuration(AttackAnimationName, 0.4, 0.1, 0.1, false, true);
		
		// Damage the player
		Other.TakeDamage(PlayerDamage, Pawn(Other).Controller, HitLocation, vect(0,0,0), class'DamageType');
		
		// Start a timer to prevent instant re-damage
		CanDamagePlayer = false;
		SetTimer(0.4, false, 'SetDamagePlayer');
		
		// Play a sound
		PlaySound(AttackSound);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

function SetDamagePlayer()
{
	CanDamagePlayer = true;
}

function SetEnemyPawnVelocity(float NewSpeed)
{
	local Rotator TempRot;
	
	ObstructedForward = false;
	HoleForward = false;
	TempRot = Rotation;
	
	if (NewSpeed > 0)
	{
		EnemyPawnDirection = 1;
		TempRot.Yaw = 32768;
		SetRotation(TempRot);
	}
	else if (NewSpeed < 0)
	{
		EnemyPawnDirection = -1;
		TempRot.Yaw = 0;
		SetRotation(TempRot);
	}
	
	EnemyPawnVelocity = NewSpeed;	
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Health -= Damage;
	if (HitLocation == vect(0,0,0))
	{
		HitLocation = Location;
	}

	if ( Health <= 0 )
	{
		Died(InstigatedBy, DamageType, HitLocation);
	}
	else
	{
		// Play a hurt animation
		PriorityAnimSlot.PlayCustomAnimByDuration(HurtAnimationName, 0.4, 0.1, 0.1, false, true);
		PlaySound(HurtSound);
	}
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function TakeRadiusDamage
(
	Controller			InstigatedBy,
	float				BaseDamage,
	float				DamageRadius,
	class<DamageType>	DamageType,
	float				Momentum,
	vector				HurtOrigin,
	bool				bFullDamage,
	Actor               DamageCauser,
	optional float      DamageFalloffExponent=1.f
)
{
	Health -= BaseDamage;
	if ( Health <= 0 )
	{
		Died(InstigatedBy, DamageType, Location);
	}
	else
	{
		// Play a hurt animation
		PriorityAnimSlot.PlayCustomAnimByDuration(HurtAnimationName, 0.4, 0.1, 0.1, false, true);
		PlaySound(HurtSound);
	}
	
	super.TakeRadiusDamage(InstigatedBy, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bFullDamage, DamageCauser, DamageFalloffExponent);
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
			DeathSystem.ParticleSystemComponent.SetTemplate(DeathParticleSystem);
			DeathSystem.ParticleSystemComponent.ActivateSystem();
		}

		PlaySound(DeathSound);
		
		// Spawn death decal if applicable
		if (DeathDecal != none)
		{
			DecalRot = Rotator(vect(0,0,0) - Location);
			CircleWorldGameInfo(WorldInfo.Game).CircleDecalManager.SpawnDecal(DeathDecal, Location, DecalRot, 20, DeathDecalSize);
		}
		
		SetTimer(DeathHideDelay, false, 'HideBody');
		
		SetCollision(false, false);
	}
}

function HideBody()
{
	Mesh.SetHidden(true);
}

defaultproperties
{
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0078.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
}