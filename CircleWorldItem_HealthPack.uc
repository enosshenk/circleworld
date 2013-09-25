class CircleWorldItem_HealthPack extends CircleWorldItem
	ClassGroup(CircleWorld)
	placeable;

var() ParticleSystemComponent ParticleSystemComponent;
var() bool PickupRespawn;									// Can this pickup respawn
var() float PickupRespawnTime;								// Time in seconds for pickup to respawn
var() float HealAmount;										// Amount the pawn is healed when this pickup is taken
var() SoundCue PickupSound;

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
		// Touched by player. Give him some health.
		Other.HealDamage(HealAmount, Pawn(Other).Controller, class'DamageType');
		if (PickupRespawn)
		{
			PickupUnavailable = true;
			SetHidden(true);
			PlaySound(PickupSound);
		}
		else
		{
			PlaySound(PickupSound);
			self.Destroy();
		}
	}
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}	
	
defaultproperties
{
	HealAmount = 50
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