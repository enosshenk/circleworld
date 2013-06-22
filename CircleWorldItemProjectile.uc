class CircleWorldItemProjectile extends Actor
	notplaceable;

var	CylinderComponent CylinderComponent;			// Our collision cylinder
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector ProjectileVelocity;						// A fake velocity vector set at init time
var rotator ProjectileRotation;						// A fake rotator set at init time, determines our heading
var vector2d InitialLocationPolar;					// Initial polar coordinates generated from our spawn-in location
var vector2d LastLocationPolar;						// Last frame polar coordinates, used for gravity
var rotator InitialLevelRot;						// Initial rotation of the world cylinder set at spawn-in of this projectile

var bool ProjectileUseGravity;						// If true this projectile is affected by gravity
var float ProjectileGravityFactor;					// If UseGravity is on, scale by this value
var float ProjectileSpeed;							// Approx. speed this projectile travels per frame
var float ProjectileDamage;							// Damage done when projectile explodes
var float ProjectileDamageRadius;					// Radius of explosion
var float ProjectileDamageMomentum;					// Momentum scalar applied to damaged actors
var float ProjectileLife;							// Maximum lifetime of this projectile
var float ProjectileLifeElapsed;					// Current elapsed lifetime
var class<DamageType> ProjectileDamageType;			// Damagetype for explosion

var ParticleSystem ProjectileParticleSystem;		// Particle system used for flight effect
var ParticleSystem ProjectileExplosionSystem;		// Particle system used for explosion
var class<CircleWorldProjectileLight> FlightLightClass;	// Class of light attached for flight effects
var class<CircleWorldExplosionLight> ExplosionLightClass;	// Class to be spawned when this projectile explodes

var ParticleSystemComponent PooledSystem;			// Ref for the flight effects
var CircleWorldItem_Emitter PooledExplosionSystem;	// Ref for the explosion effects
var CircleWorldProjectileLight FlightLight;		// Refs to the lights
var CircleWorldExplosionLight ExplosionLight;	

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
	
	// Spawn our projectile system
	PooledSystem = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjectileParticleSystem);
	PooledSystem.SetAbsolute(false, false, false);
	PooledSystem.bUpdateComponentInTick = true;
	PooledSystem.OnSystemFinished = CircleOnSystemFinished;
	AttachComponent(PooledSystem);
	
	// Spawn flight light if applicable
	if (FlightLightClass != none)
	{
		FlightLight = spawn(FlightLightClass, self, , Location, Rotation);
		AttachComponent(FlightLight.LightComponent);
	}
	
	super.PostBeginPlay();
}

function InitProjectile(rotator NewRotation, float AddSpeed)
{
	local vector TempVelocity;
	
	// Add to our speed
	ProjectileSpeed += AddSpeed / 20;
		
	TempVelocity.X = ProjectileSpeed;

	ProjectileVelocity = TempVelocity >> NewRotation;
	`log("Init projectile rotator: " $NewRotation$ " -- velocity: " $ProjectileVelocity);
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
		// If we're simulating gravity, modify our velocity each frame
		if (ProjectileUseGravity)
		{
			ProjectileVelocity.Z = ProjectileVelocity.Z + (1 * ProjectileGravityFactor) * -1;
		}
		
		// Modify our initial polar with our fake velocity vector
		InitialLocationPolar.Y = InitialLocationPolar.Y + ((ProjectileVelocity.X * -1) / 10);
		InitialLocationPolar.X = InitialLocationPolar.X + (ProjectileVelocity.Z / 10);	
		
		// Check the level base for rotation change
		LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;
		// Set new cartesian location based on our polar coordinates
		NewLocation.Y = Location.Y;
		NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
		NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
		SetLocation(NewLocation);
		
		// Set new rotation based on our polar angular value, considering our launch angle
		NewRotation = Rotation;
		NewRotation.Pitch = (LocationPolar.Y + ProjectileRotation.Pitch) - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
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
		Explode(HitLocation);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

function bool CanExplode(Actor Other)
{
	if (CircleWorld_LevelBase(Other) != none || CircleWorldItem_Lift(Other) != none || CircleWorldItem_Door(Other) != none || Pawn(Other) != none)
		return true;
	else
		return false;
}	

function Explode(vector HitLocation)
{
	// Spawn in our explosion system
	PooledExplosionSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (PooledExplosionSystem != none)
	{
		PooledExplosionSystem.ParticleSystemComponent.SetTemplate(ProjectileExplosionSystem);
		PooledExplosionSystem.ParticleSystemComponent.ActivateSystem();
	}
	
	// Spawn explosion light if applicable
	if (ExplosionLightClass != none)
	{
		ExplosionLight = spawn(ExplosionLightClass, self, , Location, Rotation);
	}
	
	// Damage radius!
	HurtRadius(ProjectileDamage, ProjectileDamageRadius, ProjectileDamageType, ProjectileDamageMomentum, Location);
	
	self.Destroy();
}

function CircleOnSystemFinished(ParticleSystemComponent PSC)
{
	if (PSC == PooledSystem)
	{
		DetachComponent(PooledSystem);
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(PooledSystem);
		PooledSystem = none;
	}
}
	
defaultproperties
{
	ProjectileUseGravity = false
	ProjectileGravityFactor = 1
	ProjectileLife = 10
	ProjectileSpeed = 100
	ProjectileDamage = 50
	ProjectileDamageRadius = 1
	ProjectileDamageMomentum = 1
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'CircleWorld.projectiletest_ps'
	ProjectileExplosionSystem=ParticleSystem'CircleWorld.projectiletextexplosion_ps'
	
	TickGroup=TG_PreAsyncWork
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
}