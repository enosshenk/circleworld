class CircleWorldAnim_PlayerBlendByJump extends UDKAnimBlendBase
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

simulated event TickAnim(float DeltaSeconds)
{
    local int DesiredChild;

    if (Owner == None)
        return;

	if (Owner.CirclePawnJumpUp)
        DesiredChild = 0;
    else if (Owner.CirclePawnJumpDown)
        DesiredChild = 1;
		
    // If the current child is not the child we want, change the blend.
    if (ActiveChildIndex != DesiredChild)
        SetActiveChild(DesiredChild, BlendTime);
}

defaultproperties
{
	CategoryDesc="CircleWorld"
	Children(0)=(name="Up")
	Children(1)=(name="Down")
	
	bFixNumChildren = true
    bTickAnimInScript=true
    bPlayActiveChild=true
    bCallScriptEventOnInit=true
    NodeName="CircleWorld PlayerBlendByJump"
}