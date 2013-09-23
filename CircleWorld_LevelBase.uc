//
// !!! This object must be located at world origin X0 Z0 !!!
//

class CircleWorld_LevelBase extends Actor
	ClassGroup(CircleWorld)
	placeable;
	
var() StaticMeshComponent StaticMeshComponent;		// The static mesh used to represent the level world
var() float WorldRadius;							// Must be set! Radius from the center point of the world to the surface
var vector PawnVelocity;
var vector PawnLocation;
var rotator InitialRotation;
var array<CircleWorld_LevelBackground> LevelBackgrounds;	// Array of background items to rotate with the cylinder

event PostBeginPlay()
{
	local CircleWorld_LevelBackground B;
	
	// Set up collision and physics
	SetCollisionType(COLLIDE_BlockAll);
	SetPhysics(PHYS_Rotating);
	RotationRate = rot(0,0,0);
	InitialRotation = Rotation;
	
	// Fill the background items array with any LevelBackground actors
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBackground', B)
	{
		LevelBackgrounds.AddItem(B);
	}
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local CircleWorld_LevelBackground B;
	
	// We update our rotation rate based on the pawn's fake velocity. Do some trig with it and figure out where the velocity vector takes us.
	RotationRate.Pitch = (ATan(PawnVelocity.X / PawnLocation.Z) * RadToUnrRot) * -1;
	
	// Update rotation value in gameinfo
	CircleWorldGameInfo(WorldInfo.Game).CircleLevelRotation = Rotation.Pitch;

	// Send the data to any level background actors
	foreach LevelBackgrounds(B)
	{
		B.PawnVelocity = PawnVelocity;
		B.PawnLocation = PawnLocation;
	}	
	
	super.Tick(DeltaTime);
}

function ForceRotation(int newRotation)
{
	// Function to force the world to rotate to a specified rotation in Unreal Rotator units
	local rotator TempRot;
	TempRot = InitialRotation;
	
	TempRot.Pitch = newRotation;
	SetRotation(TempRot);
	`log("Forcing world rotation to " $newRotation);
}

defaultproperties
{
	bWorldGeometry = true
	bNoDelete = false
	bStatic = false
	bCollideComplex = true
	CollisionType = COLLIDE_BlockAll
	TickGroup=TG_PreAsyncWork
	
	Begin Object Class=StaticMeshComponent Name=CircleStaticMeshComponent
		BlockZeroExtent=true
		CollideActors=true
		BlockActors=true
		BlockRigidBody=true
		bAcceptsStaticDecals=TRUE
		bAcceptsDecals=TRUE
	End Object
	CollisionComponent=CircleStaticMeshComponent
	StaticMeshComponent=CircleStaticMeshComponent
	Components.Add(CircleStaticMeshComponent)
}