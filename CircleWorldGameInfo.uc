class CircleWorldGameInfo extends UDKGame;

var bool DebugHUD;
var int EnergyLevel;
var int CameraMode;
var CircleWorldPawn CirclePawn;

// This function is called to respawn the player when dead. We need to modify it.
function RestartPlayer(Controller NewPlayer)
{
	
	super.RestartPlayer(NewPlayer);
}

// Function to spawn a new pawn for the player
function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{

	return super.SpawnDefaultPawnFor(NewPlayer, StartSpot);
}

defaultproperties
{
	DebugHUD = true
	PlayerControllerClass = class'CircleWorldGame.CircleWorldPlayerController'
	DefaultPawnClass = class'CircleWorldGame.CircleWorldPawn'
	HUDType = class'CircleWorldGame.CircleWorldHUD'
}