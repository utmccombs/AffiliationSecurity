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
* @description Implements affiliation security when an affiliation is created/changed
*/
global without sharing class AFFL_Security_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Affiliation__c that handles affiliation security
    * @param listNew the list of Affiliations from trigger new.
    * @param listOld the list of Affiliations from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Affiliations.
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        List<Affiliation__c> oldList;
        List<Affiliation__c> newList;

        // Get set of all affiliation ids
        // Get set of all account ids for old and new affiliations
        // Get set of contact ids
        Set<Id> afflIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> conIds = new Set<Id>();
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {
            oldList = (List<Affiliation__c>)listOld;
            for (Affiliation__c a:oldList) {
                afflIds.add(a.Id);
                accIds.add(a.Account__c);
                conIds.add(a.Contact__c);
            }
        }
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            newList = (List<Affiliation__c>)listNew;
            for (Affiliation__c a:newList) {
                afflIds.add(a.Id);
                accIds.add(a.Account__c);
                conIds.add(a.Contact__c);
            }
        }

        // Check to see if anything has changed and exit if it hasn't
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            Boolean changed = false;
            for (Integer i = 0; i < newList.size(); i++) {
                if (oldList[i].Contact__c != newList[i].Contact__c ||
                    oldList[i].Account__c != newList[i].Account__c ||
                    oldList[i].Primary__c != newList[i].Primary__c ||
                    oldList[i].Role__c != newList[i].Role__c ||
                    oldList[i].Status__c != newList[i].Status__c) {

                    changed = true;
                    break;
                }
            }
            if (!changed) return (new DmlWrapper());
        }

        // Get Set of all administrative account ids
        // Get map of administative account ids as values and contact ids as keys
        Set<Id> adminIds = new Set<Id>();
        Map<Id, Id> conAdminIdMap = new Map<Id, Id>();
        for (Contact c:[SELECT Id, AccountId FROM Contact WHERE Id IN :conIds]) {
            adminIds.add(c.AccountId);
            conAdminIdMap.put(c.Id, c.AccountId);
        }

        // Get map of all security rules: Account id is key and list of security rules is value
        Map<Id, List<AffiliationSecurityRule__c>> rules = new Map<Id, List<AffiliationSecurityRule__c>>();
        Set<Id> ruleIds = new Set<Id>();
        Set<String> fields = new Set<String>();
        for (AffiliationSecurityRule__c r:[SELECT Id, Account__c, OverrideVip__c, Primary__c, Role__c, Status__c, SecurityFieldNameLower__c FROM AffiliationSecurityRule__c WHERE Account__c IN :accIds]) {
            if (!rules.containsKey(r.Account__c))
                rules.put(r.Account__c, new List<AffiliationSecurityRule__c>());
            rules.get(r.Account__c).add(r);
            ruleIds.add(r.Id);
            fields.add(r.SecurityFieldNameLower__c);
        }

        // Get map of administrative accounts with Id as key
        fields.add('vip__c');
        String query = 'SELECT ';
        for (String f:fields)
            query += (f + ', ');
        query += 'Id FROM Account WHERE Id IN :adminIds';
        Map<Id, Account> adminAccs = new Map<Id, Account>((List<Account>)Database.query(query));

        // newList is read only so we have to duplicate
        List<Affiliation__c> newAfflList = new List<Affiliation__c>();
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate)
            newAfflList.addAll(newList);

        // Actions to perform after update/after delete
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {

            // Uncheck checkbox on administrative account for each affiliation that matches each rule
            for (Affiliation__c a:oldList)
                if (rules.containsKey(a.Account__c))
                  for (AffiliationSecurityRule__c r:rules.get(a.Account__c))
                      if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, (Boolean)adminAccs.get(conAdminIdMap.get(a.Contact__c)).get('Vip__c')))
                          adminAccs.get(conAdminIdMap.get(a.Contact__c)).put(r.SecurityFieldNameLower__c, false);

            // Add other affiliation rules that have to do with these fields
            for (AffiliationSecurityRule__c r:[SELECT Id, Account__c, OverrideVip__c, Primary__c, Role__c, SecurityFieldNameLower__c, Status__c FROM AffiliationSecurityRule__c WHERE SecurityFieldNameLower__c IN :fields AND Id NOT IN :ruleIds]) {
                if (!rules.containsKey(r.Account__c))
                    rules.put(r.Account__c, new List<AffiliationSecurityRule__c>());
                rules.get(r.Account__c).add(r);
            }

            // Add affiliations that have to do with these new rules
            List<Affiliation__c> newAffls = [SELECT Id, Contact__r.AccountId, Contact__r.Account.Vip__c, Account__c, Primary__c, Role__c, Status__c FROM Affiliation__c WHERE Contact__r.AccountId IN :(adminAccs.keySet()) AND Account__c IN :(rules.keySet()) AND Id NOT IN :afflIds];
            newAfflList.addAll(newAffls);
        }

        // Actions to perform after insert/after update/after delete
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete) {

            // Check checkbox on administrative account for each affiliation that matches each rule
            for (Affiliation__c a:newAfflList)
                if (rules.containsKey(a.Account__c))
                    for (AffiliationSecurityRule__c r:rules.get(a.Account__c))
                        if (UTIL_AffiliationSecurity.AffiliationMatches(r, a, (Boolean)adminAccs.get(conAdminIdMap.get(a.Contact__c)).get('Vip__c')))
                            adminAccs.get(conAdminIdMap.get(a.Contact__c)).put(r.SecurityFieldNameLower__c, true);
        }

        update adminAccs.values();

        return (new DmlWrapper());
    }
}
