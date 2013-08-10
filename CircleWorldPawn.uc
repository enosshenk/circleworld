class CircleWorldPawn extends Pawn
	notplaceable;

var vector CircleAcceleration;								// Fake acceleration set by the PlayerController
var vector LastAcceleration;								// Last accel value used for calculations
var vector CircleVelocity;									// Fake velocity calculated from our acceleration
var vector CircleVelocityPreAdjust;							// Velocity direct from calculations before adjustment for lifts etc
var vector LastVelocity;									// Last velocity value used for calculations
var vector CircleForce;										// Forces calculated for things like momentum
var vector CameraOffset;									// Camera offset used in CalcCamera

// Above ground camera settings
var vector MapCameraOffset;									// Camera offset data gotten from MapInfo
var rotator MapCameraRotator;								// Base rotation applied before movement
var float MapCameraFOV;										// Camera FOV data from MapInfo
var float MapCameraBlendSpeed;								// Blend speed from MapInfo
var float MapCameraMaxRotX;
var float MapCameraMaxRotZ;
var float MapCameraMaxTransX;
var float MapCameraMaxTransZ;

// Below ground camera settings
var vector MapCameraOffset_Underground;									// Camera offset data gotten from MapInfo
var rotator MapCameraRotator_Underground;								// Base rotation applied before movement
var float MapCameraFOV_Underground;										// Camera FOV data from MapInfo
var float MapCameraBlendSpeed_Underground;								// Blend speed from MapInfo
var float MapCameraMaxRotX_Underground;
var float MapCameraMaxRotZ_Underground;
var float MapCameraMaxTransX_Underground;
var float MapCameraMaxTransZ_Underground;

var rotator CameraRotator;									// Rotator used in CalcCamera
var vector AimPoint;										// A vector that we aim at when firing
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
var float BoostFuelMax;										// Current capacity of boost fuel
var float BoostUpgradeLevel;								// Upgrade level for boost
var float BoostConsumeRate;									// Fuel consumed per tick when boosting
var float BoostRegenRate;									// Fuel regenerated per tick when not boosting
var float BoostRegenTime;									// Time we must be on the ground before our fuel begins to regenerate
var float JumpLaunchTime;									// How long to play our jump launch animation
var float VerticalSensitivity;								// A variable used to determine if we're ascending or descending for animations.
var name HurtAnimationName;									// Animation sequence used for taking damage
var name PrimaryFireAnimationName;							// AnimSequence used for shooting primary fire
var name SecondaryFireAnimationName;						// Secondary fire

var bool CirclePawnMoving;									// True if the character is moving
var bool CirclePawnJumping;									// True if the character is jumping at all
var bool CirclePawnJumpUp;									// True if the character is jumping up (Hasn't hit top of jump yet)
var bool CirclePawnJumpDown;								// True when the character is falling
var bool Sprinting;											// True when the sprint key is held
var bool LedgeHanging;										// True when we're hanging on a ledge.
var bool UsingBoost;										// True while we're using our jetpack
var bool WasUsingBoost;										// True if we used boost any time before we land on solid ground
var bool BoostLand;											// True if we should play a boost landing animation
var bool CirclePawnBoostUp;									// Boosting and ascending
var bool CirclePawnBoostDown;								// Boosting and descending
var bool BoostRegenerating;									// True if we're regenerating fuel
var bool CanSkid;											// True if we are moving at top speed.
var bool IsSkidding;										// True while playing turn-skid animation. Prevents jumping and firing.
var bool IsTurning;											// True while playing idle turn animation. Prevents jumping and firing.
var bool ResetSkid;	
var bool IsRidingLift;										// True while the player is riding on a lift
var bool IsUnderground;										// True while player location on Z is less than the radius of the level world surface.
var bool CanShootPrimary;									// Seperate weapon cooldowns for primary and secondary fire
var bool CanShootSecondary;		
var bool PrimaryFireDown;									// True while player holds down primary fire button		
var bool SecondaryFireDown;		
var bool PrimarySpreadShot;									// True if we should fire multiple projectiles	
var bool HasRedKey;											// Keys
var bool HasBlueKey;
var bool HasGreenKey;

