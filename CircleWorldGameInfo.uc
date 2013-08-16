class CircleWorldGameInfo extends UDKGame;

var bool DebugHUD;
var int EnergyLevel;
var int CameraMode;
var CircleWorldPawn CirclePawn;

// Vars exposed for future HUD usage
var float CircleLevelRotation;							// Current rotation value of the level
var int CurrentObjectiveIndex;
var string CurrentObjectiveName;						// Current objective short name
var string CurrentObjectiveOrders;						// Current objective orders text
var CircleWorldObjectiveMarker CurrentObjectiveMarker;	// Current objective marker location
var float PlayerHealth;									// Current player health
var float PlayerBoostFuel;								// Current player jetpack fuel

// This function is called to respawn the player when dead. We need to modify it.
function RestartPlayer(Controller NewPlayer)
{
	// Temp hack to make objectives show
	UpdateObjectives(0);
	
	super.RestartPlayer(NewPlayer);
}

// Function to spawn a new pawn for the player
function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{

	return super.SpawnDefaultPawnFor(NewPlayer, StartSpot);
}

function UpdateObjectives(int CurrentObjective)
{
	// Update index
	CurrentObjectiveIndex = CurrentObjective;
	
	CurrentObjectiveName = CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].ObjectiveName;
	CurrentObjectiveOrders = CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].ObjectiveOrders;
	
	// Check if objective is a timer
	if (CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].ObjectiveType == O_Timer)
	{
		SetTimer(CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].ObjectiveTime, false, 'TimerCompleteObjective');
	}
	
	// Enable marker if applicable
	if (CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].Marker != none)
	{
		CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].Marker.EnableMarker();
		CurrentObjectiveMarker = CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective].Marker;
	}
	else
	{
		CurrentObjectiveMarker = none;
	}
	
	// Disable last objective marker if applicable
	if (CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective - 1].Marker != none)
	{
		CircleWorldMapInfo(WorldInfo.GetMapInfo()).Objectives[CurrentObjective - 1].Marker.DisableMarker();
	}
}

function TimerCompleteObjective()
{
	TriggerRemoteKismetEvent(name(CurrentObjectiveName));
	UpdateObjectives(CurrentObjectiveIndex + 1);
}

function CompleteObjective()
{
	UpdateObjectives(CurrentObjectiveIndex + 1);
}

function TriggerRemoteKismetEvent(name EventName)
{
	local array<SequenceObject> AllSeqEvents;
	local Sequence GameSeq;
	local int i;

	GameSeq = WorldInfo.GetGameSequence();
	if (GameSeq != None)
	{
		// reset the game sequence
		GameSeq.Reset();

		// find any Level Reset events that exist
		GameSeq.FindSeqObjectsByClass(class'SeqEvent_RemoteEvent', true, AllSeqEvents);

		// activate them
		for (i = 0; i < AllSeqEvents.Length; i++)
		{
			if(SeqEvent_RemoteEvent(AllSeqEvents[i]).EventName == EventName)
				SeqEvent_RemoteEvent(AllSeqEvents[i]).CheckActivate(WorldInfo, None);
		}
	}
}

defaultproperties
{
	DebugHUD = true
	PlayerControllerClass = class'CircleWorldGame.CircleWorldPlayerController'
	DefaultPawnClass = class'CircleWorldGame.CircleWorldPawn'
	HUDType = class'CircleWorldGame.CircleWorldHUD'
}