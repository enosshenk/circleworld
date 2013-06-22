class CircleWorldItem_WeaponUpgrade extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;

var() ParticleSystemComponent ParticleSystemComponent;		// Particle system used for this pickup
var() bool PickupRespawn;									// Can this pickup respawn
var() float PickupRespawnTime;								// Time in seconds for pickup to respawn
var() enum EUpgradeGiven
{
	BlasterRapidFire,
	BlasterSpreadShot,
	LobberBounceShot,
	LobberMineShot
} UpgradeGiven;												// Upgrade given to player when this pickup is touched

var float PickupRespawnTimeElapsed;
var bool PickupUnavailable;	

event PostBeginPlay()
{	
	SetCollisionType(COLLIDE_TouchAll);
	
	super.PostBeginPlay();
}

event Tick(float DeltaTime)
{
	if (PickupRespawn && PickupUnavailable)
	{
		PickupRespawnTimeElapsed += DeltaTime;
		
		if (PickupRespawnTimeElapsed >= PickupRespawnTime)
		{
			PickupUnavailable = false;
			SetHidden(false);
		}
	}
	super.Tick(DeltaTime);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (CircleWorldPawn(Other) != none)
	{
		switch (UpgradeGiven)
		{
			case BlasterRapidFire:
				CircleWorldPawn(Other).AddPrimaryUpgrade(1);
				if (PickupRespawn)
				{
					PickupUnavailable = true;
					SetHidden(true);
				}
				else
				{
					self.Destroy();
				}
				break;
			case BlasterSpreadShot:
				CircleWorldPawn(Other).AddPrimaryUpgrade(2);
				if (PickupRespawn)
				{
					PickupUnavailable = true;
					SetHidden(true);
				}
				else
				{
					self.Destroy();
				}
				break;
			case LobberBounceShot:
				CircleWorldPawn(Other).AddSecondaryUpgrade(1);
				if (PickupRespawn)
				{
					PickupUnavailable = true;
					SetHidden(true);
				}
				else
				{
					self.Destroy();
				}
				break;
			case LobberMineShot:
				CircleWorldPawn(Other).AddSecondaryUpgrade(2);
				if (PickupRespawn)
				{
					PickupUnavailable = true;
					SetHidden(true);
				}
				else
				{
					self.Destroy();
				}
				break;
		}
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	
	
defaultproperties
{
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