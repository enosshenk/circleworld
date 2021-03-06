class CircleWorldAnim_EnemyBlendByIdle extends UDKAnimBlendBase
	dependson(CircleWorldPawn);

var CircleWorldEnemyPawn Owner;

simulated event OnInit()
{
    Super.OnInit();

    // Call me paranoid, but I must insist on checking for both of these on init
    if ((SkelComponent == None) || (CircleWorldEnemyPawn(SkelComponent.Owner) == None))
        return;
    
    Owner = CircleWorldEnemyPawn(SkelComponent.Owner);
}

simulated event TickAnim(float DeltaSeconds)
{
    local int DesiredChild;

    if (Owner == None)
        return;

	if (Owner.EnemyPawnWalking)
        DesiredChild = 1;
    else
        DesiredChild = 0;
		
	if (Owner.Health <= 0 && Owner.Stomped)
		DesiredChild = 3;	
	else if (Owner.Health <= 0)
		DesiredChild = 2;
		
    // If the current child is not the child we want, change the blend.
    if (ActiveChildIndex != DesiredChild)
        SetActiveChild(DesiredChild, BlendTime);
}

defaultproperties
{
	CategoryDesc="CircleWorld"
	Children(0)=(name="Idle")
	Children(1)=(name="Moving")
	Children(2)=(name="Dead")
	Children(3)=(name="Stomped")
	
	bFixNumChildren = true
    bTickAnimInScript=true
    bPlayActiveChild=true
    bCallScriptEventOnInit=true
    NodeName="CircleWorld EnemyBlendByIdle"
}