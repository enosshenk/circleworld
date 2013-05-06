class CircleWorldGameInfo extends UDKGame;

var bool DebugHUD;
var int CoinsCollected;
var int CameraMode;

defaultproperties
{
	DebugHUD = true
	PlayerControllerClass = class'CircleWorldGame.CircleWorldPlayerController'
	DefaultPawnClass = class'CircleWorldGame.CircleWorldPawn'
	HUDType = class'CircleWorldGame.CircleWorldHUD'
}