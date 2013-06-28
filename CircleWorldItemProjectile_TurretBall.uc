class CircleWorldItemProjectile_TurretBall extends CircleWorldItemProjectile;

var bool IsArmed;
var float RandomFactor;

event PostBeginPlay()
{
	SetTimer(0.1, false, 'SetArm');
	RandomFactor = FRand();
	ProjectileSpeed = ProjectileSpeed + (RandomFactor * 3);
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (IsArmed && CircleWorldEnemyPawn_Turret(Other) == none && CircleWorldEnemyPawn_SimpleTurret(Other) == none)
	{
		`log("Projectile " $self$ " impacted " $Other);
		Explode(Location);
	}
}

function SetArm()
{
	IsArmed = true;
}

defaultproperties
{
	ProjectileUseGravity = false
	ProjectileGravityFactor = 2
	ProjectileLife = 10
	ProjectileSpeed = 200
	ProjectileDamage = 50
	ProjectileDamageRadius = 256
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	
	ProjectileParticleSystem=ParticleSystem'CircleTurret.fireball_ps'
	ProjectileExplosionSystem=ParticleSystem'CircleTurret.explosion_ps'
	
	FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}