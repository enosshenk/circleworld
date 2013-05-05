class CircleWorldHUD extends HUD;

var CircleWorldPawn CircleWorldPawn;
var CircleWorld_LevelBase LevelBase;
var array<CircleWorldItem> Pickups;

simulated function DrawHUD()
{
	local CircleWorld_LevelBase C;
	local CircleWorldPawn P;
	local vector ProjectLoc;
	local CircleWorldItem PU;
	local int i;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', C)
	{
		LevelBase = C;
	}
	
	foreach WorldInfo.AllActors(class'CircleWorldPawn', P)
	{
		CircleWorldPawn = P;
	}
	
	foreach WorldInfo.AllActors(class'CircleWorldItem', PU)
	{
		Pickups[i] = PU;
		i += 1;
	}

	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
	{
		Canvas.DrawColor = RedColor;
		Canvas.Font = class'Engine'.Static.GetMediumFont();
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.1);	
		Canvas.DrawText("World Properties - CircleAcceleration: " $CircleWorldPawn.CircleAcceleration$ " -- CircleVelocity: " $CircleWorldPawn.CircleVelocity$ " -- Circle RotRate: " $LevelBase.RotationRate.Pitch * UnrRotToDeg$ " -- Circle Rotation: " $LevelBase.Rotation.Pitch);
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.15);	
		Canvas.DrawText("Pawn Properties - CirclePawnMoving: " $CircleWorldPawn.CirclePawnMoving$ " -- CirclePawnJumpUp: " $CircleWorldPawn.CirclePawnJumpUp$ " -- CirclePawnJumpDown: " $CircleWorldPawn.CirclePawnJumpDown$ " -- Physics: " $CircleWorldPawn.Physics$ " -- Z Velocity: " $CircleWorldPawn.Velocity.Z);
		
		foreach Pickups(PU)
		{
			ProjectLoc = Canvas.Project(PU.Location);
			Canvas.SetPos(ProjectLoc.X, ProjectLoc.Y);
			Canvas.DrawText("Polar Radial: " $PU.LocationPolar.X$ " Polar Angular(UR): " $PU.LocationPolar.Y$ " -- Bounds Diameter: " $PU.StaticMeshComponent.Bounds.SphereRadius);
		}
	}	
	else
	{
		Canvas.DrawColor = RedColor;
		Canvas.Font = class'Engine'.Static.GetMediumFont();
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.1);	
		Canvas.DrawText("Coins Collected: " $CircleWorldGameInfo(WorldInfo.Game).CoinsCollected);
	}
	
	super.DrawHUD();
}