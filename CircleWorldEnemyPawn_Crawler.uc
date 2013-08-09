class CircleWorldEnemyPawn_Crawler extends CircleWorldEnemyPawn
	ClassGroup(CircleWorld)
	placeable;

defaultproperties
{
	Health = 50
	HealthMax = 50
	EnemyPawnGroundSpeed = 100
	Physics=PHYS_Interpolating
	bCollideActors=true
	CollisionType=COLLIDE_TouchAll
	bCollideWorld=false
	bBlockActors=false
	TickGroup=TG_PreAsyncWork
	
	PrePivot = (X=0, Y=0, Z=0)

	DeathParticleSystem = ParticleSystem'TheCircleWorld.FX.gore1'
	CanDamagePlayer = true 
	PlayerDamage = 10

	HurtAnimationName = hurt
	AttackAnimationName = attack

	Begin Object Name=CollisionCylinder
		CollisionRadius=128.000000
		CollisionHeight=64.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)



	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent		
		SkeletalMesh = SkeletalMesh'TheCircleWorld.Meshes.blobby1'
		AnimTreeTemplate = AnimTree'TheCircleWorld.AnimTree.blobby_tree'
		AnimSets(0) = AnimSet'TheCircleWorld.AnimSet.blobby_anim'
		PhysicsAsset = PhysicsAsset'TheCircleWorld.Meshes.blobby1_Physics'		
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