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
var vector LastLoc;

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
var SoundCue ExplosionSound;
var MaterialInterface DecalMat;
var bool HasExploded, ShouldExplode, ExplodeTrace;
var vector ShouldExplodeLoc;

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
	
	SetTimer(0.1, false, 'SetExplodeTrace');
	
	super.PostBeginPlay();
}

function InitProjectile(rotator NewRotation, float AddSpeed)
{
	local vector TempVelocity;
	local vector HitLocation, HitNormal, TraceEnd, TraceStart;
	local actor HitActor;
	
	// Add to our speed
	ProjectileSpeed += AddSpeed;
	
	TempVelocity.X = ProjectileSpeed;

	ProjectileVelocity = TempVelocity >> NewRotation;
	
	// Modify velocity by world radius
	if (InitialLocationPolar.X < LevelBase.WorldRadius)
	{
		ProjectileVelocity *= 2 - (InitialLocationPolar.X / LevelBase.WorldRadius);
	}
	
	// Check for immediate collision
	TraceStart = Location;
	TraceEnd = Location + (ProjectileVelocity / 10);
	
	HitActor = trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 255, 0, false);
	
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		Explode(HitLocation, Location);
	}	
	
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
		LastLoc = Location;
		
		// If we're simulating gravity, modify our velocity each frame
		if (ProjectileUseGravity)
		{
			ProjectileVelocity.Z = ProjectileVelocity.Z + (1 * ProjectileGravityFactor) * -1;
		}
		
		// Modify our initial polar with our fake velocity vector
		InitialLocationPolar.Y = InitialLocationPolar.Y + ((ProjectileVelocity.X * -1) * DeltaTime);
		InitialLocationPolar.X = InitialLocationPolar.X + (ProjectileVelocity.Z * DeltaTime);	
		
		// Check the level base for rotation change
		LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;
		// Set new cartesian location based on our polar coordinates
		NewLocation.Y = Location.Y;
		NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
		NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
		SetLocation(NewLocation);
		
		
		// Set new rotation based on our polar angular value, considering our launch angle
		NewRotation = Rotation;
		if (LocationPolar.Y > 16448)
		{
			NewRotation.Pitch = (LocationPolar.Y + ProjectileRotation.Pitch) * -1;
		}
		else
		{
			NewRotation.Pitch = (LocationPolar.Y + ProjectileRotation.Pitch) - 16384;
		}
		
		SetRotation(NewRotation);
		
		if (ShouldExplodeLoc != vect(0,0,0))
		{
			SetLocation(Location + ProjectileVelocity);
			Explode(Location, LastLoc);
		}		
		
		// Hacky collision check
		ShouldExplodeLoc = CheckExplosionTrace(DeltaTime);
		
		// Set real in-engine velocity to hopefully improve collision
		Velocity = ProjectileVelocity;
	}
	
	ProjectileLifeElapsed += DeltaTime;
	super.Tick(DeltaTime);
}

function vector CheckExplosionTrace(float DeltaTime)
{
	local vector TraceEnd, TraceStart, HitLocation, HitNormal;
	local actor HitActor;
	
	TraceStart = Location;
	TraceEnd = Location + (ProjectileVelocity * DeltaTime);
	
	HitActor = trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 255, 0, false);
	
	if (CircleWorld_LevelBase(HitActor) != none && ExplodeTrace)
	{
		return HitLocation;
	}
	
	return vect(0,0,0);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorld_LevelBase(Other) != none)
	{
		// Hit level geometry
		`log("Projectile " $self$ " impacted " $Other);
		Explode(HitLocation, LastLoc);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

function bool CanExplode(Actor Other)
{
	if (CircleWorld_LevelBase(Other) != none || CircleWorldItem_Lift(Other) != none || CircleWorldItem_Door(Other) != none || Pawn(Other) != none || CircleWorldEnemyPawn(Other) != none)
		return true;
	else
		return false;
}	

function Explode(vector HitLocation, vector HitNormal)
{
	local rotator DecalRot;
	
	if (!HasExploded)
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
			ExplosionLight = spawn(ExplosionLightClass, self, , Location, Rotation,, true);
		}
		
		// Spawn decal if applicable
		if (DecalMat != none)
		{
			DecalRot = Rotator(HitLocation - HitNormal);
			CircleWorldGameInfo(WorldInfo.Game).CircleDecalManager.SpawnDecal(DecalMat, Location, DecalRot, 10, ProjectileDamageRadius * 0.75);
//			TheDecal.InitDecal(DecalMat, 10, ProjectileDamageRadius * 0.75);
		}
		
		// Damage radius!
		HurtRadius(ProjectileDamage, ProjectileDamageRadius, ProjectileDamageType, ProjectileDamageMomentum, Location);
		
		// Play sound
		PlaySound(ExplosionSound);
		
		HasExploded = true;
		
		self.Destroy();
	}
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

function SetExplodeTrace()
{
	ExplodeTrace = true;
}
	
defaultproperties
{
	ProjectileUseGravity = false
	ProjectileGravityFactor = 1
	ProjectileLife = 10
	ProjectileSpeed = 800
	ProjectileDamage = 50
	ProjectileDamageRadius = 1
	ProjectileDamageMomentum = 1
	ProjectileDamageType = class'DamageType'
	
	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.laser2'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.lobber_exp1'
	
	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionlaser'
	
	TickGroup=TG_PreAsyncWork
	bNoDelete = false
	bStatic = false
	bCollideComplex = true
	CollisionType = COLLIDE_TouchAll
	
	Begin Object class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+048.000000
		CollisionHeight=+064.000000
		HiddenGame=false
		bDrawNonColliding=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
}