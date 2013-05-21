class CircleWorldExplosionLight extends Actor;

var UDKExplosionLight ExplosionLightComponent;
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;

	SetPhysics(PHYS_Rotating);
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	

	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
	`log("ExpLight Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);
	
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