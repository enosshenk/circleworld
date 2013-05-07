class CircleWorldItemProjectile extends Actor
	notplaceable;

var	CylinderComponent CylinderComponent;
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var rotator InitialLevelRot;

var float ProjectileSpeed;
var float ProjectileDamage;
var float ProjectileDamageRadius;
var float ProjectileDamageMomentum;
var float ProjectileLife;
var float ProjectileLifeElapsed;
var int TravelDirection;
var class<DamageType> ProjectileDamageType;

var ParticleSystem ProjectileParticleSystem;
var ParticleSystem ProjectileExplosionSystem;

var ParticleSystemComponent PooledSystem;
var CircleWorldItem_Emitter PooledExplosionSystem;

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
//		`log(TravelDirection$ " * " $ProjectileSpeed$ " = " $LocationPolar.Y);
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
		Explode(HitLocation);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	

function Explode(vector HitLocation)
{
	PooledSystem.SetActive(false);
	
	PooledExplosionSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
//	`log("Exploding at Radial " $PooledExplosionSystem.LocationPolar.X$ " Angular " $PooledExplosionSystem.LocationPolar.Y);
	if (PooledExplosionSystem != none)
	{
		PooledExplosionSystem.ParticleSystemComponent.SetTemplate(ProjectileExplosionSystem);
		PooledExplosionSystem.ParticleSystemComponent.ActivateSystem();
	}
	
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
	ProjectileLife = 10
	ProjectileSpeed = 400
	ProjectileDamage = 50
	ProjectileDamageRadius = 1
	ProjectileDamageMomentum = 1
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'CircleWorld.projectiletest_ps'
	ProjectileExplosionSystem=ParticleSystem'CircleWorld.projectiletextexplosion_ps'
	
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