//
// A basic AI controller that causes a pawn to move forward until obstructed, then reverses direction
//

class CircleWorldAIController_BackForth extends AIController;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
	if (inPawn.Controller != None)
	{
		inPawn.Controller.UnPossess();
	}

	inPawn.PossessedBy(self, bVehicleTransition);
	Pawn = inPawn;
}

auto state Startup
{
	Begin:
	`log("AI startup");
	Sleep(5);	
	CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed);
	GotoState('Moving');
}

state Moving
{
	Begin:

	if (CircleWorldEnemyPawn(Pawn).ObstructedForward || CircleWorldEnemyPawn(Pawn).HoleForward)
	{
		CircleWorldEnemyPawn(Pawn).EnemyPawnVelocity = 0;
		if (!CircleWorldEnemyPawn(Pawn).EnemyPawnMovingRight)
		{
			// Turn around and head right
			CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed);
			`log("Was moving left, setting speed to " $Pawn.GroundSpeed);
		}
		else if (CircleWorldEnemyPawn(Pawn).EnemyPawnMovingRight)
		{
			// Turn around and head left
			CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed * -1);
			`log("Was moving right, setting speed to " $Pawn.GroundSpeed * -1);
		}
	}

	// Let the pawn keep moving
	Sleep(1);
	Goto 'Begin';
}