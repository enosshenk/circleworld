class CircleWorldMapInfo extends MapInfo;

var(CircleWorldCamera) vector CameraOffset;	// Vector for camera offset
var(CircleWorldCamera) rotator CameraRotation;	// Base rotation offset
var(CircleWorldCamera) float CameraFOV;		// FOV value
var(CircleWorldCamera)	float BlendSpeed;		// Blend speed value
var(CircleWorldCamera)	float MaxRotX;			// Maximum rotation on the X axis, in degrees
var(CircleWorldCamera)	float MaxRotZ;			// Maximum rotation on the Z axis, in degrees
var(CircleWorldCamera)	float MaxTransX;		// Maximum translation on the X axis, in Unreal Units
var(CircleWorldCamera)	float MaxTransZ;		// Maximum translation on the Z axis, in Unreal Units

var(CircleWorldCamera) vector CameraOffset_U;	// Vector for camera offset *when underground*
var(CircleWorldCamera) rotator CameraRotation_U;	// Base rotation offset *when underground*
var(CircleWorldCamera) float CameraFOV_U;		// FOV value *when underground*
var(CircleWorldCamera)	float BlendSpeed_U;		// Blend speed value *when underground*
var(CircleWorldCamera)	float MaxRotX_U;			// Maximum rotation on the X axis, in degrees *when underground*
var(CircleWorldCamera)	float MaxRotZ_U;			// Maximum rotation on the Z axis, in degrees *when underground*
var(CircleWorldCamera)	float MaxTransX_U;		// Maximum translation on the X axis, in Unreal Units *when underground*
var(CircleWorldCamera)	float MaxTransZ_U;		// Maximum translation on the Z axis, in Unreal Units *when underground*

struct CircleWorldObjective
{
	var(CircleWorldObjectives) string ObjectiveName;				// Objective name, eg "Go to the core"
	var(CircleWorldObjectives) string ObjectiveOrders;				// Objective orders text, eg "Stan, get to the core before it explodes!"
	var(CircleWorldObjectives) bool ObjectiveHidden;				// If true, this objective is not called out on HUD
	var(CircleWorldObjectives) enum ObjectiveTypes					// Type of objective this is
	{
		O_Location,
		O_Timer,
		O_Kill,
		O_GetItem
	} ObjectiveType;
	var(CircleWorldObjectives) float ObjectiveTime;					// If type is timer, objective completes when this much time passes in seconds
	var(CircleWorldObjectives) CircleWorldObjectiveMarker Marker;	// Associated objective marker for a location, does not necissarily require location objective type
};

var(CircleWorldObjectives) array< CircleWorldObjective > Objectives;

defaultproperties
{
	CameraOffset = (X=128, Y=-1200, Z=128)
	CameraRotation = (Pitch=0, Yaw=0, Roll=0)
	CameraFOV = 70
	BlendSpeed = 0.1
	MaxRotX = 10
	MaxRotZ = 10
	MaxTransX = 256
	MaxTransZ = 256
	
	CameraOffset_U = (X=128, Y=-1200, Z=128)
	CameraRotation_U = (Pitch=0, Yaw=0, Roll=0)
	CameraFOV_U = 70
	BlendSpeed_U = 0.1
	MaxRotX_U = 10
	MaxRotZ_U = 10
	MaxTransX_U = 256
	MaxTransZ_U = 256
}