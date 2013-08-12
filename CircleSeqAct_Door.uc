class CircleSeqAct_Door extends SequenceAction;

var() enum EDoorCommand
{
	D_Open,
	D_Close,
	D_Toggle
} DoorCommand;

var CircleWorldItem_Door Door;

event Activated()
{
//	Door = CircleWorldItem_Door(Door);
	
	switch (DoorCommand)
	{
		case D_Open:
			Door.OpenDoor();
			break;
		case D_Close:
			Door.CloseDoor();
		case D_Toggle:
			if (Door.DoorState == D_Open)
			{
				Door.CloseDoor();
			}
			else
			{
				Door.OpenDoor();
			}
	}
}

defaultproperties
{
	ObjName="CircleWorld Door Opener"
	ObjCategory=""
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Door",PropertyName=Door)  
}