class CircleWorldPlayerController extends UDKPlayerController;

var CircleWorldPawn CirclePawn;

event PostBeginPlay()
{
	local CircleWorldPawn P;
	
	foreach WorldInfo.AllActors(class'CircleWorldPawn', P)
	{
		CirclePawn = P;
	}
	
	super.PostBeginPlay();
}

exec function DebugHUD()
{
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
	{
		CircleWorldGameInfo(WorldInfo.Game).DebugHUD = false;
	}
	else
	{
		CircleWorldGameInfo(WorldInfo.Game).DebugHUD = true;
	}
}

exec function SetPawnSpeed(float Speed)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.GroundSpeed = Speed;
}

exec function SetPawnJumpZ(float JumpZ)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.JumpZ = JumpZ;
}

exec function SetJumpMomentum(float M)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.JumpMomentum = M;
}

exec function SetMomentumFade(float F)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.MomentumFade = F;
}

exec function SetAirControl(float C)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.AirControl = C;
}

exec function SetCameraPullback(float D)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.CameraPullback = D;
}

exec function SetCameraAdjustSpeed(float S)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.CameraAdjustSpeed = S;
}

exec function SetCameraTranslateFactor(float T)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.CameraTranslateDistance = T;
}

exec function SetCameraRotateFactor(float R)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.CameraRotateFactor = R;
}

exec function SetCameraFOVFactor(float F)
{	
	CircleWorldHUD(myHUD).CircleWorldPawn.CameraFOVFactor = F;
}

exec function CircleCamOne()
{
	CircleWorldGameInfo(WorldInfo.Game).CameraMode = 0;
}

exec function CircleCamTwo()
{
	CircleWorldGameInfo(WorldInfo.Game).CameraMode = 1;
}

exec function CircleCamThree()
{
	CircleWorldGameInfo(WorldInfo.Game).CameraMode = 2;
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
{
	local Rotator tempRot;

	if( Pawn == None )
	{
	 return;
	}

	if (Role == ROLE_Authority)
	{
	 // Update ViewPitch for remote clients
	 Pawn.SetRemoteViewPitch( Rotation.Pitch );
	}

	// We set our new acceleration to a new var on the pawn. We want to bypass the stock movement system
	CircleWorldPawn(Pawn).CircleAcceleration.X = -1 * PlayerInput.aStrafe * DeltaTime * 40 * PlayerInput.MoveForwardSpeed;
	Pawn.Acceleration.Y = 0;
	Pawn.Acceleration.Z = 0;

	tempRot.Pitch = Pawn.Rotation.Pitch;
	tempRot.Roll = 0;
	if(Normal(CircleWorldPawn(Pawn).CircleAcceleration) Dot Vect(1,0,0) > 0)
	{
	 tempRot.Yaw = 0;
	 Pawn.SetRotation(tempRot);
	}
	else if(Normal(CircleWorldPawn(Pawn).CircleAcceleration) Dot Vect(1,0,0) < 0)
	{
	 tempRot.Yaw = 32768;
	 Pawn.SetRotation(tempRot);
	}

	CheckJumpOrDuck();
	}
}

function UpdateRotation( float DeltaTime )
{
   local Rotator   DeltaRot, ViewRotation;

   ViewRotation = Rotation;

   // Calculate Delta to be applied on ViewRotation
   DeltaRot.Yaw = Pawn.Rotation.Yaw;
   DeltaRot.Pitch   = PlayerInput.aLookUp;

   ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
   SetRotation(ViewRotation);
} 