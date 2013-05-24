class CircleWorldItem extends Actor
	abstract;

var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	
	SetCollisionType(COLLIDE_TouchAll);
	SetPhysics(PHYS_Rotating);
	
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
	local rotator NewRotation;
	
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

defaultproperties
{
	bNoDelete = false
	bStatic = false
	bCollideComplex = true
	CollisionType = COLLIDE_TouchAll
}