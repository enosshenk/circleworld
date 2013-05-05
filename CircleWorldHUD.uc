class CircleWorldHUD extends HUD;

var CircleWorldPawn CircleWorldPawn;
var CircleWorld_LevelBase LevelBase;
var array<CircleWorldItem> Pickups;
var Vector2D PlayerPos;

simulated function DrawHUD()
{
	local CircleWorld_LevelBase C;
	local CircleWorldPawn P;
	local vector ProjectLoc;
	local rotator MapRot;
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
		Canvas.DrawText("Pawn Properties - CirclePawnMoving: " $CircleWorldPawn.CirclePawnMoving$ " -- CirclePawnJumpUp: " $CircleWorldPawn.CirclePawnJumpUp$ " -- CirclePawnJumpDown: " $CircleWorldPawn.CirclePawnJumpDown$ " -- Rot: " $CircleWorldPawn.Rotation.Yaw$ " -- Z Velocity: " $CircleWorldPawn.Velocity.Z);
		
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
		
		MapRot.Yaw = LevelBase.Rotation.Pitch * -1;
		// Draw a white tile for a border
		Canvas.SetPos(Canvas.ClipX - 132, 0);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', 132, 132, 0, 0, 1, 1, MakeLinearColor(1,1,1,1));
		// Draw a fill tile for the map
		Canvas.SetPos(Canvas.ClipX - 130, 2);
		Canvas.DrawTile(Texture2D'EditorResources.Bkgnd', 128, 128, 0, 0, 64, 64, MakeLinearColor(1,1,1,1));
		// Draw the map
		Canvas.SetPos(Canvas.ClipX - 124, 6);
		Canvas.DrawColor = WhiteColor;
		Canvas.DrawRotatedTile(Texture2D'CircleWorld.Front', MapRot, 120, 120, 0, 0, 1024, 1024);
		// Figure out our position
		PlayerPos.X = Canvas.ClipX - 66;
		PlayerPos.Y = 66 - (CircleWorldPawn.Location.Z / (LevelBase.StaticMeshComponent.Bounds.SphereRadius / 62));
		// Draw position dot
		Canvas.SetPos(PlayerPos.X - 1, PlayerPos.Y - 1);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', 2, 2, 0, 0, 1, 1, MakeLinearColor(0,1,0,1));
	
	}
	
	super.DrawHUD();
}