class CircleWorldItemProjectile_Fireball extends CircleWorldItemProjectile;

var bool IsArmed;
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
	local vector NewLocation;
	local rotator NewRotation;
	
	if (ProjectileLifeElapsed >= ProjectileLife)
	{
		`log("Projectile " $self$ " timed out");
		Explode(Location);
	}
	else
	{
		if (ProjectileSpeed != 20)
		{
			ProjectileSpeed = Lerp(ProjectileSpeed, 20, 0.01);
		}
		InitialLocationPolar.Y += TravelDirection * ProjectileSpeed / 50;
		InitialLocationPolar.X = InitialLocationPolar.X + (50 + (RandomFactor * 2)) + (WorldInfo.DefaultGravityZ / 10);

		// Check the level base for rotation change
		LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;
//		`log(TravelDirection$ " * " $ProjectileSpeed$ " = " $LocationPolar.Y);
		// Set new cartesian location based on our polar coordinates
		NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
		NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
		NewLocation.Y = Location.Y;
		SetLocation(NewLocation);
		
		// Set new rotation based on our polar angular value
		NewRotation = Rotation;
		NewRotation.Pitch = LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
		SetRotation(NewRotation);
	}
	
	ProjectileLifeElapsed += DeltaTime;
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorld_LevelBase(Other) != none)
	{
		Explode(Location);
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
	ProjectileLife = 10
	ProjectileSpeed = 600
	ProjectileDamage = 50
	ProjectileDamageRadius = 512
	ProjectileDamageMomentum = 10
	ProjectileDamageType = class'DamageType'
	ProjectileParticleSystem=ParticleSystem'CircleWorld.fireball_ps'
	ProjectileExplosionSystem=ParticleSystem'ScottPlosion.fx.ScottPlosion1'
}