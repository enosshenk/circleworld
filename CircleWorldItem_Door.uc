//
// CircleWorldItem_Door
// A CWItem subclass that blocks players until opened. Can be locked or not.
//

class CircleWorldItem_Door extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;
	
enum EMoveDirection
{
	D_Up,
	D_Down
};

enum EDoorState
{
	D_Closed,
	D_Open
};

enum EDoorKeys
{
	K_Red,
	K_Blue,
	K_Green
};

// Editor Variables
var() StaticMeshComponent StaticMeshComponent;			// Mesh used for the door
var() EMoveDirection DoorOpenDirection;					// Direction the door moves when opened
var() float DoorOpenDistance;							// Distance the door moves to open
var() bool DoorStayOpen;								// Does this door stay opened, or does it shut after a time
var() float DoorStayOpenTime;							// If DoorStayOpen is false, this is how long the door remains open before closing again
var() float DoorOpenSpeed;								// Real speed the door moves at
var() bool IsLocked;									// True if door requires a key
var() EDoorKeys KeyRequired;							// The key required to open this door

// Internal Variables
var float DoorOpenDistanceElapsed;						// Elapsed motion
var float DoorStayOpenTimeElapsed;						// Elapsed time open
var bool DoorMoving;									// true when door is in motion
var EDoorState DoorState;
var int DoorMovingDirection;							// -1 = moving down 1 = moving up

event PostBeginPlay()
{
	
	// Set up collision because it doesn't work
	SetCollisionType(COLLIDE_BlockAll);
	
	// Set the initial direction
	if (DoorOpenDirection == D_Up)
		DoorMovingDirection = 1;
	else
		DoorMovingDirection = -1;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;
	

	if (!DoorMoving)
	{
		if (!DoorStayOpen && DoorState == D_Open)
		{
			DoorStayOpenTimeElapsed += DeltaTime;
			if (DoorStayOpenTimeElapsed >= DoorStayOpenTime)
			{
				// Time's up, shut the door
				DoorMoving = true;
				DoorOpenDistanceElapsed = 0;
			}
		}
	}
	else
	{
		// Door is in motion
		if (DoorMovingDirection == 1)
		{
			DoorOpenDistanceElapsed += DoorOpenSpeed;
			LocationPolar.X += DoorOpenSpeed;
		}
		else
		{
			DoorOpenDistanceElapsed -= DoorOpenSpeed;
			LocationPolar.X -= DoorOpenSpeed;
		}
			
		// See if we should stop moving
		if (Abs(DoorOpenDistanceElapsed) >= Abs(DoorOpenDistance))
		{
			// Door has completed motion
			DoorMoving = false;
			DoorStayOpenTimeElapsed = 0;
			DoorOpenDistanceElapsed = 0;
			
			// Set door state
			if (DoorMovingDirection == 1 && DoorOpenDirection == D_Up)		// Was moving up, door moves up. Set to open
				DoorState = D_Open;
			if (DoorMovingDirection == -1 && DoorOpenDirection == D_Up)		// Was moving down, door moves up. Set to closed
				DoorState = D_Closed;
			if (DoorMovingDirection == 1 && DoorOpenDirection == D_Down)	// Was moving up, door moves down. Set to closed
				DoorState = D_Closed;
			if (DoorMovingDirection == -1 && DoorOpenDirection == D_Down)	// Was moving down, door moves down. Set to open
				DoorState = D_Open;
				
			// Set our new travel direction
			if (DoorMovingDirection == 1)
				DoorMovingDirection = -1;
			else
				DoorMovingDirection = 1;
		}
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

function OpenDoor()
{
	if (!DoorMoving && DoorState == D_Closed && !IsLocked)
	{
		// Door is closed. Let's change that.
		DoorMoving = true;			
	}
	else if (IsLocked)
	{
		// Door is locked, see if the player has the right key
		switch (KeyRequired)
		{
			case K_Red:
				if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasRedKey)
				{
					IsLocked = false;
					DoorMoving = true;
				}
				break;
			case K_Green:
				if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasGreenKey)
				{
					IsLocked = false;
					DoorMoving = true;
				}
				break;
			case K_Blue:
				if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasBlueKey)
				{
					IsLocked = false;
					DoorMoving = true;
				}
				break;
		}
	}
}

event bool EncroachingOn(Actor Other)
{
	if (DoorMoving && CircleWorldPawn(Other) != none)
	{
		Other.TakeDamage(500, CircleWorldPawn(Other).Controller, Other.Location, VRand(), class'DmgType_Crushed');
	}
	return super.EncroachingOn(Other);
}

defaultproperties
{
	DoorOpenDirection = D_Up
	DoorOpenDistance = 512
	DoorStayOpen = false
	DoorStayOpenTime = 5
	DoorOpenSpeed = 10
	
	DoorState = D_Closed
	
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