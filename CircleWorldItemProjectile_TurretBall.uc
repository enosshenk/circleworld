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
	ProjectileGravityFactor = 3
	ProjectileLife = 6
	ProjectileSpeed = 600
	ProjectileDamage = 50
	ProjectileDamageRadius = 300
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'

	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.laser2'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.turret_exp1'
	//FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}