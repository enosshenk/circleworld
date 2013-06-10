class CircleWorldWeapons extends Component;

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

var BlasterBase Blaster;
var LobberBase Lobber;