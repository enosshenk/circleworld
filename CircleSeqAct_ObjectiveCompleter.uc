class CircleSeqAct_ObjectiveCompleter extends SequenceAction;

event Activated()
{
	CircleWorldGameInfo(GetWorldInfo().Game).CompleteObjective();
}

defaultproperties
{
	ObjName="CircleWorld ObjectiveCompleter"
	ObjCategory=""
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}