//
// !!! This object must be located at world origin X0 Z0 !!!
//

class CircleWorld_LevelBackground extends Actor
	placeable;
	
var() StaticMeshComponent StaticMeshComponent;		// The static mesh used to represent the level world
var vector PawnVelocity;
var vector PawnLocation;
var() float BackgroundScale;						// Scaling factor applied to this meshes rotation

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
	RotationRate.Pitch = (ATan(PawnVelocity.X / PawnLocation.Z) * RadToUnrRot * BackgroundScale);
	super.Tick(DeltaTime);
}

defaultproperties
{
	BackgroundScale = 1
	
	bWorldGeometry = true
	bNoDelete = false
	bStatic = false
	bCollideComplex = false
	CollisionType = COLLIDE_BlockAll
	
	Begin Object Class=StaticMeshComponent Name=CircleStaticMeshComponent
		StaticMesh = StaticMesh'CircleWorld.circle_pickup';
		BlockZeroExtent=false
		CollideActors=false
		BlockActors=false
		BlockRigidBody=false
	End Object
	CollisionComponent=CircleStaticMeshComponent
	StaticMeshComponent=CircleStaticMeshComponent
	Components.Add(CircleStaticMeshComponent)
}