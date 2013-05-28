//
// AI Controller for turret enemy
// Keeps track of player, if player is visible and shootable, transition to a fire state
//
class CircleWorldAIController_Turret extends AIController;

var CircleWorldEnemyPawn_Turret Pawn;
var vector HitLocation, HitNormal;
var actor HitActor;
		
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	if (inPawn.Controller != None)
	{
		inPawn.Controller.UnPossess();
	}

	inPawn.PossessedBy(self, bVehicleTransition);
	Pawn = CircleWorldEnemyPawn_Turret(inPawn);
}

// Initial state makes sure we have a ref to the player then passes to waiting
auto state Startup
{
	Begin:
	
	if (Pawn.PlayerTarget == none)
	{
		// This shouldn't happen but try to find a target
		Pawn.FindPlayer();
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
	
	if (FastTrace(Pawn.PlayerTarget.Location, Pawn.Location))
	{
		`log("Turret saw player");
		
		// Check if player is within turret aim range
		if (VSize(Pawn.Location - Pawn.PlayerTarget.Location) <= Pawn.TurretAimRange)
		{
			// In range, toggle aiming on
			Pawn.IsAiming = true;
			`log("Player in range to aim");
		}
		else
		{
			// Disengage aiming
			Pawn.IsAiming = false;
		}
		
		if (VSize(Pawn.Location - Pawn.PlayerTarget.Location) <= Pawn.TurretRange)
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
	if (FastTrace(Pawn.PlayerTarget.Location, Pawn.Location))
	{
		// Check if player is within turret aim range
		if (VSize(Pawn.Location - Pawn.PlayerTarget.Location) <= Pawn.TurretAimRange)
		{
			// In range, toggle aiming on
			Pawn.IsAiming = true;
			`log("Player in range to aim");
		}
		else
		{
			// Disengage aiming
			Pawn.IsAiming = false;
			GotoState('Waiting');
		}
		
		if (VSize(Pawn.Location - Pawn.PlayerTarget.Location) <= Pawn.TurretRange)
		{
			Sleep(0.2);
			Pawn.ShootAtPlayer();
			Sleep(Pawn.TurretFireRate);
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

