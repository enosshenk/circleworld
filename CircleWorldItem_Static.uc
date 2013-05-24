class CircleWorldItem_Static extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;

var() StaticMeshComponent StaticMeshComponent;
	
defaultproperties
{
	CollisionType = COLLIDE_BlockAll

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'EngineMeshes.Cube'
	    BlockRigidBody=false
		bUsePrecomputedShadows=FALSE
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}