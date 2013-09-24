class CircleWorldPawn_Elephant extends Actor
	notplaceable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var float InitialRadial;
var vector InitialLocation;

var() SkeletalMeshComponent	Mesh;
var AnimNodeSlot PriorityAnimSlot;
var int PawnFacing;									// 1 is facing right, -1 is facing left
var int PawnFacingLast;
var bool IsTurning;
var float TurnTime;
var name TurnAnim;
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
	
	InitialRadial = InitialLocationPolar.X;
	
	super.PostBeginPlay();
}

	
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

event Tick(float DeltaTime)
{
	local vector NewLocation, TraceStart, TraceEnd, HitLocation, HitNormal;
	local rotator NewRotation, TempRot;
	local actor HitActor;

	// Movement stuff here
	if (LocationPolar.Y < 16320)
	{
		// We need to move right to get to the player
		PawnFacing = 1;
		
		if (PawnFacing != PawnFacingLast && !IsTurning)
		{
			IsTurning = true;
			SetTimer(TurnTime, false, 'ResetTurning');
			PriorityAnimSlot.PlayCustomAnim(TurnAnim, 1, 0.1, 0.1, false, true);			
		}
		
		if (!IsTurning)
		{
			PawnWalking = true;			
			TempRot.Yaw = 0;
			SetRotation(TempRot);
			InitialLocationPolar.Y += GroundSpeed / 50;
		}
		PawnFacingLast = 1;
	}
	else if (LocationPolar.Y > 16448)
	{
		// We need to move left to get to the player
		PawnFacing = -1;

		if (PawnFacing != PawnFacingLast && !IsTurning)
		{
			IsTurning = true;
			SetTimer(TurnTime, false, 'ResetTurning');
			PriorityAnimSlot.PlayCustomAnim(TurnAnim, 1, 0.1, 0.1, false, true);			
		}
		
		if (!IsTurning)
		{
			PawnWalking = true;			
			TempRot.Yaw = 32768;
			SetRotation(TempRot);
			InitialLocationPolar.Y -= GroundSpeed / 50;	
		}
		PawnFacingLast = -1;
	}
	else
	{
		// No movement
		PawnWalking = false;
	}	
	
	// Adjust height to ground
	TraceStart.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	TraceStart.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	TraceStart.Y = Location.Y;
	TraceEnd = Location;
	TraceEnd += vect(0,0,-2048) >> NewRotation;
	
//	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
//		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0, true);	

	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		// Trace hit level mesh, adjust polar radial to drop the elephant to ground level
		LocationPolar.X = InitialLocationPolar.X - VSize(TraceStart - HitLocation);
	}
	
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = LocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = LocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	if (PawnFacing == -1)
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

function ResetTurning()
{
	IsTurning = false;
}

defaultproperties
{
	GroundSpeed = 80
	Physics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	TickGroup=TG_PreAsyncWork
	
	TurnTime = 0.5
	TurnAnim = elephant_turn
	
	
	PrePivot = (X=0, Y=0, Z=-64)

	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent		
        SkeletalMesh = SkeletalMesh'TheCircleWorld.Player.elephant1'
        AnimTreeTemplate = AnimTree'TheCircleWorld.Animtree.elephant1_tree'
        AnimSets(0) = AnimSet'TheCircleWorld.AnimSet.elephant1_anim'
        PhysicsAsset = PhysicsAsset'TheCircleWorld.Player.elephant1_Physics'  	
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
		AbsoluteScale = true
		Scale3D = (X=24, Y=24, Z=24)
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent)
}