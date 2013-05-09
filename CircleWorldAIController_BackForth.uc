//
// A basic AI controller that causes a pawn to move forward until obstructed, then reverses direction
//

class CircleWorldAIController_BackForth extends AIController;

auto state Startup
{
	Begin:
	
	CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed);
	Sleep(1);
	GotoState('Moving');
}

state Moving
{
	Begin:

	if (CircleWorldEnemyPawn(Pawn).ObstructedForward || CircleWorldEnemyPawn(Pawn).HoleForward)
	{
		if (Pawn.Rotation.Yaw == 0)
		{
			Sleep(5);
			CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed);
		}
		else
		{
			Sleep(5);
			CircleWorldEnemyPawn(Pawn).SetEnemyPawnVelocity(Pawn.GroundSpeed * -1);
		}
	}
	else
	{
		Sleep(1);
		Goto 'Begin';
	}
}