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
    * Neither the name of Salesforce.org nor the names of
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
public class AFFL_SecurityRule_TDTM extends hed.TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on AffiliationSecurityRule__c that handles affiliation security
    * @param listNew the list of Affiliation Security Rules from trigger new.
    * @param listOld the list of Affiliation Security Rules from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Affiliation Security Rules.
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override hed.TDTM_Runnable.DmlWrapper run(List<SObject> listNew, List<SObject> listOld, hed.TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        hed.TDTM_Runnable.DmlWrapper dmlWrapper = new hed.TDTM_Runnable.DmlWrapper();

        List<AffiliationSecurityRule__c> oldList;
        List<AffiliationSecurityRule__c> newList;

        // Get set of all rule ids
        // Get set of all account ids for old and new rules
        // Get set of all security field names for old and new rules
        Set<Id> ruleIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<String> fields = new Set<String>();
        if (triggerAction == hed.TDTM_Runnable.Action.AfterUpdate || triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {
            oldList = (List<AffiliationSecurityRule__c>)listOld;
            for (AffiliationSecurityRule__c r:oldList) {
                ruleIds.add(r.Id);
                accIds.add(r.Account__c);
                fields.add(r.SecurityFieldNameLower__c);
            }
        }
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert || triggerAction == hed.TDTM_Runnable.Action.AfterUpdate) {
            newList = (List<AffiliationSecurityRule__c>)listNew;
            for (AffiliationSecurityRule__c r:newList) {
                ruleIds.add(r.Id);
                accIds.add(r.Account__c);
                fields.add(r.SecurityFieldNameLower__c);
            }
        }

        // Get map of all affiliations: Account id is key and list of affiliations is value
        // Get set of administrative account ids
        Map<Id, List<hed__Affiliation__c>> affls = new Map<Id, List<hed__Affiliation__c>>();
        Set<Id> adminIds = new Set<Id>();
        Set<Id> afflIds = new Set<Id>();
        for (hed__Affiliation__c a:[SELECT Id, hed__Contact__r.AccountId, hed__Contact__r.Account.Vip__c, hed__Account__c, hed__Primary__c, hed__Role__c, hed__Status__c FROM hed__Affiliation__c WHERE hed__Account__c IN :accIds]) {
            if (!affls.containsKey(a.hed__Account__c))
                affls.put(a.hed__Account__c, new List<hed__Affiliation__c>());
            affls.get(a.hed__Account__c).add(a);
            adminIds.add(a.hed__Contact__r.AccountId);
            afflIds.add(a.Id);
        }

        // Get map of administrative accounts with Id as key
        fields.add('vip__c');
        String query = 'SELECT ';
        for (String f:fields)
            query += (f + ', ');
        query += 'Id FROM Account WHERE Id IN :adminIds';
        Map<Id, Account> adminAccs = new Map<Id, Account>((List<Account>)Database.query(query));

        // newList is read only so we have to duplicate
        List<AffiliationSecurityRule__c> newRuleList = new List<AffiliationSecurityRule__c>();
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert || triggerAction == hed.TDTM_Runnable.Action.AfterUpdate)
            newRuleList.addAll(newList);

        // Actions to perform after update/after delete
        if (triggerAction == hed.TDTM_Runnable.Action.AfterUpdate || triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {

            // Uncheck checkbox on administrative account for each affiliation that matches each rule
            for (AffiliationSecurityRule__c r:oldList)
                if (affls.containsKey(r.Account__c))
                    for (hed__Affiliation__c a:affls.get(r.Account__c))
                        if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, false))
                            adminAccs.get(a.hed__Contact__r.AccountId).put(r.SecurityFieldNameLower__c, false);

            // Add other affiliation rules that have to do with these accounts
            List<AffiliationSecurityRule__c> newRules = [SELECT Id, Account__c, OverrideVip__c, Primary__c, Role__c, SecurityFieldNameLower__c, Status__c FROM AffiliationSecurityRule__c WHERE SecurityFieldNameLower__c IN :fields AND Id NOT IN :ruleIds];
            newRuleList.addAll(newRules);

            // Add affiliations that have to do with these new rules
            Set<Id> newAccIds = new Set<Id>();
            for (AffiliationSecurityRule__c r:newRuleList)
                newAccIds.add(r.Account__c);
            newAccIds.removeAll(accIds);
            for (hed__Affiliation__c a:[SELECT Id, hed__Contact__r.AccountId, hed__Contact__r.Account.Vip__c, hed__Account__c, hed__Primary__c, hed__Role__c, hed__Status__c FROM hed__Affiliation__c WHERE hed__Contact__r.AccountId IN :(adminAccs.keySet()) AND hed__Account__c IN :newAccIds AND Id NOT IN :afflIds]) {
                if (!affls.containsKey(a.hed__Account__c))
                    affls.put(a.hed__Account__c, new List<hed__Affiliation__c>());
                affls.get(a.hed__Account__c).add(a);
                adminIds.add(a.hed__Contact__r.AccountId);
            }
        }

        // Actions to perform after insert/after update/after delete
        if (triggerAction == hed.TDTM_Runnable.Action.AfterInsert || triggerAction == hed.TDTM_Runnable.Action.AfterUpdate || triggerAction == hed.TDTM_Runnable.Action.AfterDelete) {

            // Check checkbox on administrative account for each affiliation that matches each rule
            for (AffiliationSecurityRule__c r:newRuleList)
                if (affls.containsKey(r.Account__c))
                    for (hed__Affiliation__c a:affls.get(r.Account__c))
                        if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, false))
                            adminAccs.get(a.hed__Contact__r.AccountId).put(r.SecurityFieldNameLower__c, true);
        }

        dmlWrapper.objectsToUpdate.addAll((List<SObject>)adminAccs.values()); // Add administrative accounts to dml wrapper

        return dmlWrapper;
    }
}
