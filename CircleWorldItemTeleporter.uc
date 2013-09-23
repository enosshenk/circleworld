class CircleWorldItemTeleporter extends Actor
	ClassGroup(CircleWorld)
	placeable;
	
var CircleWorld_LevelBase LevelBase;				// The level base used
var vector2d LocationPolar;							// X value is Radial, Y value is Angular
var vector2d InitialLocationPolar;
var vector InitialLocation;
var rotator InitialRotation;
var rotator InitialLevelRot;

var() ParticleSystemComponent ParticleSystemComponent;	// Idle particle effects
var() ParticleSystemComponent ActivationParticleSystemComponent;	// Particle system to trigger when this teleporter is used
var() SoundCue ActivationSound;					// Sound to play when this teleporter is used

var() enum ETeleporterType
{
	T_Source,
	T_Destination,
	T_TwoWay
} TeleporterType;								// Type of teleporter this is

var() CircleWorldItemTeleporter Destination;	// Reference to another teleporter for destination. Unused if this teleporter is destination type.

var bool TeleporterDisabled;					// Used to prevent immediate re-teleports from destination
var float FallbackEnableTime;					// If untouch fails for unflagging the disable, it will re-enable after this time delay
var float FallbackEnableTimeElapsed;
var bool pendingTeleport;

simulated event PostBeginPlay()
{
	local CircleWorld_LevelBase L;
	
	SetPhysics(PHYS_Rotating);
	SetCollisionType(COLLIDE_TouchAll);
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', L)
	{
		LevelBase = L;
	}	
	
	InitialLocation = Location;

	// Get our initial polar coordinates from our cartesian coordinates
	InitialLocationPolar.X = Sqrt(Location.X ** 2 + Location.Z ** 2);
	InitialLocationPolar.Y = atan2(Location.Z, Location.X) * RadToUnrRot;
	
	LocationPolar.X = InitialLocationPolar.X;
	LocationPolar.Y = InitialLocationPolar.Y;
	
	InitialRotation = Rotation;
	
	InitialLevelRot = LevelBase.Rotation;
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	local vector NewLocation, DestVect;
	local rotator NewRotation;
	
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
	
	// Update disable fallback time
	FallbackEnableTimeElapsed += DeltaTime;
	if (FallbackEnableTimeElapsed >= FallbackEnableTime)
	{
		TeleporterDisabled = false;
		FallbackEnableTimeElapsed = 0;
	}
	
	if (pendingTeleport)
	{
		// Touched by player while active. Let's do this.
		pendingTeleport = false;
		TeleporterDisabled = true;	
		Destination.NotifyArrival();
		
		// Move player to destination
		DestVect.X = 0;
		DestVect.Z = Destination.InitialLocationPolar.X;
		DestVect.Y = Destination.Location.Y;
		
		`log("Teleporting to " $DestVect);
		CircleWorldGameInfo(WorldInfo.Game).CirclePawn.SetLocation(DestVect);
		CircleWorldGameInfo(WorldInfo.Game).CirclePawn.IsTeleporting = false;
		
		// Tell destination to play effects
		Destination.PlayEffects();		
	}
	
	super.Tick(DeltaTime);
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local vector DestVect;
	
	if (CircleWorldPawn(Other) != none && !TeleporterDisabled && Destination != none && (TeleporterType == T_TwoWay || TeleporterType == T_Source))
	{	
		// Force level rotation to put destination at 0 rot
	/*	if (Destination.InitialLocationPolar.Y > 32768)
		{
			LevelBase.ForceRotation(LevelBase.Rotation.Pitch - abs(Destination.InitialLocationPolar.Y));
		}
		else
		{
			LevelBase.ForceRotation(LevelBase.Rotation.Pitch + abs(Destination.InitialLocationPolar.Y));
		} */
		LevelBase.ForceRotation(Destination.LocationPolar.Y);
		CircleWorldPawn(Other).IsTeleporting = true;
		pendingTeleport = true;
		`log("Destination angular is " $Destination.LocationPolar.Y);
	}
}

event UnTouch(Actor Other)
{
	if (CircleWorldPawn(Other) != none && TeleporterDisabled)
	{
		// Player has left our collision cylinder, re-enable for teleporting
		TeleporterDisabled = false;	
		FallbackEnableTimeElapsed = 0;
	}	
}

function NotifyArrival()
{
	//UpdateLocation();
	Destination.NotifyArrival();
}

function UpdateLocation()
{
	local vector NewLocation;
	local rotator NewRotation;
	
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
}

function PlayEffects()
{
	// Turn on activation effects
	ActivationParticleSystemComponent.SetActive(true);
	ActivationParticleSystemComponent.OnSystemFinished = TOnSystemFinished;
	
	// Play sound
	PlaySound(ActivationSound);
}

function TOnSystemFinished(ParticleSystemComponent System)
{
	System.SetActive(false);
}

defaultproperties
{
	TeleporterType = T_TwoWay
	FallbackEnableTime = 20
	ActivationSound = SoundCue'TheCircleWorld.Sounds.halt'
	
	bNoDelete = false
	bStatic = false
	
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=64.000000
		CollisionHeight=128.000000
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Emitter'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bIsScreenSizeScaled=True
		ScreenSize=0.0025
		SpriteCategoryName="Effects"
	End Object
	Components.Add(Sprite)

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
		SecondsBeforeInactive=1
	End Object
	ParticleSystemComponent=ParticleSystemComponent0
	Components.Add(ParticleSystemComponent0)
	
	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent1
		Template=ParticleSystem'TheCircleWorld.FX.EnemyPawn_exp1'
		SecondsBeforeInactive=1
		bAutoActivate=false
	End Object
	ActivationParticleSystemComponent=ParticleSystemComponent1
	Components.Add(ParticleSystemComponent1)

	Begin Object Class=ArrowComponent Name=ArrowComponent0
		ArrowColor=(R=0,G=255,B=128)
		ArrowSize=1.5
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bTreatAsASprite=True
		SpriteCategoryName="Effects"
	End Object
	Components.Add(ArrowComponent0)
}