class CircleWorldGameInfo extends UDKGame;

var bool DebugHUD;
var int EnergyLevel;
var int CameraMode;
var CircleWorldPawn CirclePawn;

defaultproperties
{
	DebugHUD = true
	PlayerControllerClass = class'CircleWorldGame.CircleWorldPlayerController'
	DefaultPawnClass = class'CircleWorldGame.CircleWorldPawn'
	HUDType = class'CircleWorldGame.CircleWorldHUD'
}