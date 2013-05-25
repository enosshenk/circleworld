class CircleWorldPawn extends Pawn
	notplaceable;

var vector CircleAcceleration;								// Fake acceleration set by the PlayerController
var vector LastAcceleration;								// Last accel value used for calculations
var vector CircleVelocity;									// Fake velocity calculated from our acceleration
var vector CircleVelocityPreAdjust;							// Velocity direct from calculations before adjustment for lifts etc
var vector LastVelocity;									// Last velocity value used for calculations
var vector CircleForce;										// Forces calculated for things like momentum
var vector CameraOffset;									// Camera offset used in CalcCamera
var rotator CameraRotator;									// Rotator used in CalcCamera
var float CameraAlpha;										// Alpha value for lerping
var float CameraAlphaZ;
var float CameraFOV;										// FOV value used for mode 3
var float CameraPullback;									// How far the camera pulls back on the Y axis from the character
var float CameraAdjustSpeed;								// How fast the camera movement blends
var float CameraTranslateDistance;							// Distance the camera moves in mode 1
var float CameraRotateFactor;								// Factor for rotating the camera in mode 2
var float CameraFOVFactor;									// Factor for changing the FOV in mode 3
var float JumpMomentum;										// Factor of momentum
var float MomentumFade;										// Factor of momentum fading
var float LastRot;											// Rotation last tick (Yaw)
var float BoostZ;											// Boost Z accel factor
var float BoostX;											// Boost X accel factor
var float BoostFuel;										// Fuel available for boosting
var float BoostConsumeRate;									// Fuel consumed per tick when boosting
var float BoostRegenRate;									// Fuel regenerated per tick when not boosting
var float BoostRegenTime;									// Time we must be on the ground before our fuel begins to regenerate
var float JumpLaunchTime;									// How long to play our jump launch animation
var float VerticalSensitivity;								// A variable used to determine if we're ascending or descending for animations.

var bool CirclePawnMoving;									// True if the character is moving
var bool CirclePawnJumping;									// True if the character is jumping at all
var bool CirclePawnJumpUp;									// True if the character is jumping up (Hasn't hit top of jump yet)
var bool CirclePawnJumpDown;								// True when the character is falling
var bool Sprinting;											// True when the sprint key is held
var bool LedgeHanging;										// True when we're hanging on a ledge.
var bool UsingBoost;										// True while we're using our jetpack
var bool WasUsingBoost;										// True if we used boost any time before we land on solid ground
var bool CirclePawnBoostUp;									// Boosting and ascending
var bool CirclePawnBoostDown;								// Boosting and descending
var bool BoostRegenerating;									// True if we're regenerating fuel
var bool UseCameraActor;
var bool CanSkid;											// True if we are moving at top speed.
var bool IsSkidding;										// True while playing turn-skid animation. Prevents jumping and firing.
var bool IsTurning;											// True while playing idle turn animation. Prevents jumping and firing.
var bool ResetSkid;	
var bool IsRidingLift;										// True while the player is riding on a lift

var CameraActor CameraActor;
var rotator CameraActorRot;
var vector CameraActorLoc;
var float CameraActorFOV;

var CircleWorld_LevelBase LevelBase;						// Ref to the cylinder base
var array<CircleWorld_LevelBackground> LevelBackgrounds;	// Array of background items to rotate with the cylinder
var AnimNodeSlot PriorityAnimSlot;							// Ref to our AnimNodeSlot for playing one-shot animations
var ParticleSystemComponent BoostParticleSystem;			// Particle system component for our boost effects
var ParticleSystemComponent GroundEffectsParticleSystem;	// Particle system used when our boost exhaust is hitting the ground
var PointLightComponent BoostLight;							// Light attached for boost effects
var CircleWorldItem_Lift RiddenLift;						// Lift we're riding on, if any



