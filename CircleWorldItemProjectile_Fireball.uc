class CircleWorldItemProjectile_Fireball extends CircleWorldItemProjectile;

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
	if (CircleWorld_LevelBase(Other) != none)
	{
		if (HitLocation.Z < Location.Z + 1)
		{
			// Bounce
			ProjectileVelocity.Z *= -1;
		}
		else
		{
			Explode(Location);
		}
	}
	else if (CircleWorldPawn(Other) != none && IsArmed)
	{
		// You hit yourself, dumbass.
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
	ProjectileUseGravity = true
	ProjectileGravityFactor = 2
	ProjectileLife = 10
	ProjectileSpeed = 200
	ProjectileDamage = 50
	ProjectileDamageRadius = 512
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'CircleWorld.fireball_ps'
	ProjectileExplosionSystem=ParticleSystem'ScottPlosion.fx.ScottPlosion1'
}