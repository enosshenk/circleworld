class CircleWorldPlayerController extends UDKPlayerController;

var float LastAccelX;
var float ThisStrafe, ThisUp;
var float JumpHeldElapsed;
var bool JumpHeld;

enum EPrimaryUpgrades
{
	BlasterUpgrade1,
	BlasterUpgrade2
};

enum ESecondaryUpgrades
{
	LobberUpgrade1,
	LobberUpgrade2
};

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

exec function SetPawnBoostZ(float Z)
{
	CircleWorldHUD(myHUD).CircleWorldPawn.BoostZ = Z;
}

exec function SetPawnBoostX(float X)
{
	CircleWorldHUD(myHUD).CircleWorldPawn.BoostX = X;
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

exec function SprintDown()
{
	CircleWorldHUD(myHUD).CircleWorldPawn.Sprinting = true;
}

exec function SprintUp()
{
	CircleWorldHUD(myHUD).CircleWorldPawn.Sprinting = false;
}

exec function DropDown()
{
	CircleWorldHUD(myHUD).CircleWorldPawn.DropDown();
}

exec function SaveCircleValues()
{
	`log("CircleWorld editable values");
	`log("Pawn Speed: " $CircleWorldHUD(myHUD).CircleWorldPawn.GroundSpeed);
	`log("Air Control: " $CircleWorldHUD(myHUD).CircleWorldPawn.AirControl);
	`log("JumpZ: " $CircleWorldHUD(myHUD).CircleWorldPawn.JumpZ);
	`log("Jump Momentum: " $CircleWorldHUD(myHUD).CircleWorldPawn.JumpMomentum);
	`log("Momentum Fade: " $CircleWorldHUD(myHUD).CircleWorldPawn.MomentumFade);
	`log("Camera Pullback: " $CircleWorldHUD(myHUD).CircleWorldPawn.CameraPullback);
	`log("Camera Adjust Speed: " $CircleWorldHUD(myHUD).CircleWorldPawn.CameraAdjustSpeed);
	`log("Camera Translate Distance: " $CircleWorldHUD(myHUD).CircleWorldPawn.CameraTranslateDistance);
	`log("Camera Rotate Factor: " $CircleWorldHUD(myHUD).CircleWorldPawn.CameraRotateFactor);
	`log("Camera FOV Factor: " $CircleWorldHUD(myHUD).CircleWorldPawn.CameraFOVFactor);
	`log("BoostZ: " $CircleWorldHUD(myHUD).CircleWorldPawn.BoostZ);
	`log("BoostX: " $CircleWorldHUD(myHUD).CircleWorldPawn.BoostX);
}

exec function CircleJump()
{
	if (!CircleWorldPawn(Pawn).WasUsingBoost)
		JumpHeld = true;
		
	if (!CircleWorldPawn(Pawn).UsingBoost)
		Pawn.DoJump(bUpdating);	
		
	if (CircleWorldPawn(Pawn).WasUsingBoost)
	{
		GotoState('PlayerFlying');
		CircleWorldPawn(Pawn).UsingBoost = true;
		CircleWorldPawn(Pawn).BoostParticleSystem.SetActive(true);
	}
}

exec function CircleStopJump()
{
	if (JumpHeld)
	{
		JumpHeld = false;
		JumpHeldElapsed = 0;
	}
		
	if (CircleWorldPawn(Pawn).UsingBoost)	
	{
		GotoState('PlayerWalking');
		CircleWorldPawn(Pawn).UsingBoost = false;
		CircleWorldPawn(Pawn).BoostParticleSystem.SetActive(false);	
	}
}

exec function BoostLiftoff()
{
	GotoState('PlayerFlying');
	CircleWorldPawn(Pawn).UsingBoost = true;
	CircleWorldPawn(Pawn).WasUsingBoost = true;
	CircleWorldPawn(Pawn).BoostParticleSystem.SetActive(true);	
}

exec function BoostStop()
{
	GotoState('PlayerWalking');
	CircleWorldPawn(Pawn).UsingBoost = false;
	CircleWorldPawn(Pawn).BoostParticleSystem.SetActive(false);	
}

exec function AddPrimaryUpgrade(int NewUpgrade)
{
	CircleWorldPawn(Pawn).AddPrimaryUpgrade(NewUpgrade);
}

exec function AddSecondaryUpgrade(int NewUpgrade)
{
	CircleWorldPawn(Pawn).AddSecondaryUpgrade(NewUpgrade);
}

exec function ClearPrimaryUpgrade()
{
	CircleWorldPawn(Pawn).ClearPrimaryUpgrade();
}

exec function ClearSecondaryUpgrade()
{
	CircleWorldPawn(Pawn).ClearSecondaryUpgrade();
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector AimVector ;
		local Rotator tempRot, AimRot;

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
		CircleWorldPawn(Pawn).CircleAcceleration.X = (-1 * PlayerInput.aStrafe * DeltaTime * 30) + (LastAccelX * 0.8);
		LastAccelX = CircleWorldPawn(Pawn).CircleAcceleration.X;
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

		// Adjust the pawn aim location
		AimRot = Pawn.Rotation;
		AimVector = Pawn.Location;
		AimRot.Pitch = PlayerInput.aForward * 16.384;
		// Bias for left/right for keyboard
		if (AimRot.Pitch > 0)
			AimRot.Pitch -= Abs(PlayerInput.aStrafe) * 8.192;
		else if (AimRot.Pitch < 0)
			AimRot.Pitch += Abs(PlayerInput.aStrafe) * 8.192;
		// Set the aimpoint and rotate to world space
		AimVector += vect(512,0,0) >> AimRot;
		CircleWorldPawn(Pawn).AimPoint = AimVector;
		
		ThisStrafe = PlayerInput.aStrafe;
		ThisUp = PlayerInput.aForward;
		
		if (JumpHeld)
			JumpHeldElapsed += DeltaTime;
			
		if (JumpHeldElapsed >= 0.5)
			BoostLiftoff();		
	}
	// End state
}

state PlayerFlying
{
ignores SeePlayer, HearNoise, Bump;

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector AimVector;
		local Rotator tempRot, AimRot;

		if( Pawn == None )
		{
			return;
		}

		if (Role == ROLE_Authority)
		{
			// Update ViewPitch for remote clients
			Pawn.SetRemoteViewPitch( Rotation.Pitch );
		}		

		CircleWorldPawn(Pawn).CircleAcceleration.X = (-1 * PlayerInput.aStrafe * DeltaTime * CircleWorldPawn(Pawn).BoostX) + (LastAccelX * 0.8);
		LastAccelX = CircleWorldPawn(Pawn).CircleAcceleration.X;
			
		if (CircleWorldPawn(Pawn).BoostFuel > 0)
		{
			// We have fuel in our tanks, keep boosting			
			Pawn.Acceleration.Z = 1000 * DeltaTime * CircleWorldPawn(Pawn).BoostZ;
		}
		else
		{
			// We're out of fuel!
			Pawn.Acceleration.Z = 0;
			GotoState('PlayerWalking');
			CircleWorldPawn(Pawn).UsingBoost = false;
			CircleWorldPawn(Pawn).WasUsingBoost = true;
			CircleWorldPawn(Pawn).BoostParticleSystem.SetActive(false);
		}	
		
		Pawn.Acceleration.X = 0;
		Pawn.Acceleration.Y = 0;
		
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

		// Adjust the pawn aim location
		AimRot = Pawn.Rotation;
		AimVector = Pawn.Location;
		AimRot.Pitch = PlayerInput.aForward * 16.384;
		// Bias for left/right for keyboard
		if (AimRot.Pitch > 0)
			AimRot.Pitch -= Abs(PlayerInput.aStrafe) * 8.192;
		else if (AimRot.Pitch < 0)
			AimRot.Pitch += Abs(PlayerInput.aStrafe) * 8.192;
		// Set the aimpoint and rotate to world space
		AimVector += vect(512,0,0) >> AimRot;
		CircleWorldPawn(Pawn).AimPoint = AimVector;
		
		ThisStrafe = PlayerInput.aStrafe;
		ThisUp = PlayerInput.aForward;
	}
	
	event BeginState(Name PreviousStateName)
	{
		CircleWorldPawn(Pawn).WasUsingBoost = true;
		Pawn.SetPhysics(PHYS_Flying);
	}
	// end state
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