var CircleWorld_LevelBase LevelBase;						// Ref to the cylinder base
var array<CircleWorld_LevelBackground> LevelBackgrounds;	// Array of background items to rotate with the cylinder
var AnimNodeSlot PriorityAnimSlot;							// Ref to our AnimNodeSlot for playing one-shot animations
var ParticleSystemComponent BoostParticleSystem;			// Particle system component for our boost effects
var ParticleSystemComponent GroundEffectsParticleSystem;	// Particle system used when our boost exhaust is hitting the ground
var PointLightComponent BoostLight;							// Light attached for boost effects
var CircleWorldItem_Lift RiddenLift;						// Lift we're riding on, if any
var CircleWorldWeapons CircleWorldWeapons;					// Ref to our weapons component
var DynamicLightEnvironmentComponent MyLightEnvironment;
var CircleWorldPawn_Elephant Elephant;						// Ref to the elephant

var enum EPrimaryUpgrades
{
	BlasterUpgrade1,
	BlasterUpgrade2
} PrimaryUpgrades;

var enum ESecondaryUpgrades
{
	LobberUpgrade1,
	LobberUpgrade2
} SecondaryUpgrades;

event PostBeginPlay()
{
	local CircleWorld_LevelBase C;
	local CircleWorld_LevelBackground B;
	local vector ElephantSpawn;
	
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
	
	// Spawn the elephant
	ElephantSpawn = Location - vect(0,160,0);
	Elephant = Spawn(class'CircleWorldPawn_Elephant', self,, ElephantSpawn, Rotation,, true);
	Elephant.PlayerPawn = self;
	
	// Collect camera settings from MapInfo, if any
	if (CircleWorldMapInfo(WorldInfo.GetMapInfo()) != none)
	{
		MapCameraOffset = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraOffset;
		MapCameraRotator = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraRotation;
		MapCameraFOV = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraFOV;
		MapCameraBlendSpeed = CircleWorldMapInfo(WorldInfo.GetMapInfo()).BlendSpeed;
		MapCameraMaxRotX = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxRotX;
		MapCameraMaxRotZ = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxRotZ;
		MapCameraMaxTransX = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxTransX;
		MapCameraMaxTransZ = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxTransZ;
		
		MapCameraOffset_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraOffset_U;
		MapCameraRotator_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraRotation_U;
		MapCameraFOV_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).CameraFOV_U;
		MapCameraBlendSpeed_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).BlendSpeed_U;
		MapCameraMaxRotX_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxRotX_U;
		MapCameraMaxRotZ_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxRotZ_U;
		MapCameraMaxTransX_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxTransX_U;
		MapCameraMaxTransZ_Underground = CircleWorldMapInfo(WorldInfo.GetMapInfo()).MaxTransZ_U;
	}
	else
	{
		// No map info, set some defaults
		MapCameraOffset.X = 128;
		MapCameraOffset.Y = -1200;
		MapCameraOffset.Z = 128;
		MapCameraFOV = 70;
		MapCameraBlendSpeed = 0.1;
		MapCameraMaxRotX = 10;
		MapCameraMaxRotZ = 10;
		MapCameraMaxTransX = 256;
		MapCameraMaxTransZ = 256;
		
		MapCameraOffset_Underground.X = 128;
		MapCameraOffset_Underground.Y = -1200;
		MapCameraOffset_Underground.Z = 128;
		MapCameraFOV_Underground = 70;
		MapCameraBlendSpeed_Underground = 0.1;
		MapCameraMaxRotX_Underground = 10;
		MapCameraMaxRotZ_Underground = 10;
		MapCameraMaxTransX_Underground = 256;
		MapCameraMaxTransZ_Underground = 256;	
	}
	
	CircleWorldGameInfo(WorldInfo.Game).CirclePawn = self;
	
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
	
	// Set underground flag
	IsUnderground = CheckUnderground();

	// Set our new velocity based on the acceleration given by PlayerController
	if (Physics == PHYS_Falling || Physics == PHYS_Flying)
	{
		NewVelocity += (LastVelocity * 0.95) + (CircleAcceleration * AirControl);
		CircleVelocity = ClampLength(NewVelocity, AirSpeed);
		CircleVelocityPreAdjust = CircleVelocity;	
	
	}
	else
	{
		NewVelocity += (LastVelocity * 0.5) + CircleAcceleration;
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
	else if (IsRidingLift && RiddenLift.CircleLiftType == CW_ContinuousHorizontal)
	{
		// Riding a continuous horizontal lift. Add the lift speed to our velocity
		if (RiddenLift.ContDirection == D_Left)
		{
			
			CircleVelocity.X += ((RiddenLift.CircleLiftSpeed / 32768) * RadToDeg) * 2.3 * Pi * RiddenLift.Location.Z;
		}
		if (RiddenLift.ContDirection == D_Right)
		{
			CircleVelocity.X -= ((RiddenLift.CircleLiftSpeed / 32768) * RadToDeg) * 2.3 * Pi * RiddenLift.Location.Z;
		}	
	}
	
	// Check our forward collision
	if (CollisionCheckForward() == true)
	{
		// Collision trace says we're hitting a wall. Stop our motion.
		if (CircleVelocity.X > 0)
		{
			CircleVelocity.X = -10;
			LevelBase.PawnVelocity.X = -10;
			LastVelocity.X = -10;
		}
		else
		{
			CircleVelocity.X = 10;
			LevelBase.PawnVelocity.X = 10;
			LastVelocity.X = 10;		
		}
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
//			Velocity.Z -= 16;			
		}
	}
	else if (WasUsingBoost && !UsingBoost && !IsRidingLift)
	{
		if (CollisionCheckFeet() == false)
		{
			`log("Resetting walking collision");
			WasUsingBoost = false;
			BoostLand = true;
			// Reset us to walking on solid ground
			Controller.GotoState('PlayerWalking');
			SetPhysics(PHYS_Walking);
		}	
	}
	
	// Set sensitivity for the following checks
	if (WasUsingBoost)
		VerticalSensitivity = 150;
	else
		VerticalSensitivity = 100;
	
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
			PriorityAnimSlot.PlayCustomAnim('turn_run', 1, 0.1, 0.1, false, true);	
		}
		
		if (Rotation.Yaw == 0 && !IsTurning && !IsSkidding)
		{
			// We are facing left
			if (LastRot == 32768 && !CanSkid)
			{
				// We have reversed facing since last frame. Play our turn in place animation
				IsTurning = true;
				SetTimer(0.45, false, 'ResetTurning');
				PriorityAnimSlot.PlayCustomAnim('turn_idle', 1, 0.1, 0.1, false, true);
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
				PriorityAnimSlot.PlayCustomAnim('turn_idle', 1, 0.1, 0.1, false, true);			
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
	
	if (!UsingBoost && BoostRegenerating && BoostFuel < BoostFuelMax)
	{
		BoostFuel += BoostRegenRate;
		if (BoostFuel > BoostFuelMax)
			BoostFuel = BoostFuelMax;
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
	BoostLand = false;
	Controller.GotoState('PlayerWalking');
}

//
//	Helper functions
//

// Function casts a trace in our direction of travel. The trace is sized and located from our bounding box, so it must be accurate.
// Returns true if trace collided with the world cylinder.
function bool CollisionCheckForward()
{
	local vector TraceExtent, TraceStart, TraceEnd;
	
	// Set up some trace extents
	TraceExtent.X = 64;
	TraceExtent.Y = 64;	
	
	// Trace in our direction of motion. This is used to detect if the pawn is colliding with a wall.
	TraceStart = Location;
	TraceEnd = Location;
	if (Rotation.Yaw == 32768)
		TraceEnd.X -= Mesh.Bounds.BoxExtent.Y;
	else if (Rotation.Yaw == 0)
		TraceEnd.X += Mesh.Bounds.BoxExtent.Y;
	
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0);
	
	if (FastTrace(TraceEnd, TraceStart, TraceExtent))
	{
		// Trace hit no world geometry
		return false;
	}
	else
	{
		return true;
	}
}

// Function casts a trace below our feet, checking to see if it collides with the cylinder mesh. Trace is sized by our bounding box again.
// Returns true if the trace hit nothing, meaning we're standing over air and need to fall.
function bool CollisionCheckFeet()
{
	local vector TraceExtent, TraceStart, TraceEnd;
	
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
	
	if (FastTrace(TraceEnd, TraceStart, TraceExtent))
	{
		// We didn't hit any level geometry.
		return true;
	}	
	else
	{
		return false;
	}
}

// Trace during jetpack flight. If trace hits anything, return the vector location
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
	if (CircleWorld_LevelBase(HitActor) != none || CircleWorldItem_Lift(HitActor) != none)
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

function float GetBoostFuelPercent()
{
	return (BoostFuel / BoostFuelMax) * 100;
}

function UpgradeBoost()
{
	BoostUpgradeLevel += 1;
	BoostFuelMax = default.BoostFuelMax * BoostUpgradeLevel;
}

function float GetHealthPercent()
{
	return (Float(Health) / Float(HealthMax)) * 100;
}

function bool CheckUnderground()
{
	// Find out if we're underground
	if (Location.Z >= LevelBase.WorldRadius)
	{
		return false;
	}
	else
	{
		return true;
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


//
//	Shooting functions
//

simulated function StartFire(byte FireModeNum)
{
	local vector TraceStart, TraceEnd, HitLocation, HitNormal;
	local actor HitActor;
	
	// First, do a trace to see if we're trying to open a door instead of shooting
	Mesh.GetSocketWorldLocationAndRotation('FireSocket', TraceStart);
	TraceEnd = TraceStart;
	if (Rotation.Yaw == 32768)
		TraceEnd -= vect(512,0,0);
	else if (Rotation.Yaw == 0)
		TraceEnd += vect(512,0,0);
	
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
	if (CircleWorldItem_Door(HitActor) != none)
	{
		// Trace hit a door. Send the door open command and abort firing
		CircleWorldItem_Door(HitActor).OpenDoor();
	}
	else
	{	
		// Didn't hit a door. Go through with firing.

		if (FireModeNum == 0 && CircleCanShoot(0) && !PrimaryFireDown)
		{
			PrimaryFireDown = true;
			ShootPrimary();
			SetTimer(CircleWorldWeapons.Blaster.FireCooldown, false, 'RepeatShootPrimary');
		}
		if (FireModeNum == 1 && CircleCanShoot(1) && !SecondaryFireDown)
		{
			SecondaryFireDown = true;
			ShootSecondary();
			SetTimer(CircleWorldWeapons.Lobber.FireCooldown, false, 'RepeatShootSecondary');
		}
	}
}	

simulated function StopFire(byte FireModeNum)
{
	if (FireModeNum == 0)
	{
		PrimaryFireDown = false;
		ClearTimer('RepeatShootPrimary');
	}
	if (FireModeNum == 1)
	{
		SecondaryFireDown = false;
		ClearTimer('RepeatShootSecondary');
	}
}

function RepeatShootPrimary()
{
	if (PrimaryFireDown)
	{
		if (CircleCanShoot(0))
		{
			// Button is still held, and we can fire
			ShootPrimary();
			SetTimer(CircleWorldWeapons.Blaster.FireCooldown, false, 'RepeatShootPrimary');
		}
		else
		{
			// Player wants to fire, but we can't. Repeat the check.
			SetTimer(CircleWorldWeapons.Blaster.FireCooldown, false, 'RepeatShootPrimary');
		}
	}
}

function RepeatShootSecondary()
{
	if (SecondaryFireDown)
	{
		if (CircleCanShoot(1))
		{
			// Button is still held, and we can fire
			ShootSecondary();
			SetTimer(CircleWorldWeapons.Blaster.FireCooldown, false, 'RepeatShootSecondary');
		}
		else
		{
			// Player wants to fire, but we can't. Repeat the check.
			SetTimer(CircleWorldWeapons.Blaster.FireCooldown, false, 'RepeatShootSecondary');
		}
	}
}

function ShootPrimary()
{
	local vector ProjectileLocation;
	local rotator ProjectileRotation;
	local CircleWorldItemProjectile Projectile, SpreadUp, SpreadDown;
	
	if (!PrimarySpreadShot)
	{
		// Get projectile spawn location from our FireSocket socket
		Mesh.GetSocketWorldLocationAndRotation('FireSocket', ProjectileLocation);
			
		// Set projectile rotation based on aim point and current location
		ProjectileRotation = Rotator(Normal(AimPoint - Location));
		
		// Play an animation to "shoot"
		PriorityAnimSlot.PlayCustomAnim(PrimaryFireAnimationName, 1, 0.1, 0.1, false, true);
		
		// Spawn projectile
		Projectile = spawn(CircleWorldWeapons.Blaster.ProjectileClass, self, , ProjectileLocation, ProjectileRotation, , true);
		
		// Start the fire cooldown
		CanShootPrimary = false;
		SetTimer(CircleWorldWeapons.Blaster.FireCooldown - 0.02, false, 'EnablePrimary');
		
		// Initialize the projectile with rotation and added velocity
		Projectile.InitProjectile(ProjectileRotation, Abs(CircleVelocity.X));
	}
	else
	{
		// Get projectile spawn location from our FireSocket socket
		Mesh.GetSocketWorldLocationAndRotation('FireSocket', ProjectileLocation);
			
		// Set projectile rotation based on aim point and current location
		ProjectileRotation = Rotator(Normal(AimPoint - Location));
		
		// Play an animation to "shoot"
		PriorityAnimSlot.PlayCustomAnim(PrimaryFireAnimationName, 1, 0.1, 0.1, false, true);
		
		// Spawn projectile #1 (Center)
		Projectile = spawn(CircleWorldWeapons.Blaster.ProjectileClass, self, , ProjectileLocation, ProjectileRotation, , true);
		// Initialize the projectile with rotation and added velocity
		Projectile.InitProjectile(ProjectileRotation, Abs(CircleVelocity.X));	
		
		// Alter rotation
		ProjectileRotation.Pitch -= 1820;
		// Spawn projectile #2 (Up)
		SpreadUp = spawn(CircleWorldWeapons.Blaster.ProjectileClass, self, , ProjectileLocation, ProjectileRotation, , true);
		// Initialize the projectile with rotation and added velocity
		SpreadUp.InitProjectile(ProjectileRotation, Abs(CircleVelocity.X));			

		// Alter rotation
		ProjectileRotation.Pitch += 3640;
		// Spawn projectile #3 (Down)
		SpreadDown = spawn(CircleWorldWeapons.Blaster.ProjectileClass, self, , ProjectileLocation, ProjectileRotation, , true);
		// Initialize the projectile with rotation and added velocity
		SpreadDown.InitProjectile(ProjectileRotation, Abs(CircleVelocity.X));	
		
		// Start the fire cooldown
		CanShootPrimary = false;
		SetTimer(CircleWorldWeapons.Blaster.FireCooldown - 0.02, false, 'EnablePrimary');

	}
}

function ShootSecondary()
{
	local vector ProjectileLocation;
	local rotator ProjectileRotation;
	local CircleWorldItemProjectile Projectile;
	
	// Get projectile spawn location from our FireSocket socket
	Mesh.GetSocketWorldLocationAndRotation('FireSocket', ProjectileLocation);
		
	// Set projectile rotation based on aim point and current location
	ProjectileRotation = Rotator(Normal(AimPoint - Location));
	
	// Play an animation to "shoot"
	PriorityAnimSlot.PlayCustomAnim(SecondaryFireAnimationName, 1, 0.1, 0.1, false, true);
	
	// Spawn projectile
	Projectile = spawn(CircleWorldWeapons.Lobber.ProjectileClass, self, , ProjectileLocation, ProjectileRotation, , true);
	
	// Start the fire cooldown
	CanShootSecondary = false;
	SetTimer(CircleWorldWeapons.Lobber.FireCooldown - 0.02, false, 'EnableSecondary');
	
	// Initialize the projectile with rotation and added velocity
	Projectile.InitProjectile(ProjectileRotation, Abs(CircleVelocity.X));
}

function EnablePrimary()
{
	CanShootPrimary = true;
}

function EnableSecondary()
{
	CanShootSecondary = true;
}

function AddPrimaryUpgrade(int NewUpgrade)
{
	// Function sets the primary weapon upgrade by fetching the data from the weapons component, and changing the weapon properties
	
	// First reset all properties to default
	PrimarySpreadShot = false;
	CircleWorldWeapons.Blaster.FireCooldown = Default.CircleWorldWeapons.Blaster.FireCooldown;
	CircleWorldWeapons.Blaster.ProjectileClass = Default.CircleWorldWeapons.Blaster.ProjectileClass;
	
	// Now find what upgrade we're applying and change the properties
	switch (NewUpgrade)
	{
		case 1:
			CircleWorldWeapons.Blaster.FireCooldown = CircleWorldWeapons.BlasterUpgrade1.FireCooldown;
			CircleWorldWeapons.Blaster.ProjectileClass = CircleWorldWeapons.BlasterUpgrade1.ProjectileClass;
			break;
		case 2:
			PrimarySpreadShot = true;
			break;
	}
}

function AddSecondaryUpgrade(int NewUpgrade)
{
	// First reset all properties to default
	CircleWorldWeapons.Lobber.FireCooldown = Default.CircleWorldWeapons.Lobber.FireCooldown;
	CircleWorldWeapons.Lobber.ProjectileClass = Default.CircleWorldWeapons.Lobber.ProjectileClass;
	
	// Now find what upgrade we're applying and change the properties
	switch (NewUpgrade)
	{
		case 1:
			CircleWorldWeapons.Lobber.FireCooldown = CircleWorldWeapons.LobberUpgrade1.FireCooldown;
			CircleWorldWeapons.Lobber.ProjectileClass = CircleWorldWeapons.LobberUpgrade1.ProjectileClass;
			break;
		case 2:
			CircleWorldWeapons.Lobber.FireCooldown = CircleWorldWeapons.LobberUpgrade2.FireCooldown;
			CircleWorldWeapons.Lobber.ProjectileClass = CircleWorldWeapons.LobberUpgrade2.ProjectileClass;
			break;
	}
}

function ClearPrimaryUpgrade()
{
	PrimarySpreadShot = false;
	CircleWorldWeapons.Blaster.FireCooldown = Default.CircleWorldWeapons.Blaster.FireCooldown;
	CircleWorldWeapons.Blaster.ProjectileClass = Default.CircleWorldWeapons.Blaster.ProjectileClass;
}

function ClearSecondaryUpgrade()
{
	CircleWorldWeapons.Lobber.FireCooldown = Default.CircleWorldWeapons.Lobber.FireCooldown;
	CircleWorldWeapons.Lobber.ProjectileClass = Default.CircleWorldWeapons.Lobber.ProjectileClass;	
}


event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Play a hurt animation
	PriorityAnimSlot.PlayCustomAnim(HurtAnimationName, 1, 0.1, 0.1, false, true);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

// Null function to disable fall damage
function TakeFallingDamage();

// Replacement of a stock checking function.
function bool CannotJumpNow()
{
	return IsSkidding;	
}

function bool CircleCanShoot(int FireMode)
{
	if (IsSkidding || IsTurning)
		return false;
	else
	{
		if (FireMode == 0)
		{
			return CanShootPrimary;
		}
		else if (FireMode == 1)
		{
			return CanShootSecondary;
		}
	}
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
	}
	else if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 2)
	{
		// UBER CAM
		if (!IsUnderground)
		{
			// Not underground, use standard settings
			CameraOffset = Location;
			CameraOffset.X += MapCameraOffset.X * -1;
			CameraOffset.Y += MapCameraOffset.Y;
			CameraOffset.Z += MapCameraOffset.Z;
			
			// Do camera translation
			DesiredOffset = CameraOffset;
			DesiredOffset.X += Clamp(CircleVelocity.X, MapCameraMaxTransX * -1, MapCameraMaxTransX);
			DesiredOffset.Z += Clamp(Velocity.Z, MapCameraMaxTransZ * -1, MapCameraMaxTransZ);
			
			// X Axis
			if (CameraOffset.X != DesiredOffset.X)
			{
				CameraOffset.X = Lerp(CameraOffset.X, DesiredOffset.X, MapCameraBlendSpeed);
			}
			// Z axis
			if (CameraOffset.Z != DesiredOffset.Z)
			{
				CameraOffset.Z = Lerp(CameraOffset.Z, DesiredOffset.Z, MapCameraBlendSpeed);
			}
			// Do camera rotation
			DesiredCamRot = Rotator(Location - CameraOffset);
			DesiredCamRot += MapCameraRotator;
			DesiredCamRot.Yaw += Clamp(CircleVelocity.X * DegToUnrRot, MapCameraMaxRotX * -1, MapCameraMaxRotX);
			DesiredCamRot.Pitch += Clamp(CircleVelocity.Z * DegToUnrRot, MapCameraMaxRotZ * -1, MapCameraMaxRotZ);
			
			// Yaw = X
			if (CameraRotator.Yaw != DesiredCamRot.Yaw)
			{
				CameraRotator.Yaw = Lerp(CameraRotator.Yaw, DesiredCamRot.Yaw, MapCameraBlendSpeed);
			}
			// Pitch = Z
			if (CameraRotator.Pitch != DesiredCamRot.Pitch)
			{
				CameraRotator.Pitch = Lerp(CameraRotator.Pitch, DesiredCamRot.Pitch, MapCameraBlendSpeed);
			}	
		
			// Set the final out vars
			out_CamLoc = CameraOffset;
			out_CamRot = CameraRotator;
			out_FOV = MapCameraFOV;
		}
		else if (IsUnderground)
		{
			// Underground
			CameraOffset = Location;
			CameraOffset.X += MapCameraOffset_Underground.X * -1;
			CameraOffset.Y += MapCameraOffset_Underground.Y;
			CameraOffset.Z += MapCameraOffset_Underground.Z;
			
			// Do camera translation
			DesiredOffset = CameraOffset;
			DesiredOffset.X += Clamp(CircleVelocity.X, MapCameraMaxTransX_Underground * -1, MapCameraMaxTransX_Underground);
			DesiredOffset.Z += Clamp(Velocity.Z, MapCameraMaxTransZ_Underground * -1, MapCameraMaxTransZ_Underground);
			
			// X Axis
			if (CameraOffset.X != DesiredOffset.X)
			{
				CameraOffset.X = Lerp(CameraOffset.X, DesiredOffset.X, MapCameraBlendSpeed_Underground);
			}
			// Z axis
			if (CameraOffset.Z != DesiredOffset.Z)
			{
				CameraOffset.Z = Lerp(CameraOffset.Z, DesiredOffset.Z, MapCameraBlendSpeed_Underground);
			}
	
			// Do camera rotation
			DesiredCamRot = Rotator(Location - CameraOffset);
			DesiredCamRot += MapCameraRotator_Underground;
			DesiredCamRot.Yaw += Clamp(CircleVelocity.X * DegToUnrRot, MapCameraMaxRotX_Underground * -1, MapCameraMaxRotX_Underground);
			DesiredCamRot.Pitch += Clamp(CircleVelocity.Z * DegToUnrRot, MapCameraMaxRotZ_Underground * -1, MapCameraMaxRotZ_Underground);
			
			// Yaw = X
			if (CameraRotator.Yaw != DesiredCamRot.Yaw)
			{
				CameraRotator.Yaw = Lerp(CameraRotator.Yaw, DesiredCamRot.Yaw, MapCameraBlendSpeed_Underground);
			}
			// Pitch = Z
			if (CameraRotator.Pitch != DesiredCamRot.Pitch)
			{
				CameraRotator.Pitch = Lerp(CameraRotator.Pitch, DesiredCamRot.Pitch, MapCameraBlendSpeed_Underground);
			}	
		
			// Set the final out vars
			out_CamLoc = CameraOffset;
			out_CamRot = CameraRotator;
			out_FOV = MapCameraFOV_Underground;		
		}
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
	Health = 1000
	HealthMax = 1000
	
	GroundSpeed = 1500
	AirSpeed = 2100
	MaxJumpHeight = 3500
	JumpZ = 2000
	BoostZ = 6000
	BoostX = 50
	AirControl = 0.1
	
	MaxFallSpeed = 2100
	JumpMomentum =  .3
	MomentumFade = .5
	JumpLaunchTime = .2

	BoostFuel = 200
	BoostFuelMax = 999
	BoostConsumeRate = 0.1
	BoostRegenRate = 0.1
	BoostRegenTime = 1
	BoostUpgradeLevel = 8

	CameraPullback = 2000
	CameraAdjustSpeed = 0.01
	CameraTranslateDistance = 400
	CameraRotateFactor = .01
	CameraFOVFactor = 10
	
	CanShootPrimary = true
	CanShootSecondary = true
	
	HurtAnimationName = hurt
	PrimaryFireAnimationName = punch_stand1
	SecondaryFireAnimationName = punch_stand2
	
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=true
	TickGroup=TG_PreAsyncWork
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=90.000000
		CollisionHeight=80.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	Begin Object Class=DynamicLightEnvironmentComponent Name=LightEnvironment0
		bIsCharacterLightEnvironment=TRUE
	End Object
	Components.Add(LightEnvironment0)
	MyLightEnvironment=LightEnvironment0
	
	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'TheCircleWorld.Player.Stanley_ref'
		AnimTreeTemplate=AnimTree'TheCircleWorld.AnimTree.Player1_tree'
		PhysicsAsset = PhysicsAsset'TheCircleWorld.Player.Stanley_ref_Physics'
		AnimSets(0)=AnimSet'TheCircleWorld.AnimSet.Player1_anim'
		PhysicsAsset = PhysicsAsset'CircleWorldContent.Player.Player1_Physics'	
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
		LightEnvironment=LightEnvironment0
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
	
	Begin Object class=ParticleSystemComponent name=ParticleSystemComponent0
		Template=ParticleSystem'TheCircleWorld.FX.jetfire1'
		bAutoActivate=false
	End Object
	BoostParticleSystem = ParticleSystemComponent0
	
	Begin Object class=ParticleSystemComponent name=ParticleSystemComponent1
		Template=ParticleSystem'TheCircleWorld.FX.groundfx'
		bAutoActivate=false
	End Object
	GroundEffectsParticleSystem = ParticleSystemComponent1
	
	Begin Object class=PointLightComponent name=PointLightComponent0
		CastShadows = true
		CastStaticShadows = false
		CastDynamicShadows = true
		Radius = 900
		Brightness=3
		LightColor=(R=255,G=88,B=0)
	End Object
	BoostLight = PointLightComponent0
	
	Begin Object class=CircleWorldWeapons name=CircleWorldWeapons0
	End Object
	CircleWorldWeapons = CircleWorldWeapons0
}