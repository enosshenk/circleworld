class CircleWorldItemProjectile_Lobber extends CircleWorldItemProjectile;

var bool IsArmed;
var bool RandomizeVector;
var float RandomFactor;

event PostBeginPlay()
{
	SetTimer(0.1, false, 'SetArm');
	RandomFactor = FRand();
	ProjectileSpeed = ProjectileSpeed + (RandomFactor * 3);
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	if (!RandomizeVector)
	{
		ProjectileVelocity.X += RandomFactor * 3;
		ProjectileVelocity.Y += RandomFactor * 3;
		RandomizeVector = true;
	}
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (IsArmed && Pawn(Other) != none)
	{
		Other.TakeDamage(ProjectileDamage, Pawn(Other).Controller, HitLocation, vect(0,0,0), ProjectileDamageType);
		Explode(Location);
	}
	else if (IsArmed && CanExplode(Other))
	{
		Explode(Location);
	}
}

function SetArm()
{
	IsArmed = true;
}

defaultproperties
{
	ProjectileUseGravity = true
	ProjectileGravityFactor = 2
	ProjectileLife = 10
	ProjectileSpeed = 150
	ProjectileDamage = 50
	ProjectileDamageRadius = 512
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'CircleWorld.fireball_ps'
	ProjectileExplosionSystem=ParticleSystem'CircleTurret.explosion_ps'
	
	FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}