//
// CircleWorldItem_Lift
// A moving platform that can be ridden.
// Must be positioned at the BOTTOM of travel for vertical lifts, or at the LEFT of travel for horizontal lifts
//

class CircleWorldItem_Lift extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;

var() StaticMeshComponent StaticMeshComponent;

enum ELiftType
{
	CW_Vertical,
	CW_Horizontal,
	CW_ContinuousHorizontal
};

enum EContDirection
{
	D_Left,
	D_Right
};

var() ELiftType CircleLiftType;							// Type of lift being used
var() EContDirection ContDirection;						// If type is continuous horizontal, direction of travel
var() float CircleLiftWaitTime;							// Time this lift will wait at either position before moving. No effect on continous horizontal
var() float CircleLiftTravel;							// Vertical: The distance in Unreal Units this lift will travel before stopping  Horizontal: How many Unreal Rotation Units the lift moves before stopping
var() float CircleLiftSpeed;							// Vertical: Distance this lift moves in Unreal Units per tick  Horizontal: Distance this lift moves in Unreal Rotation Units per tick

var bool IsWaiting;										// True if we're waiting at a stop
var int TravelDirection;								// 1 if we're ascending, -1 if we're descending
var float WaitTimeElapsed;								// How much time has passed since we began waiting
var float TravelElapsed;								// How far we've moved from our start point

event PostBeginPlay()
{
	// Set up collision because it doesn't work
	SetCollisionType(COLLIDE_BlockAll);
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	
	switch (CircleLiftType)
	{	
		case CW_Vertical:
			if (IsWaiting)
			{
				// Append our time to our elapsed wait time
				WaitTimeElapsed += DeltaTime;
				// See if we've run out of wait time
				if (WaitTimeElapsed >= CircleLiftWaitTime)
				{
					IsWaiting = false;
					TravelElapsed = 0;
				}
			}
			else
			{
				// Lift is in motion
				if (TravelDirection == 1)
				{
					TravelElapsed += CircleLiftSpeed;
					LocationPolar.X += CircleLiftSpeed;
				}
				else
				{
					TravelElapsed -= CircleLiftSpeed;
					LocationPolar.X -= CircleLiftSpeed;
				}
					
				// See if we should stop moving
				if (Abs(TravelElapsed) >= Abs(CircleLiftTravel))
				{
					// Stop the lift I wanna get off!
					IsWaiting = true;
					WaitTimeElapsed = 0;
					
					// Set our travel direction
					if (TravelDirection == 1)
						TravelDirection = -1;
					else
						TravelDirection = 1;
				}
			}
			break;

		case CW_Horizontal:
			if (IsWaiting)
			{
				// Append our time to our elapsed wait time
				WaitTimeElapsed += DeltaTime;
				// See if we've run out of wait time
				if (WaitTimeElapsed >= CircleLiftWaitTime)
				{
					IsWaiting = false;
					TravelElapsed = 0;
				}
			}
			else
			{
				// Lift is in motion
				if (TravelDirection == 1)
				{
					TravelElapsed += CircleLiftSpeed;
					InitialLocationPolar.Y += CircleLiftSpeed;
				}
				else
				{
					TravelElapsed -= CircleLiftSpeed;
					InitialLocationPolar.Y -= CircleLiftSpeed;
				}
					
				// See if we should stop moving
				if (Abs(TravelElapsed) >= Abs(CircleLiftTravel))
				{
					// Stop the lift I wanna get off!
					IsWaiting = true;
					WaitTimeElapsed = 0;
					
					// Set our travel direction
					if (TravelDirection == 1)
						TravelDirection = -1;
					else
						TravelDirection = 1;
				}
			}
			break;

			case CW_ContinuousHorizontal:
				// Move the lift
				if (ContDirection == D_Left)
				{
					InitialLocationPolar.Y -= CircleLiftSpeed;
					if (InitialLocationPolar.Y < 0)
						InitialLocationPolar.Y = 65536;
					if (InitialLocationPolar.Y > 65536)
						InitialLocationPolar.Y = 0;
				}
				else
				{
					InitialLocationPolar.Y += CircleLiftSpeed;
					if (InitialLocationPolar.Y < 0)
						InitialLocationPolar.Y = 65536;
					if (InitialLocationPolar.Y > 65536)
						InitialLocationPolar.Y = 0;
				}
			break;
	}
	
	// Check the level base for rotation change
	LocationPolar.Y = (LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = LocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = LocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);
	
	// Set new rotation based on our polar angular value
	NewRotation = Rotation;
	NewRotation.Pitch = LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position
	SetRotation(NewRotation);
}

event bool EncroachingOn(Actor Other)
{
	local Pawn P;
	local vector TempVect;
	local vector Height, HitLocation, HitNormal;
	
	P = Pawn(Other);
	if (P != none)
	{
		Height = P.GetCollisionHeight() * vect(0,0,1);
		
		if (TraceComponent(HitLocation, HitNormal, StaticMeshComponent, P.Location - Height, P.Location + Height, P.GetCollisionExtent()))
		{		
			if (P.Location.Z < Location.Z)
			{
				TempVect.Z = P.Mesh.Bounds.BoxExtent.Z;
				P.SetLocation(HitLocation + Height + TempVect);
				//P.Velocity.Z += CircleLiftSpeed;
				//P.SetPhysics(PHYS_Falling);
			}
		}
	}
	`log("Encroached on " $Other);
	
	return false;
}
	
defaultproperties
{
	CircleLiftType = CW_Vertical
	CircleLiftWaitTime = 10
	CircleLiftTravel = 1024
	CircleLiftSpeed = 10
	
	IsWaiting = true
	TravelDirection = 1
	
	bWorldGeometry = true
	bNoDelete = false
	bStatic = false
	bCollideComplex = true	
	CollisionType = COLLIDE_BlockAll
	TickGroup=TG_PreAsyncWork
	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'EngineMeshes.Cube'
		bUsePrecomputedShadows=FALSE
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}