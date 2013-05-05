class CircleWorldPawn extends Pawn
	notplaceable;

var vector CircleAcceleration;								// Fake acceleration set by the PlayerController
var vector LastAcceleration;								// Last accel value used for calculations
var vector CircleVelocity;									// Fake velocity calculated from our acceleration
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

var bool CirclePawnMoving;									// True if the character is moving
var bool CirclePawnJumping;									// True if the character is jumping at all
var bool CirclePawnJumpUp;									// True if the character is jumping up (Hasn't hit top of jump yet)
var bool CirclePawnJumpDown;								// True when the character is falling

var CircleWorld_LevelBase LevelBase;						// Ref to the cylinder base
var array<CircleWorld_LevelBackground> LevelBackgrounds;	// Array of background items to rotate with the cylinder


event PostBeginPlay()
{
	local CircleWorld_LevelBase C;
	local CircleWorld_LevelBackground B;
	
	// Get our reference to the level cylinder
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', C)
	{
		LevelBase = C;
	}
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBackground', B)
	{
		LevelBackgrounds.AddItem(B);
	}
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewVelocity, TraceStart, TraceEnd, HitLocation, HitNormal, TraceExtent;
	local actor HitActor;
	local CircleWorld_LevelBackground B;
	
	// Set our new velocity based on the acceleration given by PlayerController
	if (Physics == PHYS_Falling)
	{
		CircleForce = (CircleAcceleration * AirControl) / 100;
		CircleForce += LastVelocity * JumpMomentum;
		NewVelocity += (LastVelocity * MomentumFade + CircleForce);
		CircleVelocity = ClampLength(NewVelocity, GroundSpeed);
	}
	else
	{
		CircleForce = CircleAcceleration;
		NewVelocity += (LastVelocity * MomentumFade + CircleForce);
		CircleVelocity = ClampLength(NewVelocity, GroundSpeed);
	}

	// Set the values as the previous accel and velocity for the next tick
	LastAcceleration = CircleAcceleration;
	LastVelocity = CircleVelocity;
	
	// Set up some trace extents
	TraceExtent.X = 64;
	TraceExtent.Y = 64;	
	
	// Do the trace
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
	
	FlushPersistentDebugLines();
	if (CircleWorldGameInfo(WorldInfo.Game).DebugHUD)
		DrawDebugLine(TraceStart, TraceEnd, 255, 0, 0);
		
	HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, TraceExtent);
	if (CircleWorld_LevelBase(HitActor) != none)
	{
		// Trace hit the level mesh. We should immediately stop moving as we're bumping a wall.
		CircleVelocity.X = 0;
		LevelBase.PawnVelocity.X = 0;
		LastVelocity.X = 0;
	}
	
	// Check some flags
	if (Velocity.Z > 10)
	{
		// We are jumping up! Tell the AnimTree
		CirclePawnJumpUp = true;
		CirclePawnJumpDown = false;
		CirclePawnJumping = true;
	}
	else if (Velocity.Z < -10)
	{
		// We're falling straight down
		CirclePawnJumpUp = false;
		CirclePawnJumpDown = true;
		CirclePawnJumping = true;
	}	
	else
	{
		CirclePawnJumpUp = false;
		CirclePawnJumpDown = false;	
		CirclePawnJumping = false;
	}
	
	if (VSize(Velocity) > 10 || VSize(CircleVelocity) > 10)
	{
		// We are moving on the X axis, flag our movement state for AnimTree handling
		CirclePawnMoving = true;
	}
	else
	{
		CirclePawnMoving = false;
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
	
	// Needs to be set every frame to make sure we have a floor to stand on
	bForceFloorCheck = true;
	
	super.Tick(DeltaTime);
}	
	
simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector DesiredOffset;
	local rotator DesiredRot;
	local float DesiredFOV;

	if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 0)
	{
		DesiredOffset.X = Clamp(CircleVelocity.X, CameraTranslateDistance * -1, CameraTranslateDistance);
		
		// X axis
		if (CameraAlpha >= 1)
		{
			CameraOffset.X = DesiredOffset.X;
			CameraAlpha = 0;
		}
		else
		{
			CameraOffset.X = Lerp(CameraOffset.X, DesiredOffset.X, CameraAlpha);
		}
		
		out_CamLoc.Y = self.Location.Y - CameraPullback;
		out_CamLoc.X = CameraOffset.X;
		out_CamLoc.Z = Location.Z + 128;
		out_CamRot.Yaw = 16384;
		
		CameraOffset = out_CamLoc;
		CameraAlpha += fDeltaTime / CameraAdjustSpeed;
	}
	else if (CircleWorldGameInfo(WorldInfo.Game).CameraMode == 1)
	{
		CameraOffset = self.Location;
		CameraOffset.Y -= CameraPullback;
		
		DesiredRot = Rotator(Location - CameraOffset);
		DesiredRot.Yaw += (CircleVelocity.X * CameraRotateFactor) * -1;
		DesiredRot.Pitch += Velocity.Z;
		
		if (CameraAlpha >= 1)
		{
			CameraRotator = DesiredRot;
			CameraAlpha = 0;
		}
		else
		{
			CameraRotator.Yaw = Lerp(CameraRotator.Yaw, DesiredRot.Yaw, CameraAlpha);
			CameraRotator.Pitch = Lerp(CameraRotator.Pitch, DesiredRot.Pitch, CameraAlpha);
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
		
		if (CameraAlpha >= 1)
		{
			CameraFOV = DesiredFOV;
			CameraAlpha = 0;
		}
		else
		{
			CameraFOV = Lerp(CameraFOV, DesiredFOV, CameraAlpha);
		}
		
		out_CamLoc = CameraOffset;
		out_CamRot.Yaw = 16384;
		out_FOV = CameraFOV;
		
		CameraFOV = out_FOV;
		CameraAlpha += fDeltaTime / CameraAdjustSpeed;
	}
	
	return true;
}

function TakeFallingDamage();


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
	MaxJumpHeight = 1100
	JumpZ = 0900.000000
	AirControl = 0.03
	MaxFallSpeed = 1024
	JumpMomentum = 0.9
	MomentumFade = 0.2
	
	CameraPullback = 2048
	CameraAdjustSpeed = 200
	CameraTranslateDistance = 200
	CameraRotateFactor = 1
	CameraFOVFactor = 10
	
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=true
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=74.000000
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
		SkeletalMesh = SkeletalMesh'Rock.TheRock'
		AnimTreeTemplate=AnimTree'CircleWorld.Rock_Tree'
		AnimSets(0)=AnimSet'Rock.Rock_Anim'
		PhysicsAsset = PhysicsAsset'Rock.therock_Physics'
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
//		LightEnvironment=MyLightEnvironment
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
}