//===================================================================================================
//       Date: 06/27/2018
//  Developer: Paritosh Bhatia
/*    Purpose: This is handler class for Case Claim Line item object and is used for accomplishing the 
*              below use cases -
1. Sum the Planned, Actual and Correct Paid Amount from Case Claim line item to Case Claim
*/               
//Limitations:
//
//====================================================================================================
//                                 Update History
// Date       Developer      Description
//====================================================================================================
//
//===================================================================================================


public class SIU_CaseClaimLineItemHandlerLogic 
{        
    //=================================================================================================
    //Sum the Planned, Actual and Correct Paid Amount from Case Claim line item to Case Claim
    //=================================================================================================
    public static void updateCaseClaimRecoveryAmount(List<SIU_CaseClaimLineItem__c> lineItems)
    {
        final Set<Id> relatedCaseClaimIds = new Set<Id>();
        final Set<Id> relatedCaseIds = new Set<Id>();
        
        for (SIU_CaseClaimLineItem__c lineItem : lineItems)
        {
            relatedCaseClaimIds.add(lineItem.SIU_CaseClaimId__c);
            relatedCaseIds.add(lineItem.SIU_CaseId__c);
        }
        
        final List<SIU_CaseClaim__c> relatedCaseClaims = [SELECT Id, SIU_ActualRecoveryAmount__c, SIU_PlannedRecoveryAmount__c, 
                                                          SIU_CorrectPaidAmount__c, SIU_IsCorrectPaidAmountRolledUp__c, SIU_Case__c,
                                                          SIU_ByPassCorrectPaidAmountRollup__c, SIU_NonRecoveredAmount__c,
                                                          (SELECT Id, SIU_PlannedRecoveryAmount__c, SIU_ActualRecoveryAmount__c,
                                                           SIU_CaseId__c, SIU_CorrectPaidAmount__c, SIU_ClaimType__c, SIU_NonRecoveredAmount__c
                                                           FROM Case_Claim_Line_Items__r)
                                                          FROM SIU_CaseClaim__c
                                                          WHERE Id IN :relatedCaseClaimIds and SIU_Case__c IN :relatedCaseIds];
        
        for(SIU_CaseClaim__c caseClaim : relatedCaseClaims)
        {
            if((caseClaim.SIU_IsCorrectPaidAmountRolledUp__c && caseClaim.SIU_CorrectPaidAmount__c >= 0) 
               || (!caseClaim.SIU_IsCorrectPaidAmountRolledUp__c && (caseClaim.SIU_CorrectPaidAmount__c == 0 || caseClaim.SIU_CorrectPaidAmount__c == null)))
            {                            
                decimal plannedAmount = 0;
                decimal actualAmount = 0;
                decimal correctAmount = 0;        
                boolean updateCorrect =  false;
                
                for(SIU_CaseClaimLineItem__c lineItem : caseClaim.Case_Claim_Line_Items__r)
                {        
                    system.debug('case id '+lineItem.SIU_CaseId__c+' correct paid amount '+lineItem.SIU_CorrectPaidAmount__c );
                    //if(lineItem.SIU_CaseId__c == caseClaim.SIU_Case__c)
                    //{
                        if(lineItem.SIU_PlannedRecoveryAmount__c > 0)  
                        {   
                            plannedAmount += lineItem.SIU_PlannedRecoveryAmount__c;
                        }
                        if(lineItem.SIU_ActualRecoveryAmount__c > 0)
                        {   
                            actualAmount += lineItem.SIU_ActualRecoveryAmount__c; 
                        }
                        if(lineItem.SIU_CorrectPaidAmount__c > 0)
                        {
                            correctAmount += lineItem.SIU_CorrectPaidAmount__c; 
                            updateCorrect = true;
                        }
                    //}
                }
                
                caseClaim.SIU_PlannedRecoveryAmount__c = plannedAmount;
                caseClaim.SIU_ActualRecoveryAmount__c = actualAmount;                              
                
                if(updateCorrect)
                {
                    caseClaim.SIU_CorrectPaidAmount__c = correctAmount;
                    caseClaim.SIU_ByPassCorrectPaidAmountRollup__c = !caseClaim.SIU_ByPassCorrectPaidAmountRollup__c;
                    caseClaim.SIU_IsCorrectPaidAmountRolledUp__c = true;
                }
                else
                {
                    caseClaim.SIU_CorrectPaidAmount__c = 0;
                    caseClaim.SIU_IsCorrectPaidAmountRolledUp__c = false;
                } 
            }
        }        
        update relatedCaseClaims;
    }
}
