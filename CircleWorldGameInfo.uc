class CircleWorldGameInfo extends UDKGame;

var bool DebugHUD;
var int EnergyLevel;
var int CameraMode;
var CircleWorldPawn CirclePawn;
var CircleWorld_LevelBase LevelBase;

var CircleWorldDecalManager CircleDecalManager;

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
	local NavigationPoint startSpot;
	local int TeamNum, Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LP; 
	local PlayerController PC; 

	if( bRestartLevel && WorldInfo.NetMode!=NM_DedicatedServer && WorldInfo.NetMode!=NM_ListenServer )
	{
		`warn("bRestartLevel && !server, abort from RestartPlayer"@WorldInfo.NetMode);
		return;
	}
	// figure out the team number and find the start spot
	TeamNum = ((NewPlayer.PlayerReplicationInfo == None) || (NewPlayer.PlayerReplicationInfo.Team == None)) ? 255 : NewPlayer.PlayerReplicationInfo.Team.TeamIndex;
	StartSpot = FindPlayerStart(NewPlayer, TeamNum);

	// if a start spot wasn't found,
	if (startSpot == None)
	{
		// check for a previously assigned spot
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
			`warn("Player start not found, using last start spot");
		}
		else
		{
			// otherwise abort
			`warn("Player start not found, failed to restart player");
			return;
		}
	}
	
	// Force levelbase rotation
	LevelBase.ForceRotation(0);
	
	// try to create a pawn to use of the default class for this player
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = SpawnDefaultPawnFor(NewPlayer, StartSpot);
	}
	if (NewPlayer.Pawn == None)
	{
		`log("failed to spawn player at "$StartSpot);
		NewPlayer.GotoState('Dead');
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		}
	}
	else
	{
		// initialize and start it up
		NewPlayer.Pawn.SetAnchor(startSpot);
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).TimeMargin = -0.1;
			startSpot.AnchoredPawn = None; // SetAnchor() will set this since IsHumanControlled() won't return true for the Pawn yet
		}
		NewPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.Pawn.PlayTeleportEffect(true, true);
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);

		if (!WorldInfo.bNoDefaultInventoryForPlayer)
		{
			AddDefaultInventory(NewPlayer.Pawn);
		}
		SetPlayerDefaults(NewPlayer.Pawn);

		// activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None &&
					SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
				{
					SpawnedEvent.SpawnPoint = startSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	// To fix custom post processing chain when not running in editor or PIE.
	PC = PlayerController(NewPlayer);
	if (PC != none)
	{
		LP = LocalPlayer(PC.Player); 
		if(LP != None) 
		{ 
			LP.RemoveAllPostProcessingChains(); 
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
			if(PC.myHUD != None)
			{
				PC.myHUD.NotifyBindPostProcessEffects();
			}
		} 
	}
	
	// Temp hack to make objectives show
	UpdateObjectives(0);
	
	super.RestartPlayer(NewPlayer);
}

event PreBeginPlay()
{
	CircleDecalManager = Spawn(class'CircleWorldDecalManager');
	
	super.PreBeginPlay();
}

event PostBeginPlay()
{
	local CircleWorld_LevelBase LB;
	
	foreach WorldInfo.AllActors(class'CircleWorld_LevelBase', LB)
	{
		LevelBase = LB;
	}
	
	super.PostBeginPlay();
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