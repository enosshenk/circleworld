class CircleWorldEnemyPawn_Turret extends Pawn
	ClassGroup(CircleWorld)
	placeable;

var SkelControlLookAt RingAim;						// Skelcontrol for our rotation
var SkelControlLookAt GunAim;						// Skelcontrol for our ascension
var CircleWorldPawn PlayerTarget;					// The player character
var bool IsAiming;									// If true, use skelcontrols to aim at the player

var float TurretRange;								// Range at which this turret will begin to fire on the player
var float TurretAimRange;							// Range at which this turret will use skelcontrols to lock onto the player
var float TurretFireRate;							// Delay in seconds between shots
var float TurretSkill;								// 1.0 = perfect aim, 0 = degraded aim
var class<CircleWorldItemProjectile> TurretProjectile;		// Projectile class this turret shoots at the player
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;

var ParticleSystem DeathParticleSystem;				// PS to use when killed
var name HurtAnimationName;							// Animation Sequence to play when hurt
var name DeathAnimationName;						// AnimSequence to play when killed
var AnimNodeSlot PriorityAnimSlot;					// Ref to our priority anim slot

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	local CircleWorldPawn P;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	

	foreach WorldInfo.AllActors(class'CircleWorldPawn', P)
	{
		PlayerTarget = P;
	}	
	
	InitialLocation = Location;
	InitialRotation = Rotation;
	
	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
	`log("Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	super.PostBeginPlay();
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill refs to our skelcontrols for aiming
	RingAim = SkelControlLookAt(Mesh.FindSkelControl('RingControl'));
	GunAim = SkelControlLookAt(Mesh.FindSkelControl('GunControl'));
	
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	
	// See if we should be aiming at the player
	if (IsAiming)
	{
		// Set our skelcontrols to aim
		RingAim.SetTargetLocation(PlayerTarget.Location);
		RingAim.InterpolateTargetLocation(1);
		GunAim.SetTargetLocation(PlayerTarget.Location);
		GunAim.InterpolateTargetLocation(1);
	}

	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);

	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	NewRotation.Pitch = (InitialRotation.Pitch + LocationPolar.Y) - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
	SetRotation(NewRotation);
	
	super.Tick(DeltaTime);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local CircleWorldItem_Emitter DeathSystem;
	
	DeathSystem = spawn(class'CircleWorldItem_Emitter', self, , HitLocation, self.Rotation);
	if (DeathSystem != none)
	{
		DeathSystem.ParticleSystemComponent.SetTemplate(DeathParticleSystem);
		DeathSystem.ParticleSystemComponent.ActivateSystem();
	}	
	
	// Play death animation
	PriorityAnimSlot.PlayCustomAnimByDuration(DeathAnimationName, 0.4, 0.1, 0.1, false, true);
	
	return super.Died(Killer, DamageType, HitLocation);
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Play a hurt animation
	PriorityAnimSlot.PlayCustomAnimByDuration(HurtAnimationName, 0.4, 0.1, 0.1, false, true);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

function ShootAtPlayer()
{
	local CircleWorldItemProjectile Projectile;
	local vector ProjectileLocation;
	local rotator ProjectileRotation;
	
	// First get our shoot location from the skelmesh socket
	Mesh.GetSocketWorldLocationAndRotation('FireSocket', ProjectileLocation);
	// Get rotation for the projectile
	ProjectileRotation = Rotator(Normal(PlayerTarget.Location - ProjectileLocation));
	ProjectileRotation += (RotRand() * 0.2) * (1.0 - TurretSkill);
	// Spawn the murderball
	Projectile = spawn(TurretProjectile, self, , ProjectileLocation, ProjectileRotation, , true);
	if (Projectile != none)
	{
		// Init the projectile
		Projectile.InitProjectile(ProjectileRotation, 0);
	}
}

function FindPlayer()
{
	local CircleWorldPawn P;	
	
	foreach WorldInfo.AllActors(class'CircleWorldPawn', P)
	{
		PlayerTarget = P;
	}	
}

simulated function SetViewRotation(rotator NewRotation);
simulated function FaceRotation(rotator NewRotation, float DeltaTime);
function UpdateControllerOnPossess(bool bVehicleTransition);
// Null this shit
	
defaultproperties
{
	TurretRange = 2048
	TurretAimRange = 4096
	TurretFireRate = 1
	TurretSkill = 0.75
	TurretProjectile = class'CircleWorldItemProjectile_TurretBall'

	DeathParticleSystem = ParticleSystem'CircleWorld.bloodexplosion_ps'		
	
	HurtAnimationName = hurt
	DeathAnimationName = death
	
	GroundSpeed = 0
	ControllerClass = class'CircleWorldAIController_Turret'
	Physics=PHYS_Interpolating
	WalkingPhysics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	bStationary=true
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=74.000000
		CollisionHeight=48.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)


	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'CircleTurret.Turret'
		AnimTreeTemplate = AnimTree'CircleTurret.Turret_Tree'
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
        BlockRigidBody=true
        CollideActors=true
        BlockZeroExtent=true
		BlockNonZeroExtent=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateSkelWhenNotRendered=FALSE
		bHasPhysicsAssetInstance=true
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
}