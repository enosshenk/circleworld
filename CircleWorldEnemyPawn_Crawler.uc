class CircleWorldEnemyPawn_Crawler extends CircleWorldEnemyPawn
	ClassGroup(CircleWorld)
	placeable;

defaultproperties
{
	GroundSpeed = 100
	ControllerClass = class'CircleWorldAIController_Crawler'
	Physics=PHYS_Interpolating
	WalkingPhysics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	TickGroup=TG_PreAsyncWork
	MaxPitchLimit=9999999

	DeathParticleSystem = ParticleSystem'CircleWorld.bloodexplosion_ps'		
	CanDamagePlayer = true	
	PlayerDamage = 10
	
	HurtAnimationName = hurt
	DeathAnimationName = death
	AttackAnimationName = attack
	
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
		
		SkeletalMesh = SkeletalMesh'cylmaster.Enemies.CRAWLER'
		AnimTreeTemplate = AnimTree'cylmaster.Enemies.crawler_tree'
		AnimSets(0) = AnimSet'cylmaster.Enemies.crawler-anim'
		PhysicsAsset = PhysicsAsset'cylmaster.Enemies.CRAWLER_Physics'
		
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