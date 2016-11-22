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
* @description Implements VIP functionality for affiliation security
*/
global class AFFL_AccountVip_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Account that handles vip accounts for affiliation security
    * @param listNew the list of Accounts from trigger new.
    * @param listOld the list of Accounts from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for Accounts.
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Get list of accounts whose Vip__c field has changed
        // Get set of account ids
        List<Account> oldList = (List<Account>)listOld;
        List<Account> newList = (List<Account>)listNew;
        List<Account> accList = new List<Account>();
        Set<Id> accIds = new Set<Id>();
        for (Integer i = 0; i < oldList.size(); i++) {
            if (oldList[i].Vip__c != newList[i].Vip__c) {
                accList.add(newList[i]);
                accIds.add(newList[i].Id);
            }
        }

        // Exit if nothing to do here
        if (accList.isEmpty()) return (new DmlWrapper());

        // Get map of affiliations that have to do with accounts' contacts with admin account id as key
        // Get set of account ids that have to do with these affiliations
        Map<Id, List<Affiliation__c>> affls = new Map<Id, List<Affiliation__c>>();
        Set<Id> afflAccIds = new Set<Id>();
        Set<Id> conIds = (new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN :accIds])).keySet();
        for (Affiliation__c affl:[SELECT Id, Contact__r.AccountId, Account__c, Primary__c, Role__c, Status__c FROM Affiliation__c WHERE Contact__c IN :conIds]) {
            if (!affls.containsKey(affl.Contact__r.AccountId))
                affls.put(affl.Contact__r.AccountId, new List<Affiliation__c>());
            affls.get(affl.Contact__r.AccountId).add(affl);
            afflAccIds.add(affl.Account__c);
        }

        // Get map of security rules that have to do with affiliations' accounts with account id as key
        Map<Id, List<AffiliationSecurityRule__c>> rules = new Map<Id, List<AffiliationSecurityRule__c>>();
        for (AffiliationSecurityRule__c r:[SELECT Id, Account__c, OverrideVip__c, Primary__c, Role__c, SecurityFieldNameLower__c, Status__c FROM AffiliationSecurityRule__c WHERE Account__c IN :afflAccIds]) {
            if (!rules.containsKey(r.Account__c))
                rules.put(r.Account__c, new List<AffiliationSecurityRule__c>());
            rules.get(r.Account__c).add(r);
        }

        // Uncheck all fields referenced by rules
        for (Account a:accList)
            for (List<AffiliationSecurityRule__c> rls:rules.values())
                for (AffiliationSecurityRule__c r:rls)
                    a.put(r.SecurityFieldNameLower__c, false);

        // Check all fields that still have a matching rule/affiliation
        for (Account a:accList)
            if (affls.containsKey(a.Id))
                for (Affiliation__c affl:affls.get(a.Id))
                    if (rules.containsKey(affl.Account__c))
                        for (AffiliationSecurityRule__c r:rules.get(affl.Account__c))
                            if (UTIL_AffiliationSecurity.AffiliationMatches(r, affl, a.Vip__c))
                                a.put(r.SecurityFieldNameLower__c, true);

        return (new DmlWrapper());
    }
}
