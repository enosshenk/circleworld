class CircleWorldAnim_Random extends UDKAnimBlendBase
	dependson(CircleWorldPawn);

var CircleWorldPawn Owner;

simulated event OnInit()
{
    Super.OnInit();

    // Call me paranoid, but I must insist on checking for both of these on init
    if ((SkelComponent == None) || (CircleWorldPawn(SkelComponent.Owner) == None))
        return;
    
    Owner = CircleWorldPawn(SkelComponent.Owner);
}

event OnBecomeRelevant()
{
    local int DesiredChild;

    if (Owner == None)
        return;

	DesiredChild = rand(Children.Length);
		
    // If the current child is not the child we want, change the blend.
    if (ActiveChildIndex != DesiredChild)
        SetActiveChild(DesiredChild, BlendTime);
}

defaultproperties
{
	CategoryDesc="CircleWorld"
	Children(0)=(name="")
	
	bFixNumChildren = false
    bTickAnimInScript=true
    bPlayActiveChild=true
    bCallScriptEventOnInit=true
    NodeName="CircleWorld Random"
}