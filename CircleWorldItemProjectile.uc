class CircleWorldItemProjectile extends DynamicSMActor
	notplaceable;

var	CylinderComponent CylinderComponent;
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var rotator InitialLevelRot;
var float ProjectileSpeed;
var float ProjectileLife;
var float ProjectileLifeElapsed;
var int TravelDirection;

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
	
	InitialLevelRot = LevelBase.Rotation;
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	
	if (ProjectileLifeElapsed >= ProjectileLife)
	{
		`log("Projectile " $self$ " timed out");
		self.Destroy();
	}
	else
	{
		InitialLocationPolar.Y += TravelDirection * ProjectileSpeed / 50;
		// Check the level base for rotation change
		LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;
		`log(TravelDirection$ " * " $ProjectileSpeed$ " = " $LocationPolar.Y);
		// Set new cartesian location based on our polar coordinates
		NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
		NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
		NewLocation.Y = Location.Y;
		SetLocation(NewLocation);
		
		// Set new rotation based on our polar angular value
		NewRotation = Rotation;
		NewRotation.Pitch = LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
		SetRotation(NewRotation);
	}
	
	ProjectileLifeElapsed += DeltaTime;
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorld_LevelBase(Other) != none)
	{
		// Hit level geometry
		`log("Projectile " $self$ " impacted " $Other);
		self.Destroy();
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	
	
defaultproperties
{
	ProjectileLife = 10
	ProjectileSpeed = 400
	
	bNoDelete = false
	bStatic = false
	bCollideComplex = true
	CollisionType = COLLIDE_TouchAll
	
	Begin Object class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+016.000000
		CollisionHeight=+032.000000
		HiddenGame=false
		bDrawNonColliding=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
	Begin Object Name=StaticMeshComponent0
		StaticMesh = StaticMesh'CircleWorld.circle_pickup'
		BlockZeroExtent=true
		CollideActors=true
		BlockActors=false
		BlockRigidBody=false
	End Object
}