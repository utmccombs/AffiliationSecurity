/*
    Copyright (c) 2016, McCombs School of Business, The University of Texas at Austin
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Kyle Schmid
* @date 2016
* @description Implements affiliation security when an affiliation security rule is created/changed
*/
global class AFFL_SecurityRule_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on AffiliationSecurityRule__c that handles affiliation security
    * @param listNew the list of Affiliation Security Rules from trigger new.
    * @param listOld the list of Affiliation Security Rules from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Affiliation Security Rules.
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        List<AffiliationSecurityRule__c> oldList;
        List<AffiliationSecurityRule__c> newList;

        // Get set of all rule ids
        // Get set of all account ids for old and new rules
        // Get set of all security field names for old and new rules
        Set<Id> ruleIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<String> fields = new Set<String>();
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {
            oldList = (List<AffiliationSecurityRule__c>)listOld;
            for (AffiliationSecurityRule__c r:oldList) {
                ruleIds.add(r.Id);
                accIds.add(r.Account__c);
                fields.add(r.SecurityFieldNameLower__c);
            }
        }
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            newList = (List<AffiliationSecurityRule__c>)listNew;
            for (AffiliationSecurityRule__c r:newList) {
                ruleIds.add(r.Id);
                accIds.add(r.Account__c);
                fields.add(r.SecurityFieldNameLower__c);
            }
        }

        // Get map of all affiliations: Account id is key and list of affiliations is value
        // Get set of administrative account ids
        Map<Id, List<Affiliation__c>> affls = new Map<Id, List<Affiliation__c>>();
        Set<Id> adminIds = new Set<Id>();
        Set<Id> afflIds = new Set<Id>();
        for (Affiliation__c a:[SELECT Id, Contact__r.AccountId, Contact__r.Account.Vip__c, Account__c, Primary__c, Role__c, Status__c FROM Affiliation__c WHERE Account__c IN :accIds]) {
            if (!affls.containsKey(a.Account__c))
                affls.put(a.Account__c, new List<Affiliation__c>());
            affls.get(a.Account__c).add(a);
            adminIds.add(a.Contact__r.AccountId);
            afflIds.add(a.Id);
        }

        // Get map of administrative accounts with Id as key
        Map<Id, Account> adminAccs = UTIL_AffiliationSecurity.GetAdminAccountMap(fields, adminIds);

        // newList is read only so we have to duplicate
        List<AffiliationSecurityRule__c> newRuleList = new List<AffiliationSecurityRule__c>();
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate)
            newRuleList.addAll(newList);

        // Actions to perform after update/after delete
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {

            // Uncheck checkbox on administrative account for each affiliation that matches each rule
            for (AffiliationSecurityRule__c r:oldList)
                if (affls.containsKey(r.Account__c))
                    for (Affiliation__c a:affls.get(r.Account__c))
                        if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, a.Contact__r.Account.Vip__c))
                            adminAccs.get(a.Contact__r.AccountId).put(r.SecurityFieldNameLower__c, false);

            // Add other affiliation rules that have to do with these accounts
            List<AffiliationSecurityRule__c> newRules = [SELECT Id, Account__c, OverrideVip__c, Primary__c, Role__c, SecurityFieldNameLower__c, Status__c FROM AffiliationSecurityRule__c WHERE SecurityFieldNameLower__c IN :fields AND Id NOT IN :ruleIds];
            newRuleList.addAll(newRules);

            // Add affiliations that have to do with these new rules
            Set<Id> newAccIds = new Set<Id>();
            for (AffiliationSecurityRule__c r:newRuleList)
                newAccIds.add(r.Account__c);
            newAccIds.removeAll(accIds);
            for (Affiliation__c a:[SELECT Id, Contact__r.AccountId, Contact__r.Account.Vip__c, Account__c, Primary__c, Role__c, Status__c FROM Affiliation__c WHERE Contact__r.AccountId IN :(adminAccs.keySet()) AND Account__c IN :newAccIds AND Id NOT IN :afflIds]) {
                if (!affls.containsKey(a.Account__c))
                    affls.put(a.Account__c, new List<Affiliation__c>());
                affls.get(a.Account__c).add(a);
                adminIds.add(a.Contact__r.AccountId);
            }
        }

        // Actions to perform after insert/after update/after delete
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {

            // Check checkbox on administrative account for each affiliation that matches each rule
            for (AffiliationSecurityRule__c r:newRuleList)
                if (affls.containsKey(r.Account__c))
                    for (Affiliation__c a:affls.get(r.Account__c))
                        if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, a.Contact__r.Account.Vip__c))
                            adminAccs.get(a.Contact__r.AccountId).put(r.SecurityFieldNameLower__c, true);
        }

        dmlWrapper.objectsToUpdate.addAll((List<SObject>)adminAccs.values()); // Add administrative accounts to dml wrapper

        return dmlWrapper;
    }
}