event PostBeginPlay()
{
	local CircleWorld_LevelBase C;
	local CircleWorld_LevelBackground B;
	local CameraActor CA;
	
	// Get our reference to the level cylinder
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', C)
	{
		LevelBase = C;
	}
	
	// Fill the background items array with any LevelBackground actors
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBackground', B)
	{
		LevelBackgrounds.AddItem(B);
	}
	
	// attach the jetpack effect
	Mesh.AttachComponentToSocket(BoostParticleSystem, 'BoostSocket');
	AttachComponent(GroundEffectsParticleSystem);
	Mesh.AttachComponentToSocket(BoostLight, 'BoostSocket');
	BoostLight.SetEnabled(false);
	
	foreach WorldInfo.AllActors(class'CameraActor', CA)
	{
		if (CA.Tag == 'fnord')
		{
			`log("Found camera actor");
			CameraActor = CA;
			CameraActorRot = CameraActor.Rotation;
			CameraActorLoc = CameraActor.Location;
			CameraActorFOV = CameraActor.FOVAngle;
		}
	}
	
	super.PostBeginPlay();
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

event Tick(float DeltaTime)
{
	local vector NewVelocity, TempVector, TranslateVector;
	local CircleWorld_LevelBackground B;

	// Find out if we're on a lift
	if (RidingLift() == true)
	{
		IsRidingLift = true;
		if (IsTimerActive('DisableRidingOnLift'));
			ClearTimer('DisableRidingOnLift');
	}
	else
	{
		if (!IsTimerActive('DisableRidingOnLift'));
			SetTimer(0.1, false, 'DisableRidingOnLift');
	}

	// Set our new velocity based on the acceleration given by PlayerController
	if (Physics == PHYS_Falling)
	{
		CircleForce = CircleAcceleration;
		CircleForce += LastVelocity * JumpMomentum;
		NewVelocity = (LastVelocity * MomentumFade + CircleForce);
		CircleVelocity = ClampLength(NewVelocity, GroundSpeed);
		CircleVelocityPreAdjust = CircleVelocity;
	}
	else if (Physics == PHYS_Flying)
	{
		CircleForce = CircleAcceleration;
		NewVelocity = (LastVelocity * MomentumFade + CircleForce);
		CircleVelocity = ClampLength(NewVelocity, AirSpeed);
		CircleVelocityPreAdjust = CircleVelocity;		
	}
	else
	{
		CircleForce = CircleAcceleration;
		NewVelocity = (LastVelocity * MomentumFade + CircleForce);
		CircleVelocity = ClampLength(NewVelocity, GroundSpeed);
		CircleVelocityPreAdjust = CircleVelocity;
	}

	if (IsRidingLift && RiddenLift.CircleLiftType == CW_Horizontal)
	{
		`log("Riding horizontal lift");
		// Riding a horizontal lift. Add the lift speed to our velocity
		if (RiddenLift.TravelDirection == 1 && !RiddenLift.IsWaiting)
		{
			
			CircleVelocity.X -= ((RiddenLift.CircleLiftSpeed / 32768) * RadToDeg) * 2.3 * Pi * RiddenLift.Location.Z;
		}
		if (RiddenLift.TravelDirection == -1 && !RiddenLift.IsWaiting)
		{
			CircleVelocity.X += ((RiddenLift.CircleLiftSpeed / 32768) * RadToDeg) * 2.3 * Pi * RiddenLift.Location.Z;
		}
	}
	
	// Check our forward collision
	if (CollisionCheckForward() == true)
	{
		// Collision trace says we're hitting a wall. Stop our motion.
		CircleVelocity.X = 0;
		LevelBase.PawnVelocity.X = 0;
		LastVelocity.X = 0;
	}

	if (!Sprinting && !CirclePawnJumping && !UsingBoost && !WasUsingBoost && !IsRidingLift)
	{
		// Check our below feet collision
		if (CollisionCheckFeet() == true)
		{
			// Collision trace says we need to fall
			WasUsingBoost = false;
			Controller.GotoState('PlayerWalking');
			SetPhysics(PHYS_Falling);
			Velocity.Z -= 16;			
		}
	}
	else if (WasUsingBoost && !UsingBoost && !IsRidingLift)
	{
		if (CollisionCheckFeet() == false)
		{
			`log("Resetting walking collision");
			// Reset us to walking on solid ground
			WasUsingBoost = false;
			Controller.GotoState('PlayerWalking');
			SetPhysics(PHYS_Walking);
		}	
	}
	
	// Set sensitivity for the following checks
	if (WasUsingBoost)
		VerticalSensitivity = 150;
	else
		VerticalSensitivity = 10;
	
	// Set some flags
	if (Velocity.Z > VerticalSensitivity)
	{
		if (!UsingBoost)
		{
			// We are jumping up! Tell the AnimTree
			CirclePawnJumpUp = true;
			CirclePawnJumpDown = false;
			CirclePawnJumping = true;
		}
		else
		{
			// We are boosting up
			CirclePawnBoostUp = true;
			CirclePawnBoostDown = false;
		}
	}
	else if (Velocity.Z < VerticalSensitivity * -1)
	{
		if (!WasUsingBoost)
		{
			// We're falling straight down
			CirclePawnJumpUp = false;
			CirclePawnJumpDown = true;
			CirclePawnJumping = true;
		}
		else
		{
			// We are falling in boost mode
			CirclePawnBoostUp = false;
			CirclePawnBoostDown = true;		
		}
	}	
	else
	{
		CirclePawnJumpUp = false;
		CirclePawnJumpDown = false;	
		CirclePawnJumping = false;
		CirclePawnBoostUp = false;
		CirclePawnBoostDown = false;	
	}
	
	if (VSize(Velocity) > 10 || VSize(CircleVelocityPreAdjust) > 10)
	{
		// We are moving on the X axis, flag our movement state for AnimTree handling
		CirclePawnMoving = true;
	}
	else
	{
		CirclePawnMoving = false;
	}

	if (!CirclePawnJumping && !UsingBoost)
	{
		if (VSize(CircleVelocity) >= GroundSpeed - 20)	// We're moving near top speed, we can skid if we stop suddenly.
		{
			// We want to delay changing our skid status to allow the animations to play out
			// This is also hacky and stupid, but it works
			ResetSkid = false;
			if (!IsTimerActive('SetSkid'))
				SetTimer(0.3, false, 'SetSkid');
		}
		else
		{
			ResetSkid = true;
			if (!IsTimerActive('SetSkid'))
				SetTimer(0.1, false, 'SetSkid');
		}

		if (Abs(CircleVelocity.X) < Abs(LastVelocity.X) * 0.95 && CanSkid && !IsTurning && !IsSkidding)
		{
			// Play our running skid-and-stop animation
			IsSkidding = true;
			ResetSkid = false;
			if (!IsTimerActive('SetSkid'))
				SetTimer(0.1, false, 'SetSkid');
			SetTimer(0.45, false, 'ClearSkid');
			PriorityAnimSlot.PlayCustomAnimByDuration('turn_run', 0.45, 0.1, 0.1, false, true);	
		}
		
		if (Rotation.Yaw == 0 && !IsTurning && !IsSkidding)
		{
			// We are facing left
			if (LastRot == 32768 && !CanSkid)
			{
				// We have reversed facing since last frame. Play our turn in place animation
				IsTurning = true;
				SetTimer(0.45, false, 'ResetTurning');
				PriorityAnimSlot.PlayCustomAnimByDuration('turn_idle', 0.45, 0.1, 0.1, false, true);
			}
			LastRot = 0;			
		}
		else if (Rotation.Yaw == 32768 && !IsTurning && !IsSkidding)
		{
			// We are facing right
			if (LastRot == 0 && !CanSkid)
			{
				// We have reversed facing since last frame.
				IsTurning = true;
				SetTimer(0.45, false, 'ResetTurning');
				PriorityAnimSlot.PlayCustomAnimByDuration('turn_idle', 0.45, 0.1, 0.1, false, true);			
			}
			LastRot = 32768;
		}
	}

	// Send the data to the cylinder world actor
	LevelBase.PawnVelocity = CircleVelocity;
	LevelBase.PawnLocation = Location;
	
	// Send the data to any level background actors
	foreach LevelBackgrounds(B)
	{
		B.PawnVelocity = CircleVelocity;
		B.PawnLocation = Location;
	}
	
	if (Sprinting)
	{
		// We are sprinting. Use old floor detection and modify our groundspeed.
		bForceFloorCheck = true;
		GroundSpeed = default.GroundSpeed * 2;
	}
	else
	{
		bForceFloorCheck = false;
		GroundSpeed = default.GroundSpeed;	
	}
	
	// Check our boost fuel stuff
	if (UsingBoost)
	{
		// We're using our jetpack. Reduce the fuel supply.
		BoostFuel -= BoostConsumeRate;
		if (BoostFuel < 0)
			BoostFuel = 0;
		
		// Make sure regen gets disabled
		BoostRegenerating = false;
		ClearTimer('BeginBoostRegenerate');
		
		// Trace below us for detecting ground effects
		TempVector = JetpackGroundCheck();
		if (TempVector != vect(0,0,0))
		{
			GroundEffectsParticleSystem.SetActive(true);
			TranslateVector = TempVector - Location;
			GroundEffectsParticleSystem.SetTranslation(TranslateVector);
		}
		else
		{
			GroundEffectsParticleSystem.SetActive(false);
		}
		BoostLight.SetEnabled(true);
	}
	else
	{
		GroundEffectsParticleSystem.SetActive(false);
		BoostLight.SetEnabled(false);
	}
	
	if (!UsingBoost && !BoostRegenerating && !IsTimerActive('BeginBoostRegenerate'))
	{
		// We're on the ground, but we haven't begun to regenerate fuel yet
		// Set a timer to begin the regeneration.
		SetTimer(BoostRegenTime, false, 'BeginBoostRegenerate');
	}
	
	if (!UsingBoost && BoostRegenerating)
	{
		BoostFuel += BoostRegenRate;
		if (BoostFuel > 100)
			BoostFuel = 100;
	}
	
	// Set the values as the previous accel and velocity for the next tick
	LastAcceleration = CircleAcceleration;
	LastVelocity = CircleVelocityPreAdjust;
	
	// Make sure we don't go anywhere on Y
	Velocity.Y = 0;
	Acceleration.Y = 0;
	
	super.Tick(DeltaTime);
}

event Landed(vector HitNormal, Actor FloorActor)
{
	UsingBoost = false;
	WasUsingBoost = false;
	Controller.GotoState('PlayerWalking');
}

//
//	Helper functions
//

// Function casts a trace in our direction of travel. The trace is sized and located from our bounding box, so it must be accurate.
// Returns true if trace collided with the world cylinder.
function bool CollisionCheckForward()
{
	local vector TraceExtent, TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;
	
	// Set up some trace extents
	TraceExtent.X = 64;
	TraceExtent.Y = 64;	
	
	// Trace in our direction of motion. This is used to detect if the pawn is colliding with a wall.
	TraceEnd = Location;
	if (Rotation.Yaw == 0)
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.Y;
		TraceStart = Location + vect(32,0,0);
	}
	else
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.Y * -1;
		TraceStart = Location + vect(-32,0,0);
	}
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0);
		
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, TraceExtent);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		// Trace hit the level mesh.
		return true;
	}
	else
	{
		return false;
	}
}

// Function casts a trace below our feet, checking to see if it collides with the cylinder mesh. Trace is sized by our bounding box again.
// Returns true if the trace hit nothing, meaning we're standing over air and need to fall.
function bool CollisionCheckFeet()
{
	local vector TraceExtent, TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;
	
	// Set up some trace extents
	TraceExtent.X = 64;
	TraceExtent.Y = 64;	
	
	// Set up for our below feet trace.
	TraceStart = Location;
	TraceStart.Z -= (Mesh.Bounds.BoxExtent.Z / 2) - 32;
	TraceEnd = TraceStart;
	TraceEnd.Z -= 256;
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0);
	
	// Trace straight down from our feet.
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, TraceExtent);
	if (CircleWorld_LevelBase(HitActor) == none)
	{
		// We didn't hit any level geometry.
		return true;
	}	
	else
	{
		return false;
	}
}

function vector JetpackGroundCheck()
{
	local vector TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;
	
	Mesh.GetSocketWorldLocationAndRotation('BoostSocket', TraceStart);
	TraceEnd = TraceStart;
	TraceEnd.Z -= 256;

	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0);

	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		// Trace hit the level geometry. We send the hitlocation to position the ground effects.
		return HitLocation;
	}
	else
	{
		return vect(0,0,0);
	}	
}

function bool RidingLift()
{
	local vector TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;

	TraceStart = Location;
	TraceStart.Z -= (Mesh.Bounds.BoxExtent.Z / 2) - 32;
	TraceEnd = TraceStart;
	TraceEnd.Z -= 128;

	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 0, 255, 0);

	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorldItem_Lift(HitActor) != none)
	{
		// We're on a lift
		RiddenLift = CircleWorldItem_Lift(HitActor);
		WasUsingBoost = false;
		return true;
	}
	else
	{
		RiddenLift = none;
		return false;
	}	
}

//
//	Pawn functions
//

function DropDown()
{
	// Function to check and see if we can do a drop down move. If so, execute the move.
	local vector TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;
	
	TraceStart = Location;
	TraceEnd = TraceStart;
	TraceEnd.Z -= Mesh.Bounds.BoxExtent.Z * 2;
	
	if (Rotation.Yaw == 0)
	{
		TraceEnd.X += Mesh.Bounds.BoxExtent.Z * 2;
	}
	else
	{
		TraceEnd.X -= Mesh.Bounds.BoxExtent.Z * 2;
	}
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0, true);	
		
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		`log("Cannot drop down");
	}		
	else
	{
		`log("Can drop down");
		CircleVelocity.X += 512;
	}
}

function PullUp()
{
	// Function to pull us back up if we're ledge hanging
	
}

// Main fire function. FireModeNum 0 is left click, 1 is right click.
simulated function StartFire(byte FireModeNum)
{
	local CircleWorldItemProjectile Projectile;
	local vector ProjectileLocation;
	local rotator ProjectileRotation;
	
	// We can't shoot if we're skidding or turning
	if (!IsSkidding && !IsTurning)
	{
		// We spawn the projectile at our current location, but 64 units ahead of our direction of travel.
		ProjectileLocation = self.Location;
		if (Rotation.Yaw == 0)
			ProjectileLocation.X -= 64;
		if (Rotation.Yaw == 32768)
			ProjectileLocation.X += 64;
			
		// Make sure the projectile gets our current rotation. This determines it's direction of flight.
		ProjectileRotation = self.Rotation;
		
		// Play an animation to "shoot"
		PriorityAnimSlot.PlayCustomAnimByDuration('punch_stand1', 0.45, 0.1, 0.1, false, true);
		
		// Find out which fire mode we're using, and spawn that projectile.
		if (FireModeNum == 0)
			Projectile = spawn(class'CircleWorldItemProjectile', self, , ProjectileLocation, ProjectileRotation, , true);
		if (FireModeNum == 1)
			Projectile = spawn(class'CircleWorldItemProjectile_Fireball', self, , ProjectileLocation, ProjectileRotation, , true);
			
		// Once more we make damn sure our projectile rotation is right.
		if (Rotation.Yaw == 0)
		{
			// Set the projectile pitch with a small bit of random angle.
			ProjectileRotation.Pitch = 0 + (Clamp(Velocity.Z, -10, 10) * DegToUnrRot);	
			// InitProjectile must be called, passing the proper rotation.
			Projectile.InitProjectile(ProjectileRotation, CircleVelocity.X);
		}
		if (Rotation.Yaw == 32768)
		{
			ProjectileRotation.Pitch = 32768 + (Clamp(Velocity.Z, -10, 10) * DegToUnrRot);
			Projectile.InitProjectile(ProjectileRotation, CircleVelocity.X);
		}
	}
}	

// Null function to disable fall damage
function TakeFallingDamage();

// Replacement of a stock checking function.
function bool CannotJumpNow()
{
	return IsSkidding;
	
}

function ClearSkid()
{
	IsSkidding = false;
}

function ResetTurning()
{
	IsTurning = false;
}

function SetSkid()
{
	if (ResetSkid)
	{
		CanSkid = false;
	}
	else
	{
		CanSkid = true;
	}
}

function BeginBoostRegenerate()
{
	BoostRegenerating = true;
}

function DisableRidingOnLift()
{
	IsRidingLift = false;
}

//
//	Camera
//

simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector DesiredOffset;
	local rotator DesiredCamRot;
	local float DesiredFOV;

	if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 0)
	{
		CameraOffset.Y = CameraPullback * -1;
		
		DesiredOffset.X = Clamp(CircleVelocity.X, CameraTranslateDistance * -1, CameraTranslateDistance);
		DesiredOffset.Z = Clamp(Velocity.Z, CameraTranslateDistance * -1, CameraTranslateDistance);
		
		// X Axis
		if (CameraOffset.X != DesiredOffset.X)
		{
			CameraOffset.X = Lerp(CameraOffset.X, DesiredOffset.X, CameraAdjustSpeed);
		}
		// Z axis
		if (CameraOffset.Z != DesiredOffset.Z)
		{
			CameraOffset.Z = Lerp(CameraOffset.Z, DesiredOffset.Z, CameraAdjustSpeed);
		}
		
		out_CamLoc = Location + CameraOffset;
		out_CamRot.Yaw = 16384;
		
	}
	else if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 1)
	{
		CameraOffset = self.Location;
		CameraOffset.Y -= CameraPullback;
		
		DesiredCamRot = Rotator(Location - CameraOffset);
		DesiredCamRot.Yaw += (CircleVelocity.X * CameraRotateFactor) * -1;
		DesiredCamRot.Pitch += Velocity.Z;
		
		// Yaw = X
		if (CameraRotator.Yaw != DesiredCamRot.Yaw)
		{
			CameraRotator.Yaw = Lerp(CameraRotator.Yaw, DesiredCamRot.Yaw, CameraAdjustSpeed);
		}
		// Pitch = Z
		if (CameraRotator.Pitch != DesiredCamRot.Pitch)
		{
			CameraRotator.Pitch = Lerp(CameraRotator.Pitch, DesiredCamRot.Pitch, CameraAdjustSpeed);
		}	
		
		out_CamLoc = CameraOffset;
		out_CamRot = CameraRotator;
		
		CameraRotator = out_CamRot;
		CameraAlpha += fDeltaTime / CameraAdjustSpeed;
	}
	else if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 2)
	{
		CameraOffset = self.Location;
		CameraOffset.Y -= CameraPullback;
		
		DesiredFOV = Clamp(60 + ((VSize(Velocity) + VSize(CircleVelocity)) / 2) / CameraFOVFactor, 50 - CameraFOVFactor, 90 + CameraFOVFactor);
		
		if (CameraFOV != DesiredFOV)
		{
			CameraFOV = Lerp(CameraFOV, DesiredFOV, CameraAdjustSpeed);
		}
		
		out_CamLoc = CameraOffset;
		out_CamRot.Yaw = 16384;
		out_FOV = CameraFOV;
		
		CameraFOV = out_FOV;
	}
	else if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 3)
	{
		out_CamLoc = CameraActorLoc;
		out_CamRot = CameraActorRot;
		out_FOV = CameraActorFOV;
	}
	
	return true;
}

simulated singular event Rotator GetBaseAimRotation()
{
   local rotator   POVRot;

   POVRot = Rotation;
   if( (Rotation.Yaw % 65535 > 16384 && Rotation.Yaw % 65535 < 49560) ||
	  (Rotation.Yaw % 65535 < -16384 && Rotation.Yaw % 65535 > -49560) )
   {
		POVRot.Yaw = 32768;
   }
   else
   {
		POVRot.Yaw = 0;
   }
   
   if( POVRot.Pitch == 0 )
   {
	  POVRot.Pitch = RemoteViewPitch << 8;
   }

   return POVRot;
}  
	
defaultproperties
{
	GroundSpeed = 700
	AirSpeed = 1200
	MaxJumpHeight = 1100
	JumpZ = 0900.000000
	BoostZ = 30
	BoostX = 10
	AirControl = 0.03
	MaxFallSpeed = 1024
	JumpMomentum = 0.9
	MomentumFade = 0.2
	JumpLaunchTime = 0.4
	
	BoostFuel = 100;
	BoostConsumeRate = 0.05;
	BoostRegenRate = 0.1;
	BoostRegenTime = 1;
	
	CameraPullback = 2048
	CameraAdjustSpeed = 0.05
	CameraTranslateDistance = 200
	CameraRotateFactor = 1
	CameraFOVFactor = 10
	
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=true
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=64.000000
		CollisionHeight=128.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)


	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'RockCharacter.TheRock'
		AnimTreeTemplate=AnimTree'RockCharacter.Rock_Tree'
		AnimSets(0)=AnimSet'RockCharacter.Rock_Anim'
		PhysicsAsset = PhysicsAsset'RockCharacter.therock_Physics'		
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
        BlockRigidBody=true
        CollideActors=true
        BlockZeroExtent=true
		BlockNonZeroExtent=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateSkelWhenNotRendered=FALSE
		bHasPhysicsAssetInstance=true
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
	
	Begin Object class=ParticleSystemComponent name=ParticleSystemComponent0
		Template=ParticleSystem'CircleWorld.Boost_PS'
		bAutoActivate=false
	End Object
	BoostParticleSystem = ParticleSystemComponent0
	
	Begin Object class=ParticleSystemComponent name=ParticleSystemComponent1
		Template=ParticleSystem'CircleWorld.GroundEffects_PS'
		bAutoActivate=false
	End Object
	GroundEffectsParticleSystem = ParticleSystemComponent1
	
	Begin Object class=PointLightComponent name=PointLightComponent0
		CastShadows = true
		CastStaticShadows = false
		CastDynamicShadows = true
		Radius = 512
		Brightness=1.0
		LightColor=(R=255,G=255,B=255)
	End Object
	BoostLight = PointLightComponent0
}