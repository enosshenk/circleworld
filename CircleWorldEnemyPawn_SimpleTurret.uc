class CircleWorldEnemyPawn_SimpleTurret extends Actor
	placeable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;

var() StaticMeshComponent Mesh;						// Mesh used for this turret. Using static because they're very simple.
var() float Health;									// Current health
var() float HealthMax;								// Max health
var() vector FirePoint;								// A relative vector describing where the projectiles are spawned
var() rotator FireDirection;						// An offset applied to the fire direction
var() float MaxRange;								// Range at which this turret begins to fire at player
var() float ShotsPerSalvo;							// How many projectiles are fired per salvo
var() float FireSpeed;								// Time in seconds between salvo shots
var() float SalvoWaitTime;							// Time in seconds between salvos of shots
var() float OverrideDamage;							// If set to non-zero, projectile damage will be overridden with this value
var() class<CircleWorldItemProjectile> TurretProjectile;		// Projectile class this turret shoots at the player
var() ParticleSystem DeathParticleSystem;				// PS to use when killed

// Internal vars
var float DistanceToPlayer;							// Actual UU distance from turret to player
var bool ShouldFire;								// True if we should be shooting
var bool IsFiringSalvo;								// True if a salvo fire is in progress
var float FireTimeElapsed;
var float SalvoTimeElapsed;
var float ShotsFiredElapsed;

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	
	
	InitialLocation = Location;
	InitialRotation = Rotation;
	
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
	local float TempFloat;
	
	// Do our movement code first
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

	// Set new rotation based on our polar angular value
	NewRotation.Pitch = (InitialRotation.Pitch + LocationPolar.Y) - 16384;
	SetRotation(NewRotation);
	
	// Do fire procedures
	// First do range check
	if (!ShouldFire && !IsFiringSalvo && Health > 0)
	{
		// Update range to player
		TempFloat = CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location.Z - LocationPolar.X;
		DistanceToPlayer = VSize(Location - CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location);
		
		if (DistanceToPlayer <= MaxRange && (TempFloat > -50 || TempFloat < 50))
		{
			ShouldFire = true;
		}
	}
	
	if (ShouldFire && IsFiringSalvo && Health > 0)
	{
		// Continue firing salvo until shots are expired
		// Update range to player
		TempFloat = CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location.Z - LocationPolar.X;
		DistanceToPlayer = VSize(Location - CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location);
		
		if (DistanceToPlayer <= MaxRange && (TempFloat > -50 || TempFloat < 50))
		{
			FireTimeElapsed += DeltaTime;
			if (FireTimeElapsed >= FireSpeed)
			{
				FireTimeElapsed = 0;
				ShotsFiredElapsed += 1;
				if (ShotsFiredElapsed == ShotsPerSalvo + 1)
				{
					// Done with this salvo
					ShotsFiredElapsed = 0;
					IsFiringSalvo = false;
				}
				else
				{
					FireProjectile();
				}
			}
		}
		else
		{
			ShouldFire = false;
		}
	}
	
	if (ShouldFire && !IsFiringSalvo && Health > 0)
	{
		// Update range to player
		TempFloat = CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location.Z - LocationPolar.X;
		DistanceToPlayer = VSize(Location - CircleWorldGameInfo(WorldInfo.Game).CirclePawn.Location);
		
		if (DistanceToPlayer <= MaxRange && (TempFloat > -50 || TempFloat < 50))
		{
			// Update between salvo timer
			SalvoTimeElapsed += DeltaTime;
			if (SalvoTimeElapsed >= SalvoWaitTime)
			{
				// Timer is expired, fire salvo
				IsFiringSalvo = true;
				SalvoTimeElapsed = 0;
			}
		}
		else
		{
			ShouldFire = false;
		}
	}
	
	if (!ShouldFire && IsFiringSalvo && Health > 0)
	{
		// We should stop firing, but we need to finish this salvo before stopping
		FireTimeElapsed += DeltaTime;
		if (FireTimeElapsed >= FireSpeed)
		{
			FireTimeElapsed = 0;
			ShotsFiredElapsed += 1;
			if (ShotsFiredElapsed == ShotsPerSalvo + 1)
			{
				// Done with this salvo
				ShotsFiredElapsed = 0;
				IsFiringSalvo = false;
			}
			else
			{
				FireProjectile();
			}
		}		
	}
	
	super.Tick(DeltaTime);
}

function FireProjectile()
{
	local CircleWorldItemProjectile Projectile;
	local vector ProjectileLocation;
	local rotator ProjectileRotation;
	
	ProjectileRotation = InitialRotation;
	ProjectileRotation.Pitch -= 16384;
	ProjectileRotation += FireDirection * -1;
	
	ProjectileLocation = Location;
	ProjectileLocation += FirePoint >> Rotation;
	
	Projectile = spawn(TurretProjectile, self, , ProjectileLocation, ProjectileRotation, , true);
	if (Projectile != none)
	{
		// Init the projectile
		Projectile.InitProjectile(ProjectileRotation, 0);
		// Override damage if desired
		if (OverrideDamage != 0)
		{
			Projectile.ProjectileDamage = OverrideDamage;
		}
	}
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Health -= Damage;
	if (HitLocation == vect(0,0,0))
	{
		HitLocation = Location;
	}

	if ( Health <= 0 )
	{
		Died(InstigatedBy, DamageType, HitLocation);
	}
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function TakeRadiusDamage
(
	Controller			InstigatedBy,
	float				BaseDamage,
	float				DamageRadius,
	class<DamageType>	DamageType,
	float				Momentum,
	vector				HurtOrigin,
	bool				bFullDamage,
	Actor               DamageCauser,
	optional float      DamageFalloffExponent=1.f
)
{
	Health -= BaseDamage;
	if ( Health <= 0 )
	{
		Died(InstigatedBy, DamageType, Location);
	}
	
	super.TakeRadiusDamage(InstigatedBy, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bFullDamage, DamageCauser, DamageFalloffExponent);
}

function Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local CircleWorldItem_Emitter DeathSystem;
	
	// Spawn and activate a particle system for death
	DeathSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (DeathSystem != none)
	{
		DeathSystem.ParticleSystemComponent.SetTemplate(DeathParticleSystem);
		DeathSystem.ParticleSystemComponent.ActivateSystem();
	}	
	// Make sure we stop shooting shit
	ShouldFire = false;
	IsFiringSalvo = false;
	// Hide mesh
	SetHidden(true);
}

defaultproperties
{
	Health = 20
	HealthMax = 20
	FirePoint = (X=0,Y=0,Z=96)
	MaxRange = 4096
	ShotsPerSalvo = 3
	FireSpeed = 0.5
	SalvoWaitTime = 5
	
	TurretProjectile = class'CircleWorldItemProjectile_TurretBall'
	DeathParticleSystem = ParticleSystem'TheCircleWorld.FX.EnemyPawn_exp1'
	
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'TheCircleWorld.Pawns.TurretSimple1'
		bUsePrecomputedShadows=FALSE
	End Object
	CollisionComponent=StaticMeshComponent0
	Mesh=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}