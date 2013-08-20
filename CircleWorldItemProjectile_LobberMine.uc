class CircleWorldItemProjectile_LobberMine extends CircleWorldItemProjectile;

var bool IsArmed;
var bool RandomizeVector;
var float RandomFactor;

event PostBeginPlay()
{
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
	if ((Pawn(Other) != none || CircleWorldEnemyPawn(Other) != none) && CircleWorldPawn(Other) == none)
	{
		// Shot landed on a pawn that isn't the player. Deal damage and don't spawn the mine.
		Other.TakeDamage(ProjectileDamage, Pawn(Other).Controller, HitLocation, vect(0,0,0), ProjectileDamageType);
		Explode(HitLocation, HitNormal);
	}
	else if (Other.bWorldGeometry == true && CircleWorldItem_Lift(Other) == none)
	{
		// Shot hit world geometry but not a lift. Spawn the mine class and destroy ourselves
		`log("Trying to spawn mine");
		spawn(class'CircleWorldItem_Mine', self, , Location, Rotation);
		self.Destroy();
	}
}


defaultproperties
{
	ProjectileUseGravity = true
	ProjectileGravityFactor = 3
	ProjectileLife = 12
	ProjectileSpeed = 300
	ProjectileDamage = 99
	ProjectileDamageRadius = 300
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'TheCircleWorld.FX.fireball'
	ProjectileExplosionSystem=ParticleSystem'TheCircleWorld.FX.lobber_exp1'

	FlightLightClass = class'CircleWorldProjectileLight'
	ExplosionLightClass = class'CircleWorldExplosionLight'
	
	DecalMat = Material'TheCircleWorld.Decals.fireball_decal'
}