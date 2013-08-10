class CircleWorldPawn_Elephant extends Actor
	notplaceable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;

var() SkeletalMeshComponent	Mesh;
var AnimNodeSlot PriorityAnimSlot;
var int PawnFacing;									// 1 is facing right, -1 is facing left
var float GroundSpeed;
var bool PawnWalking;
var CircleWorldPawn PlayerPawn;

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
	local rotator NewRotation, TempRot;

	// Movement stuff here
	if (LocationPolar.Y < 16320)
	{
		// We need to move right to get to the player
		PawnWalking = true;
		PawnFacing = 1;
		TempRot.Yaw = 0;
		SetRotation(TempRot);
		InitialLocationPolar.Y += GroundSpeed / 50;
	}
	else if (LocationPolar.Y > 16448)
	{
		// We need to move left to get to the player
		PawnWalking = true;
		PawnFacing = -1;
		TempRot.Yaw = 32768;
		SetRotation(TempRot);
		InitialLocationPolar.Y -= GroundSpeed / 50;	
	}
	else
	{
		// No movement
		PawnWalking = false;
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
	if (PawnFacing == 1)
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

defaultproperties
{
	GroundSpeed = 100
	Physics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	TickGroup=TG_PreAsyncWork
	
	PrePivot = (X=0, Y=0, Z=-64)
	DrawScale3D = (X=3, Y=3, Z=3)

	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent		
		SkeletalMesh = SkeletalMesh'TheCircleWorld.Meshes.blobby1'
		AnimTreeTemplate = AnimTree'TheCircleWorld.blobby_tree2'
		AnimSets(0) = AnimSet'TheCircleWorld.AnimSet.blobby_anim'
		PhysicsAsset = PhysicsAsset'TheCircleWorld.Meshes.blobby1_Physics'		
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