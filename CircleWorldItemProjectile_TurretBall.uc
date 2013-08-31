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
		Explode(HitLocation, LastLoc);
	}
}

function SetArm()
{
	IsArmed = true;
}

defaultproperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius=+048.000000
		CollisionHeight=+064.000000
		HiddenGame=false
		bDrawNonColliding=true
	End Object
	
	ProjectileUseGravity = false
	ProjectileGravityFactor = 3
	ProjectileLife = 6
	ProjectileSpeed = 600
	ProjectileDamage = 50
	ProjectileDamageRadius = 300
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'

	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.laser2'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.EnemyPawn_exp1'
	
	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionfireball'
	
	DecalMat = DecalMaterial'TheCircleWorld.Decals.blueglow'
	
	//FlightLightClass =  class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}