class CircleWorldEnemyPawn extends Pawn
	abstract;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;

var bool EnemyPawnWalking;							// True if this enemy pawn is "moving"
var bool EnemyPawnMovingRight;						// True if we're moving right
var float EnemyPawnVelocity;						// Out simulated velocity on the cylinder
var bool ObstructedForward;							// True if we're bumped into a wall
var bool HoleForward;								// True if we detect a hole in the floor ahead of us
var bool CanDamagePlayer;							// If true, damage player on touch
var float PlayerDamage;								// Amount of damage to cause to the player on touch

var ParticleSystem DeathParticleSystem;				// PS to use when killed
var name HurtAnimationName;							// Animation Sequence to play when hurt
var name AttackAnimationName;						// AnimSequence to play when we touch the player and do damage
var AnimNodeSlot PriorityAnimSlot;					// Ref to our priority anim slot

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
	
	// If we're blocked, set our speed to 0 until the AIController catches up
	if (ObstructedForward || HoleForward)
	{
		EnemyPawnVelocity = 0;
	}
	
	// Flag us for motion
	if (Abs(EnemyPawnVelocity) >= 15)
		EnemyPawnWalking = true;
	else
		EnemyPawnWalking = false;
		
	// Modify our initial polar to simulate movement.
	InitialLocationPolar.Y += EnemyPawnVelocity / 50;	
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	NewRotation.Pitch = LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
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
		Other.TakeDamage(PlayerDamage, Controller, HitLocation, vect(0,0,0), class'DamageType');
		
		// Start a timer to prevent instant re-damage
		CanDamagePlayer = false;
		SetTimer(0.4, false, 'SetDamagePlayer');
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
		EnemyPawnMovingRight = true;
		TempRot.Yaw = 32768;
		SetRotation(TempRot);
	}
	else if (NewSpeed < 0)
	{
		EnemyPawnMovingRight = false;
		TempRot.Yaw = 0;
		SetRotation(TempRot);
	}
	
	EnemyPawnVelocity = NewSpeed;
	
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Play a hurt animation
	PriorityAnimSlot.PlayCustomAnimByDuration(HurtAnimationName, 0.4, 0.1, 0.1, false, true);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local CircleWorldItem_Emitter DeathSystem;
	
	// Spawn and activate a particle system for death
	DeathSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (DeathSystem != none)
	{
		DeathSystem.ParticleSystemComponent.SetTemplate(DeathParticleSystem);
		DeathSystem.ParticleSystemComponent.ActivateSystem();
	}	
	
	return super.Died(Killer, DamageType, HitLocation);
}

simulated function SetViewRotation(rotator NewRotation);
simulated function FaceRotation(rotator NewRotation, float DeltaTime);
function UpdateControllerOnPossess(bool bVehicleTransition);
// Null this shit