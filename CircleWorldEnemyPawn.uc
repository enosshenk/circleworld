class CircleWorldEnemyPawn extends Pawn
	placeable;

var bool EnemyPawnWalking;							// True if this enemy pawn is "moving"
var float EnemyPawnVelocity;						// Out simulated velocity on the cylinder
var bool ObstructedForward;							// True if we're bumped into a wall
var bool HoleForward;								// True if we detect a hole in the floor ahead of us

var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
	
event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	

	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
	`log("Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local vector TraceStart, TraceEnd, HitLocation, HitNormal, TraceExtent;
	local actor HitActor;

	// Trace for holes in the floor ahead of us.
	TraceStart = Location;
	TraceStart.Z -= 64;
	TraceEnd = TraceStart;
	TraceEnd.Z -= Mesh.Bounds.BoxExtent.Z * 2;
	
	if (Rotation.Yaw == 0)
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.Z * 2;
	}
	else
	{
		TraceEnd.X -= Mesh.Bounds.BoxExtent.Z * 2;
	}
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0, false);	
		
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		HoleForward = false;
	}
	else
	{
		HoleForward = true;
	}
	
	// Set up some trace extents
	TraceExtent.X = 64;
	TraceExtent.Y = 64;	
	
	// Trace in our direction of motion. This is used to detect if the pawn is colliding with a wall.
	TraceEnd = Location;
	if (Rotation.Yaw == 0)
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.X;
		TraceStart = Location + vect(64,0,0);
	}
	else
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.X * -1;
		TraceStart = Location + vect(-64,0,0);
	}
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0, false);
		
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, TraceExtent);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		// Trace hit the level mesh.
		ObstructedForward = true;
	}
	else
	{
		ObstructedForward = false;
	}
	
	// We're bumping a wall or a hole. Null our fake velocity until the AIController can reverse us.
	if (ObstructedForward || HoleForward)
		EnemyPawnVelocity = 0;
	
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
	
	super.Tick(DeltaTime);
}

event TickSpecial( float DeltaTime )
{
	local rotator NewRotation;
	
	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	NewRotation.Pitch = LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
	SetRotation(NewRotation);
//	`log("Setting New Rotation: " $NewRotation);
}

function SetEnemyPawnVelocity(float NewSpeed)
{
	local Rotator TempRot;
	
	ObstructedForward = false;
	EnemyPawnVelocity = NewSpeed;
	TempRot = Rotation;
	
	if (NewSpeed > 0)
	{
		TempRot.Yaw = 32768;
		SetRotation(TempRot);
	}
	else
	{
		TempRot.Yaw = 0;
		SetRotation(TempRot);
	}
	`log("Enemy pawn speed set to " $NewSpeed);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local CircleWorldItem_Emitter DeathSystem;
	
	DeathSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (DeathSystem != none)
	{
		DeathSystem.ParticleSystemComponent.SetTemplate(ParticleSystem'CircleWorld.bloodexplosion_ps');
		DeathSystem.ParticleSystemComponent.ActivateSystem();
	}	
	SetHidden(true);
	super.Died(Killer, DamageType, HitLocation);
}
	
defaultproperties
{
	GroundSpeed = 100
	ControllerClass = class'CircleWorldAIController_BackForth'
	WalkingPhysics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=true
	bScriptTickSpecial=true
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=74.000000
		CollisionHeight=128.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)


	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'Rock.snail'
		AnimTreeTemplate=AnimTree'CircleWorld.snail_tree'
		AnimSets(0)=AnimSet'Rock.snail_anim'
		PhysicsAsset = PhysicsAsset'Rock.snail_Physics'
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