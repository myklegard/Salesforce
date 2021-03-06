trigger estimatePlanned_Project_Trigger  on Estimate_Planned__c (after insert, after update, after delete,before insert, before update) {	
if((Trigger.isInsert && Trigger.isBefore)||(Trigger.isUpdate && Trigger.isBefore))
{
    Set<ID> projIds = new Set<ID>();
	for(Estimate_Planned__c estObj: Trigger.new){
	    projIds.add(estObj.Project__c);
	}
	Map<ID, Project__c> projMap = new Map<ID, Project__c>([SELECT Portfolio_Manager__c FROM Project__c WHERE Id IN :projIds]);
	for(Estimate_Planned__c estObj: Trigger.new){
	    Project__c projId = projMap.get(estObj.Project__c);
	    if(projId.Portfolio_Manager__c != null){
		estObj.Project_Portfolio_Manager__c = projId.Portfolio_Manager__c;  
	    }
    }
}
else
{	
Set<ID> estIds = new Set<ID>();
    if(Trigger.isInsert || Trigger.isUpdate){
        for(Estimate_Planned__c epObj: Trigger.new){
            estIds.add(epObj.project__c);
        }
    }
    if(Trigger.isUpdate || Trigger.isDelete){
        for(Estimate_Planned__c epObj: Trigger.old){
             estIds.add(epObj.project__c);
        }  
    }
     LIST<AggregateResult> estPlanned=[select sum(Cost_Estimate__c) Cost_Estimate,project__c from Estimate_Planned__c   where  Status__c in ('Approved','Locked') and Project_Funding__c='' and Funding_Direction__c='Request' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     LIST<AggregateResult> dupestPlanned=[select sum(Cost_Estimate__c) Cost_Estimate,project__c from Estimate_Planned__c   where  Status__c in ('Approved','Locked') and Project_Funding__c in (select Id from Project_Funding_Sources__c where status__c='Draft' ) and Funding_Direction__c='Request' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     List<AggregateResult>  projectFunding=[select sum(Amount__c) pfamount,project__c from Project_Funding_Sources__c where  Status__c='Approved' and Funding_Type__c='Request' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     LIST<AggregateResult> estPlanned1=[select sum(Cost_Estimate__c) Cost_Estimate,project__c from Estimate_Planned__c   where  Status__c in ('Approved','Locked') and Project_Funding__c='' and Funding_Direction__c='Return' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     LIST<AggregateResult> dupestPlanned1=[select sum(Cost_Estimate__c) Cost_Estimate,project__c from Estimate_Planned__c   where  Status__c in ('Approved','Locked') and Project_Funding__c in (select Id from Project_Funding_Sources__c where status__c='Draft')  and Funding_Direction__c='Return' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     List<AggregateResult>  projectFunding1=[select sum(Amount__c) pfamount,project__c from Project_Funding_Sources__c where  Status__c='Approved' and Funding_Type__c='Return' and project__c IN :estIds GROUP BY project__c LIMIT 9];
     List<project__c> proj =[select Id,Total_Funding1__c from project__c where Id IN :estIds LIMIT 1];
     Integer costEstimate=0;
     Integer dupcostEstimate=0;
     Integer pfamount=0; 
     Integer costEstimate1=0;
     Integer dupcostEstimate1=0;
     Integer pfamount1=0;  
     for(AggregateResult sobj : estPlanned)
     {
       costEstimate= Integer.valueOf(sobj.get('Cost_Estimate'));
       if(costEstimate==null)
       costEstimate=0; 
     }
     
    for(AggregateResult sobj : dupestPlanned)
     {   
       dupcostEstimate= Integer.valueOf(sobj.get('Cost_Estimate'));
       if(dupcostEstimate==null)
       dupcostEstimate=0; 
     }
     
     for(AggregateResult sobj : projectFunding)
     {  
       pfamount= Integer.valueOf(sobj.get('pfamount'));
       if(pfamount==null)
       pfamount=0;
     }
     for(AggregateResult sobj : estPlanned1)
     {   
       costEstimate1= Integer.valueOf(sobj.get('Cost_Estimate'));
       if(costEstimate1==null)
       costEstimate1=0; 
     }
         for(AggregateResult sobj : dupestPlanned1)
     {   
       dupcostEstimate1= Integer.valueOf(sobj.get('Cost_Estimate'));
       if(dupcostEstimate1==null)
       dupcostEstimate1=0; 
     }
     
     for(AggregateResult sobj : projectFunding1)
     { 
       pfamount1= Integer.valueOf(sobj.get('pfamount'));
       if(pfamount1==null)
       pfamount1=0;
     }     
      for(project__c p:proj)  
      {
       system.debug('****'+costEstimate+'**'+dupcostEstimate+'**'+pfamount+'**'+costEstimate1+'****'+pfamount1);        
       p.Total_Funding1__c=costEstimate+dupcostEstimate+pfamount-costEstimate1-dupcostEstimate1-pfamount1; 
       p.Total_Estimated__c=costEstimate+dupcostEstimate-costEstimate1-dupcostEstimate1;
       update p;
      }
}
}