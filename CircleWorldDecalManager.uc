class CircleWorldDecalManager extends Actor
	notplaceable;
	
var array< CircleWorldDecal> Decals;
var int MaxDecals;

function CircleWorldDecal SpawnDecal(MaterialInterface Mat, vector SpawnLocation, rotator SpawnRotator, float StayTime, float Radius)
{
	local CircleWorldDecal NewDecal;
	
	if (Decals.Length >= MaxDecals)
	{
		// Remove first decal
		Decals[0].Destroy();
		Decals.RemoveItem(Decals[0]);

		// Spawn decal and init
		NewDecal = spawn(class'CircleWorldDecal', self, , SpawnLocation, SpawnRotator,, true);
		NewDecal.InitDecal(Mat, StayTime, Radius);
		// Add to array
		Decals.AddItem(NewDecal);
		// Return the decal
		return NewDecal;		
	}
	else
	{
		// Spawn decal and init
		NewDecal = spawn(class'CircleWorldDecal', self, , SpawnLocation, SpawnRotator,, true);
		NewDecal.InitDecal(Mat, StayTime, Radius);
		// Add to array
		Decals.AddItem(NewDecal);
		// Return the decal
		return NewDecal;
	}
}

function RemoveDecal(CircleWorldDecal Decal)
{
	Decals.RemoveItem(Decal);
}

defaultproperties
{
	MaxDecals = 100
}