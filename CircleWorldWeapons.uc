//
//	CircleWorldWeapons
// This class is attached to the CirclePawn as a component, and exists only as an information holder for the weapon system.
//
class CircleWorldWeapons extends Component;

// First the base weapons. Player always has these, and when an upgrade is discarded he goes back to these settings.

// Blaster, primary fire
struct BlasterBase
{
	var string HUDName;
	var float FireCooldown;
	var class<CircleWorldItemProjectile> ProjectileClass;
	
	structdefaultproperties
	{
		HUDName = "Blaster";
		FireCooldown = 0.2;
		ProjectileClass = class'CircleWorldItemProjectile_Blaster';
	}
};

// Upgrade 1, rapid fire. Modifies fire cooldown time.
struct BlasterUpgrade1Base
{
	var float FireCooldown;
	var class<CircleWorldItemProjectile> ProjectileClass;
	
	structdefaultproperties
	{
		FireCooldown = 0.07;
		ProjectileClass = class'CircleWorldItemProjectile_Blaster';
	}
};

// Upgrade 2 is spread fire. Nothing is modified, it just flags a boolean in the pawn.


// Lobber, secondary fire
struct LobberBase
{
	var string HUDName;
	var float FireCooldown;
	var class<CircleWorldItemProjectile> ProjectileClass;
	
	structdefaultproperties
	{
		HUDName = "Lobber";
		FireCooldown = 0.75;
		ProjectileClass = class'CircleWorldItemProjectile_Lobber';
	}
};

// Upgrade 1, bouncey projectile. Modifies the projectile class.
struct LobberUpgrade1Base
{
	var float FireCooldown;
	var class<CircleWorldItemProjectile> ProjectileClass;
	
	structdefaultproperties
	{
		FireCooldown = 0.75;
		ProjectileClass = class'CircleWorldItemProjectile_LobberBounce';
	}
};

// Upgrade 2, mine spawner. Modifies projectile class.
struct LobberUpgrade2Base
{
	var float FireCooldown;
	var class<CircleWorldItemProjectile> ProjectileClass;
	
	structdefaultproperties
	{
		FireCooldown = 0.75;
		ProjectileClass = class'CircleWorldItemProjectile_LobberMine';
	}
};

// Now actually declare variables of the types outlined above.
var BlasterBase Blaster;
var BlasterUpgrade1Base BlasterUpgrade1;
var LobberBase Lobber;
var LobberUpgrade1Base LobberUpgrade1;
var LobberUpgrade2Base LobberUpgrade2;
