class CircleWorldAnim_PlayerBlendByIdle extends UDKAnimBlendBase
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

	if (!Owner.CirclePawnMoving)
        DesiredChild = 0;
    else if (Owner.WasUsingBoost)
        DesiredChild = 1;
    else if (Owner.CirclePawnJumping && !Owner.WasUsingBoost)
        DesiredChild = 2;
    else if (Owner.CirclePawnMoving)
        DesiredChild = 3;
		
    // If the current child is not the child we want, change the blend.
    if (ActiveChildIndex != DesiredChild)
        SetActiveChild(DesiredChild, BlendTime);
}

defaultproperties
{
	CategoryDesc="CircleWorld"
	Children(0)=(name="Idle")
	Children(1)=(name="Fly")
	Children(2)=(name="Jump")
	Children(3)=(name="Run")
	
	bFixNumChildren = true
    bTickAnimInScript=true
    bPlayActiveChild=true
    bCallScriptEventOnInit=true
    NodeName="CircleWorld PlayerBlendByIdle"
}