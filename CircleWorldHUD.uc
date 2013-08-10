class CircleWorldHUD extends HUD;

var CircleWorldPawn CircleWorldPawn;
var CircleWorld_LevelBase LevelBase;
var array<CircleWorldEnemyPawn_Turret> Turrets;
var array<CircleWorldEnemyPawn> Enemies;
var CircleWorldPawn_Elephant Elephant;
var Vector2D PlayerPos;

simulated function DrawHUD()
{
	local CircleWorld_LevelBase C;
	local CircleWorldPawn P;
	local vector ProjectLoc;
	local rotator MapRot;
	local CircleWorldEnemyPawn EP;
	local CircleWorldEnemyPawn_Turret T;
	local CircleWorldPawn_Elephant E;
	local int i;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', C)
	{
		LevelBase = C;
	}
	
	foreach WorldInfo.AllActors(class'CircleWorldPawn_Elephant', E)
	{
		Elephant = E;
	}
	
	foreach WorldInfo.AllActors(class'CircleWorldPawn', P)
	{
		CircleWorldPawn = P;
	}
	
	i = 0;
	foreach WorldInfo.AllActors(class'CircleWorldEnemyPawn', EP)
	{
		Enemies[i] = EP;
		i += 1;
	}

	i = 0;
	foreach WorldInfo.AllActors(class'CircleWorldEnemyPawn_Turret', T)
	{
		Turrets[i] = T;
		i += 1;
	}
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
	{
		Canvas.DrawColor = RedColor;
		Canvas.Font = class'Engine'.Static.GetSmallFont();
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.1);	
		Canvas.DrawText("World Properties - CircleAcceleration: " $CircleWorldPawn.CircleAcceleration$ " -- CircleVelocity: " $CircleWorldPawn.CircleVelocity$ " -- CircleVelocityPreAdjust: " $CircleWorldPawn.CircleVelocityPreAdjust$ " -- Circle Rotation: " $LevelBase.Rotation.Pitch);
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.15);	
		Canvas.DrawText("Pawn Properties -- Rot: " $CircleWorldPawn.Rotation.Yaw$ " -- Velocity: X"$CircleWorldPawn.CircleVelocity.X$ "Z" $CircleWorldPawn.Velocity.Z$ " -- AccelZ: " $CircleWorldPawn.Acceleration.Z$ " -- Boost: " $CircleWorldPawn.UsingBoost$ " -- Fuel: " $CircleWorldPawn.GetBoostFuelPercent()$ "% -- WasUsingBoost: " $CircleWorldPawn.WasUsingBoost$ " -- AimPoint: " $CircleWorldPawn.AimPoint);
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.2);
		Canvas.DrawText("Input - aStrafe: " $CircleWorldPlayerController(PlayerOwner).ThisStrafe$ " -- aForward: " $CircleWorldPlayerController(PlayerOwner).ThisUp$ " -- Control State: " $CircleWorldPlayerController(PlayerOwner).GetStateName()$ " -- IsRidingLift: " $CircleWorldPawn.IsRidingLift$ " -- RiddenLift: " $CircleWorldPawn.RiddenLift);
		
		ProjectLoc = Canvas.Project(CircleWorldPawn.AimPoint);
		Canvas.SetPos(ProjectLoc.X - 8, ProjectLoc.Y - 8);
		Canvas.DrawTile(Texture2D'CircleWorld.velocityvector', 16, 16, 0, 0, 16, 16, MakeLinearColor(1,0,0,1));
		
		foreach Enemies(EP)
		{
			ProjectLoc = Canvas.Project(EP.Location);
			Canvas.SetPos(ProjectLoc.X, ProjectLoc.Y);
			Canvas.DrawText("PawnVelocity: " $EP.EnemyPawnVelocity$ " -- Obstructed: " $EP.ObstructedForward$ " -- HoleForward: " $EP.HoleForward$ " -- Pitch: " $EP.Rotation.Pitch$ " -- Yaw: " $EP.Rotation.Yaw$ " -- EnemyPawnDirection: " $EP.EnemyPawnDirection);
		}		

		foreach Turrets(T)
		{
			ProjectLoc = Canvas.Project(T.Location);
			Canvas.SetPos(ProjectLoc.X, ProjectLoc.Y);
			Canvas.DrawText("State: " $T.Controller.GetStateName()$ " -- Target: " $T.PlayerTarget$ " -- IsAiming: " $T.IsAiming);
		}	
		
		ProjectLoc = Canvas.Project(Elephant.Location);
		Canvas.SetPos(ProjectLoc.X, ProjectLoc.Y);
		Canvas.DrawText("Polar Y: " $Elephant.LocationPolar.Y);		
		
	}	
	else
	{
		Canvas.DrawColor = RedColor;
		Canvas.Font = class'Engine'.Static.GetMediumFont();
		Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.1);	
		Canvas.DrawText("Energy: " $CircleWorldGameInfo(WorldInfo.Game).EnergyLevel);
		
		// Minimap stuff
		
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
		
		// Fuel guage stuff		
		// Draw a background
		Canvas.SetPos(Canvas.ClipX / 2 - 102, 8);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', 204, 24, 0, 0, 1, 1, MakeLinearColor(0,0,0,1));
		// Draw the guage bar
		Canvas.SetPos(Canvas.ClipX / 2 - 100, 10);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', CircleWorldPawn.GetBoostFuelPercent() * 2, 20, 0, 0, 1, 1, MakeLinearColor(1,1,1,1));

		// Health guage stuff		
		// Draw a background
		Canvas.SetPos(Canvas.ClipX / 2 - 102, 32);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', 204, 24, 0, 0, 1, 1, MakeLinearColor(0,0,0,1));
		// Draw the guage bar
		Canvas.SetPos(Canvas.ClipX / 2 - 100, 34);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', CircleWorldPawn.GetHealthPercent() * 2, 20, 0, 0, 1, 1, MakeLinearColor(1,0,0,1));
		
		// Draw key icons
		if (CircleWorldPawn.HasRedKey)
		{
			Canvas.SetPos(Canvas.ClipX / 2 - 96, 40);
			Canvas.DrawTile(Texture2D'CircleWorld.Key', 32,32, 0, 0, 32, 32, MakeLinearColor(1,0,0,1));
		}
		if (CircleWorldPawn.HasGreenKey)
		{
			Canvas.SetPos(Canvas.ClipX / 2 - 16, 40);
			Canvas.DrawTile(Texture2D'CircleWorld.Key', 32,32, 0, 0, 32, 32, MakeLinearColor(0,1,0,1));
		}
		if (CircleWorldPawn.HasBlueKey)
		{
			Canvas.SetPos(Canvas.ClipX / 2 + 48, 40);
			Canvas.DrawTile(Texture2D'CircleWorld.Key', 32,32, 0, 0, 32, 32, MakeLinearColor(0,0,1,1));
		}
		}
	
	super.DrawHUD();
}