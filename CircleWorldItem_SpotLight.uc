class CircleWorldItem_SpotLight extends SpotLightMovable
	ClassGroup(CircleWorld)
	placeable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;
var rotator InitialLevelRot;

simulated event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	SetPhysics(PHYS_Rotating);
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	
	
	InitialLocation = Location;

	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
//	`log("Emitter Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
//	`log("Emitter Initial Cartesian: " $InitialLocation);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	InitialRotation = Rotation;
	
	InitialLevelRot = LevelBase.Rotation;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	
	// Check the level base for rotation change
	LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

//	`log("Emitter Polar: R" $LocationPolar.X$ " A" $LocationPolar.Y);
//	`log("Emitter Cartesian: " $NewLocation);
	
	// Set new rotation based on our polar angular value
	NewRotation = Rotation;

	NewRotation.Pitch = InitialRotation.Pitch + LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position

	SetRotation(NewRotation);
	
	super.Tick(DeltaTime);
}

defaultproperties
{
	bNoDelete = false
	bStatic = false
}
