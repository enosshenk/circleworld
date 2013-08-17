class CircleWorldDecal extends DecalActorBase
	notplaceable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;
var rotator InitialLevelRot;

var float DecalStayTime;
var float DecalTimeElapsed;

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
	
	// Update decal timer
	DecalTimeElapsed += DeltaTime;
	if (DecalTimeElapsed >= DecalStayTime)
	{
		// Time is up
		self.Destroy();
	}
	
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

function InitDecal(MaterialInterface Mat, float StayTime, float Radius)
{
	local float Width, Height;
	
	Width = Radius;
	Height = Radius;
	Width += (Radius * 0.2 * -1) + Rand(Radius * 0.2);
	Height += (Radius * 0.2 * -1) + Rand(Radius * 0.2);
	
	DecalStayTime = StayTime;
	DecalTimeElapsed = 0;

	Decal.SetDecalMaterial(Mat);
	Decal.Width = Width;
	Decal.Height = Height;
}

defaultproperties
{
	bNoDelete = false
	bStatic = false
	bMovable = true
	
	Begin Object Name=NewDecalComponent
		DecalTransform=DecalTransform_OwnerAbsolute
		bStaticDecal=false
		bMovableDecal=true
		bDecalMaterialSetAtRunTime=true
	End Object
	Decal=NewDecalComponent
	Components.Add(NewDecalComponent)
}