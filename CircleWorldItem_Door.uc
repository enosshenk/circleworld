//
// CircleWorldItem_Door
// A CWItem subclass that blocks players until opened. Can be locked or not.
//

class CircleWorldItem_Door extends Actor
	ClassGroup(CircleWorld)
	placeable;
	
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
var() SkeletalMeshComponent SkeletalMeshComponent;			// Mesh used for the door
var() bool DoorStayOpen;								// Does this door stay opened, or does it shut after a time
var() float DoorStayOpenTime;							// If DoorStayOpen is false, this is how long the door remains open before closing again
var() bool IsLocked;									// True if door requires a key
var() EDoorKeys KeyRequired;							// The key required to open this door
var() SoundCue OpenSound;								// Sound played when door opens
var() SoundCue CloseSound;								// Sound played when door closes

// Internal Variables
var float DoorStayOpenTimeElapsed;						// Elapsed time open
var EDoorState DoorState;								// Door open/closed state at level start

var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;
var rotator InitialLevelRot;

event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	SetPhysics(PHYS_Rotating);
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	
	
	InitialLocation = Location;

	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
//	`log("Emitter Initial Polar: R" $InitialLocationPolar.X$ " A" $InitialLocationPolar.Y);
//	`log("Emitter Initial Cartesian: " $InitialLocation);
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	InitialRotation = Rotation;
	
	InitialLevelRot = LevelBase.Rotation;
	
	// Set up collision because it doesn't work
	SetCollisionType(COLLIDE_BlockAll);
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation;
	local rotator NewRotation;

	// Movement stuff
	if (!DoorStayOpen && DoorState == D_Open)
	{
		// Update open timer
		DoorStayOpenTimeElapsed += DeltaTime;
		if (DoorStayOpenTimeElapsed >= DoorStayOpenTime)
		{
			// Shut the door
			CloseDoor();
		}
	}
	
	// Check the level base for rotation change
	LocationPolar.Y = (InitialLevelRot.Pitch + LevelBase.Rotation.Pitch * -1) + InitialLocationPolar.Y;

	// Set new cartesian location based on our polar coordinates
	NewLocation.X = InitialLocationPolar.X * cos(LocationPolar.Y * UnrRotToRad);
	NewLocation.Z = InitialLocationPolar.X * sin(LocationPolar.Y * UnrRotToRad);
	NewLocation.Y = Location.Y;
	SetLocation(NewLocation);
	
	// Set new rotation based on our polar angular value
	NewRotation = Rotation;

	NewRotation.Pitch = InitialRotation.Pitch + LocationPolar.Y - 16384;		// Subtract 16384 because UnrealEngine sets 0 rotation as 3 oclock position

	SetRotation(NewRotation);
	
	super.Tick(DeltaTime);
}

function OpenDoor()
{
	if (DoorState != D_Open)
	{
		if (IsLocked)
		{
			// Door is locked, see if the player has the right key
			switch (KeyRequired)
			{
				case K_Red:
					if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasRedKey)
					{
						IsLocked = false;
						DoorState = D_Open;
						SetCollisionType(COLLIDE_NoCollision);
						DoorStayOpenTimeElapsed = 0;
						PlaySound(OpenSound);
					}
					break;
				case K_Green:
					if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasGreenKey)
					{
						IsLocked = false;
						DoorState = D_Open;
						SetCollisionType(COLLIDE_NoCollision);
						DoorStayOpenTimeElapsed = 0;
						PlaySound(OpenSound);
					}
					break;
				case K_Blue:
					if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasBlueKey)
					{
						IsLocked = false;
						DoorState = D_Open;
						SetCollisionType(COLLIDE_NoCollision);
						DoorStayOpenTimeElapsed = 0;
						PlaySound(OpenSound);
					}
					break;	
			}
		}
		else
		{
			DoorState = D_Open;
			SetCollisionType(COLLIDE_NoCollision);
			DoorStayOpenTimeElapsed = 0;
			PlaySound(OpenSound);
		}
	}
}

function CloseDoor()
{
	if (DoorState != D_Closed)
	{
		DoorState = D_Closed;
		SetCollisionType(COLLIDE_BlockAll);
		PlaySound(OpenSound);
	}
}

event bool EncroachingOn(Actor Other)
{
	if (DoorState == D_Closed && CircleWorldPawn(Other) != none)
	{
		Other.TakeDamage(500, CircleWorldPawn(Other).Controller, Other.Location, VRand(), class'DmgType_Crushed');
	}
	return super.EncroachingOn(Other);
}

defaultproperties
{
	DoorStayOpen = false
	DoorStayOpenTime = 5
	DoorState = D_Closed
	
	OpenSound = SoundCue'TheCircleWorld.Sounds.dooropen1a'
	CloseSound = SoundCue'TheCircleWorld.Sounds.doorclose1a'
	
	bWorldGeometry = true
	bNoDelete = false
	bStatic = false
	bCollideComplex = true	
	CollisionType = COLLIDE_BlockAll
	TickGroup=TG_PreAsyncWork


	Begin Object Class=SkeletalMeshComponent Name=CircleSkeletalMeshComponent		
		SkeletalMesh = SkeletalMesh'TheCircleWorld.meshes.door1a'
		AnimTreeTemplate = AnimTree'TheCircleWorld.Animtree.door1a_tree'
		AnimSets(0) = AnimSet'TheCircleWorld.animset.door1a_anim'
		PhysicsAsset = PhysicsAsset'TheCircleWorld.meshes.door1a_physics'
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
	CollisionComponent=CircleSkeletalMeshComponent
	SkeletalMeshComponent=CircleSkeletalMeshComponent
	Components.Add(CircleSkeletalMeshComponent) 
}