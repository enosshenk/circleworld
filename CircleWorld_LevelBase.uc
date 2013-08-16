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

event PostBeginPlay()
{
	// Set up collision and physics
	SetCollisionType(COLLIDE_BlockAll);
	SetPhysics(PHYS_Rotating);
	RotationRate = rot(0,0,0);
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	// We update our rotation rate based on the pawn's fake velocity. Do some trig with it and figure out where the velocity vector takes us.
	RotationRate.Pitch = (ATan(PawnVelocity.X / PawnLocation.Z) * RadToUnrRot) * -1;
	
	// Update rotation value in gameinfo
	CircleWorldGameInfo(WorldInfo.Game).CircleLevelRotation = Rotation.Pitch;
	
	super.Tick(DeltaTime);
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