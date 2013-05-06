class CircleWorldItem_Coin extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;
	
event PostBeginPlay()
{
	local Rotator RotationRot;
	
	SetCollisionType(COLLIDE_TouchAll);
	SetPhysics(PHYS_Rotating);
	RotationRot.Yaw = 4551;
//	RotationRate = RotationRot;	
	
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldPawn(Other) != none)
	{
		// Touched by a player. Credit a coin and kill ourselves.
		CircleWorldGameInfo(WorldInfo.Game).CoinsCollected += 1;
		self.Destroy();
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	
	
defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh = StaticMesh'CircleWorld.coin'
	End Object
}