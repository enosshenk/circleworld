class CircleWorldItemProjectile_LobberBounce extends CircleWorldItemProjectile;

var bool IsArmed;
var bool RandomizeVector;
var float RandomFactor;
var SoundCue BounceSound;

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
	local Rotator TempRot;
	
	if (CircleWorld_LevelBase(Other) != none || CircleWorldItem_Lift(Other) != none || CircleWorldItem_Door(Other) != none)
	{
		// Get a rotator set up the same as our polar coordinate angular
		TempRot.Pitch = LocationPolar.Y;
		
		// Figure out if we hit a floor
		if (Normal(Location - HitLocation) Dot Vector(TempRot) < 0)
		{
			// Bounce
			ProjectileVelocity.Z *= -1;
			PlaySound(BounceSound);
		}
		else
		{
			Explode(HitLocation, HitNormal);
		}
	}
	else if ((Pawn(Other) != none || CircleWorldEnemyPawn(Other) != none) && IsArmed)
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
	ProjectileUseGravity = true
	ProjectileGravityFactor = 3
	ProjectileLife = 12
	ProjectileSpeed = 210
	ProjectileDamage = 99
	ProjectileDamageRadius = 999
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.fireball'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.lobber_exp1'
	
	ExplosionSound = SoundCue'TheCircleWorld.Sounds.explosionfireball'
	BounceSound = SoundCue'TheCircleWorld.Sounds.bouncey1'
	
	DecalMat = DecalMaterial'TheCircleWorld.Decals.blueglow'

	//FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
}