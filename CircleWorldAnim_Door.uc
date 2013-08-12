class CircleWorldAnim_Door extends UDKAnimBlendBase
	dependson(CircleWorldPawn);

var CircleWorldItem_Door Owner;

simulated event OnInit()
{
    Super.OnInit();

    // Call me paranoid, but I must insist on checking for both of these on init
    if ((SkelComponent == None) || (CircleWorldItem_Door(SkelComponent.Owner) == None))
        return;
    
    Owner = CircleWorldItem_Door(SkelComponent.Owner);
}

simulated event TickAnim(float DeltaSeconds)
{
    local int DesiredChild;

    if (Owner == None)
        return;

	if (Owner.DoorState == D_Closed)
        DesiredChild = 1;
    else
        DesiredChild = 0;
		
    // If the current child is not the child we want, change the blend.
    if (ActiveChildIndex != DesiredChild)
        SetActiveChild(DesiredChild, BlendTime);
}

defaultproperties
{
	CategoryDesc="CircleWorld"
	Children(0)=(name="Open")
	Children(1)=(name="Close")
	
	bFixNumChildren = true
    bTickAnimInScript=true
    bPlayActiveChild=true
    bCallScriptEventOnInit=true
    NodeName="CircleWorld Door Node"
}