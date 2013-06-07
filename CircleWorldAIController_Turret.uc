//
// AI Controller for turret enemy
// Keeps track of player, if player is visible and shootable, transition to a fire state
//
class CircleWorldAIController_Turret extends AIController;

var CircleWorldEnemyPawn_Turret Turret;
var vector HitLocation, HitNormal;
var actor HitActor;
		
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	if (inPawn.Controller != None)
	{
		inPawn.Controller.UnPossess();
	}

	inPawn.PossessedBy(self, bVehicleTransition);
	Turret = CircleWorldEnemyPawn_Turret(inPawn);
}

// Initial state makes sure we have a ref to the player then passes to waiting
auto state Startup
{
	Begin:
	
	if (Turret.PlayerTarget == none)
	{
		// This shouldn't happen but try to find a target
		Turret.FindPlayer();
	}
	else
	{
		GotoState('Waiting');
	}
	
	Sleep(1);
	goto 'Begin';
}

// State for sitting there waiting for a target
state Waiting
{
	Begin:
	
	if (FastTrace(Turret.PlayerTarget.Location, Turret.Location))
	{
		`log("Turret saw player");
		
		// Check if player is within turret aim range
		if (VSize(Turret.Location - Turret.PlayerTarget.Location) <= Turret.TurretAimRange)
		{
			// In range, toggle aiming on
			Turret.IsAiming = true;
			`log("Player in range to aim");
		}
		else
		{
			// Disengage aiming
			Turret.IsAiming = false;
		}
		
		if (VSize(Turret.Location - Turret.PlayerTarget.Location) <= Turret.TurretRange)
		{
			// Player is in LOS, and is in range. Go to firing state.
			GotoState('Firing');
		}
		else
		{
			`log("Player out of LoS or range");
		}
	}
	else
	{
		`log("No LoS to player");
	}
	
	Sleep(1);
	Goto 'Begin';
}

// State for actively firing shit at the player
state Firing
{
	Begin:
	
	`log("Fire state begin");
	if (FastTrace(Turret.PlayerTarget.Location, Turret.Location))
	{
		// Check if player is within turret aim range
		if (VSize(Turret.Location - Turret.PlayerTarget.Location) <= Turret.TurretAimRange)
		{
			// In range, toggle aiming on
			Turret.IsAiming = true;
			`log("Player in range to aim");
		}
		else
		{
			// Disengage aiming
			Turret.IsAiming = false;
			GotoState('Waiting');
		}
		
		if (VSize(Turret.Location - Turret.PlayerTarget.Location) <= Turret.TurretRange)
		{
			Sleep(0.2);
			Turret.ShootAtPlayer();
			Sleep(Turret.TurretFireRate);
			GotoState('Firing');
		}
		else
		{
			GotoState('Waiting');
		}
	}
	else
	{
		GotoState('Waiting');
	}
}

