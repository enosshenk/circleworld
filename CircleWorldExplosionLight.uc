class CircleWorldExplosionLight extends Actor;

var UDKExplosionLight ExplosionLightComponent;
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

	// Set new rotation based on our polar angular value
	NewRotation = Rotation;

	NewRotation.Pitch = InitialRotation.Pitch + LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position

	SetRotation(NewRotation);
	
	super.Tick(DeltaTime);
}

function LightFinished(UDKExplosionLight Light)
{
	self.Destroy();
}

defaultproperties
{
	bNoDelete = false
	bStatic = false

	Begin Object Class=UDKExplosionLight Name=ExplosionLight0
		HighDetailFrameTime=+0.02
		Brightness=8
		Radius=256
		LightColor=(R=255,G=255,B=255,A=255)
		TimeShift=((StartTime=0.0,Radius=256,Brightness=16,LightColor=(R=255,G=255,B=255,A=255)),(StartTime=0.3,Radius=128,Brightness=8,LightColor=(R=255,G=255,B=128,A=255)),(StartTime=0.4,Radius=128,Brightness=0,LightColor=(R=255,G=255,B=64,A=255)))
		OnLightFinished = LightFinished
	End Object
	ExplosionLightComponent=ExplosionLight0
	Components.Add(ExplosionLight0) 	
}