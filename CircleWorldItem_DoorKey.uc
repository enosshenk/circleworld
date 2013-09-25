class CircleWorldItem_DoorKey extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;

var() ParticleSystemComponent ParticleSystemComponent;
var() enum EDoorKeys
{
	K_Red,
	K_Blue,
	K_Green
} KeyGiven;													// Key given to the player when this pickup is touched

var() SoundCue PickupSound;									// Sound played when picked up

var bool PickupUnavailable;
	
event PostBeginPlay()
{	
	SetCollisionType(COLLIDE_TouchAll);
	
	SetTimer(1, true, 'KeyTick');
	
	super.PostBeginPlay();
}

function KeyTick()
{
	switch (KeyGiven)
	{
		case K_Red:
			if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasRedKey)
			{
				PickupUnavailable = true;
				SetHidden(true);
			}
			else
			{
				PickupUnavailable = false;
				SetHidden(false);			
			}
			break;
		case K_Green:
			if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasGreenKey)
			{
				PickupUnavailable = true;
				SetHidden(true);
			}
			else
			{
				PickupUnavailable = false;
				SetHidden(false);			
			}
			break;
		case K_Blue:
			if (CircleWorldGameInfo(WorldInfo.Game).CirclePawn.HasBlueKey)
			{
				PickupUnavailable = true;
				SetHidden(true);
			}
			else
			{
				PickupUnavailable = false;
				SetHidden(false);			
			}
			break;
	}
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldPawn(Other) != none && !PickupUnavailable)
	{
		switch (KeyGiven)
		{
			case K_Red:
				CircleWorldPawn(Other).HasRedKey = true;
				PickupUnavailable = true;
				SetHidden(true);
				break;
			case K_Green:
				CircleWorldPawn(Other).HasGreenKey = true;
				PickupUnavailable = true;
				SetHidden(true);
				break;
			case K_Blue:
				CircleWorldPawn(Other).HasBlueKey = true;
				PickupUnavailable = true;
				SetHidden(true);
				break;
		}
		
		PickupUnavailable = true;
		SetHidden(true);
		PlaySound(PickupSound);
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	
	
defaultproperties
{
	PickupSound = SoundCue'TheCircleWorld.Sounds.PlayerLand'
	
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