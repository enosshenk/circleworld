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
	if (IsArmed && (Pawn(Other) != none || CircleWorldEnemyPawn(Other) != none))
	{
		Other.TakeDamage(ProjectileDamage, Pawn(Other).Controller, HitLocation, vect(0,0,0), ProjectileDamageType);
		Explode(HitLocation, LastLoc);
	}
	else if (IsArmed && CanExplode(Other))
	{
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
	
	ProjectileUseGravity = true
	ProjectileGravityFactor = 3
	ProjectileLife = 12
	ProjectileSpeed = 300
	ProjectileDamage = 99
	ProjectileDamageRadius = 1500
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'CircleWorldDamageType_Lobber'
	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.fireball'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.lobber_exp1'
	
	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionfireball'
	
	DecalMat = DecalMaterial'TheCircleWorld.Decals.blueglow'


	FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}