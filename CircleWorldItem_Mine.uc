class CircleWorldItem_Mine extends Actor
	notplaceable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;
var rotator InitialLevelRot;

var float MineTimeout;
var float MineTimeoutElapsed;
var float MineDamage;
var float MineDamageRadius;
var class<DamageType> MineDamageType;

var ParticleSystemComponent ParticleSystemComponent;	// Particles running while idle
var ParticleSystem ExplosionSystem;		// Particle system used for explosion
var class<CircleWorldProjectileLight> BaseLightClass;	// Class of light attached while idle
var class<CircleWorldExplosionLight> ExplosionLightClass;	// Class to be spawned when this mine explodes

var CircleWorldItem_Emitter PooledExplosionSystem;	// Ref for the explosion effects
var CircleWorldProjectileLight FlightLight;		// Refs to the lights
var CircleWorldExplosionLight ExplosionLight;	
var SoundCue ExplosionSound;
	
event PostBeginPlay()
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
	
	SetCollisionType(COLLIDE_TouchAll);

	// Spawn flight light if applicable
	if (BaseLightClass != none)
	{
		FlightLight = spawn(BaseLightClass, self, , Location, Rotation);
		AttachComponent(FlightLight.LightComponent);
	}
	
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldEnemyPawn(Other) != none)
	{
		// Touched by enemy, explode and do damage.
		Explode(Location);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	

function Explode(vector HitLocation)
{
	// Spawn in our explosion system
	PooledExplosionSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (PooledExplosionSystem != none)
	{
		PooledExplosionSystem.ParticleSystemComponent.SetTemplate(ExplosionSystem);
		PooledExplosionSystem.ParticleSystemComponent.ActivateSystem();
	}
	
	// Spawn explosion light if applicable
	if (ExplosionLightClass != none)
	{
		ExplosionLight = spawn(ExplosionLightClass, self, , Location, Rotation);
	}
	
	// Damage radius!
	HurtRadius(MineDamage, MineDamageRadius, MineDamageType, 0, Location);
	
	// Play sound
	PlaySound(ExplosionSound);
	
	self.Destroy();
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
	
	// Check mine time to see if we should time out
	MineTimeoutElapsed += DeltaTime;
	
	if (MineTimeoutElapsed >= MineTimeout)
	{
		// Mine timed out
		self.Destroy();
	}
	
	super.Tick(DeltaTime);
}
	
defaultproperties
{
	MineTimeout = 120
	MineDamage = 300
	MineDamageRadius = 2000
	MineDamageType = class'DamageType'


	ExplosionSystem=ParticleSystem'TheCircleWorld.FX.nuke'

	BaseLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'  
	
	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionfireball'
	
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=64.000000
		CollisionHeight=64.000000
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
		Template=ParticleSystem'TheCircleWorld.FX.laser2'
	End Object
	ParticleSystemComponent=ParticleSystemComponent0
	Components.Add(ParticleSystemComponent0)
}