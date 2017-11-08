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
* @description Tests for UTIL_AffiliationSecurity
*/
@isTest
private class UTIL_AffiliationSecurity_TEST {

    /*********************************************************************************************************
    * @description Test Method for AffiliationMatches
    */
    @isTest
    static void test_match_method() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];
        Account a2 = [SELECT Id FROM Account WHERE Name = :'test_acc_2'];
        Contact c1 = [SELECT Id FROM Contact WHERE LastName = :'test1'];
        Contact c2 = [SELECT Id FROM Contact WHERE LastName = :'test2'];

        // VIP
        Affiliation__c affl1 = new Affiliation__c(Contact__c = c2.Id, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(OverrideVip__c = true, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r2 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');

        // Account
        Affiliation__c affl2 = new Affiliation__c(Contact__c = c1.Id, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r3 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r4 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a2.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');

        // Primary
        Affiliation__c affl3 = new Affiliation__c(Contact__c = c1.Id, Account__c = a1.Id, Primary__c = true, Role__c = 'test', Status__c = 'Current');
        Affiliation__c affl4 = new Affiliation__c(Contact__c = c1.Id, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r5 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = true, Role__c = 'test', Status__c = 'Current');

        // Role
        Affiliation__c affl5 = new Affiliation__c(Contact__c = c1.Id, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r6 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r7 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'nottest', Status__c = 'Current');

        // Status
        Affiliation__c affl6 = new Affiliation__c(Contact__c = c1.Id, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r8 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r9 = new AffiliationSecurityRule__c(OverrideVip__c = false, Account__c = a1.Id, Primary__c = false, Role__c = 'test', Status__c = 'NotCurrent');

        insert new List<Affiliation__c>{affl1, affl2, affl3, affl4, affl5, affl6};
        Map<Id, Affiliation__c> affls = new Map<Id, Affiliation__c>([SELECT Id, Account__c, Contact__r.Account.Vip__c, Role__c, Status__c, Primary__c FROM Affiliation__c]);

        Test.startTest();

        // VIP
        System.assert(UTIL_AffiliationSecurity.AffiliationMatches(r1, affls.get(affl1.Id), true));
        System.assert(!UTIL_AffiliationSecurity.AffiliationMatches(r2, affls.get(affl1.Id), true));

        // Account
        System.assert(UTIL_AffiliationSecurity.AffiliationMatches(r3, affls.get(affl2.Id), false));
        System.assert(!UTIL_AffiliationSecurity.AffiliationMatches(r4, affls.get(affl2.Id), false));

        // Primary
        System.assert(UTIL_AffiliationSecurity.AffiliationMatches(r5, affls.get(affl3.Id), false));
        System.assert(!UTIL_AffiliationSecurity.AffiliationMatches(r5, affls.get(affl4.Id), false));

        // Role
        System.assert(UTIL_AffiliationSecurity.AffiliationMatches(r6, affls.get(affl5.Id), false));
        System.assert(!UTIL_AffiliationSecurity.AffiliationMatches(r7, affls.get(affl5.Id), false));

        // Status
        System.assert(UTIL_AffiliationSecurity.AffiliationMatches(r8, affls.get(affl6.Id), false));
        System.assert(!UTIL_AffiliationSecurity.AffiliationMatches(r9, affls.get(affl6.Id), false));

        Test.stopTest();
    }
    
    /*********************************************************************************************************
    * @description Test Method for GetAdminAccountMap
    */
    @isTest
    static void test_account_query_method() {
        
        Id accId = [SELECT Id FROM Account WHERE Name = :'test_acc_1'].Id;
        Set<Id> accIds = new Set<Id>{accId};
        Set<String> accNames = new Set<String>();
        
        Test.startTest();
        
        Map<Id, Account> result = UTIL_AffiliationSecurity.GetAdminAccountMap(accNames, accIds);
        
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assert(result.containsKey(accId));
    }
    
    /*********************************************************************************************************
    * @description Test Method for CreateTriggerHandlers
    */
    @isTest
    static void test_create_method() {

        Set<String> classes = new Set<String>{'AFFL_Security_TDTM', 'AFFL_SecurityRule_TDTM', 'AFFL_AccountVip_TDTM'};

        Test.startTest();

        UTIL_AffiliationSecurity.CreateTriggerHandlers();
        Integer size = [SELECT Id FROM Trigger_Handler__c WHERE Class__c IN :classes].size();

        Test.stopTest();

        System.assertEquals(6, size);
    }

    /*********************************************************************************************************
    * @description Test setup method
    */
    @testSetup
    static void setup() {

        List<TDTM_Global_API.TdtmToken> tokens = TDTM_Global_API.getTdtmConfig();
        tokens.add(new TDTM_Global_API.TdtmToken('AFFL_Security_TDTM', 'Affiliation__c', 'AfterInsert;AfterUpdate;AfterDelete', 5.0));
        tokens.add(new TDTM_Global_API.TdtmToken('AFFL_SecurityRule_TDTM', 'AffiliationSecurityRule__c', 'AfterInsert;AfterUpdate;AfterDelete', 1.0));
        tokens.add(new TDTM_Global_API.TdtmToken('AFFL_AccountVip_TDTM', 'Account', 'BeforeUpdate', 5.0));
        TDTM_Global_API.setTdtmConfig(tokens);

        Account a1 = new Account(Name = 'test_acc_1');
        Account a2 = new Account(Name = 'test_acc_2');
        insert new List<Account>{a1, a2};

        Contact c1 = new Contact(LastName = 'test1');
        Contact c2 = new Contact(LastName = 'test2');
        insert new List<Contact>{c1, c2};
        c2 = [SELECT Id, AccountId FROM Contact WHERE Id = :c2.Id];

        Account adm2 = [SELECT Id, Vip__c FROM Account WHERE Id = :c2.AccountId];
        adm2.Vip__c = true;
        update adm2;
    }
}
