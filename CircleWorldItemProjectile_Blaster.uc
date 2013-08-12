class CircleWorldItemProjectile_Blaster extends CircleWorldItemProjectile;

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
	if (IsArmed && (Pawn(Other) != none || CircleWorldEnemyPawn(Other) != none || CircleWorldEnemyPawn_Turret(Other) != none || CircleWorldEnemyPawn_SimpleTurret(Other) != none))
	{
		// We impacted another pawn directly. Do full damage then explode.
		Other.TakeDamage(ProjectileDamage, Pawn(Other).Controller, HitLocation, vect(0,0,0), ProjectileDamageType);
		Explode(Location);
	}
	else if (IsArmed && CanExplode(Other))
	{
		// We hit something else, just explode.
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
	ProjectileGravityFactor = 0
	ProjectileLife = 8
	ProjectileSpeed = 800
	ProjectileDamage = 15
	ProjectileDamageRadius = 196
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'

	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.laser1'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.blaster_exp1'

	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionlaser'
	
	// FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}