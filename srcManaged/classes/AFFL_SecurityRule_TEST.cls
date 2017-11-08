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
* @description Tests for AFFL_SecurityRule_TDTM
*/
@isTest
private class AFFL_SecurityRule_TEST {

    /*********************************************************************************************************
    * @description Test insert a rule that grants access for one record and not another
    */
    @isTest
    static void test_insert() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a1.Id, Role__c = 'test', Status__c = 'Current');

        Test.startTest();

        insert r1;

        Test.stopTest();

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        Account adm3 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test3 Administrative Account'];
        System.assert(adm1.Vip__c);
        System.assert(!adm3.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test insert a rule that grants access to a VIP record
    */
    @isTest
    static void test_insert_vip() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a1.Id, Role__c = 'test', Status__c = 'Current', OverrideVip__c = true);

        Test.startTest();

        insert r1;

        Test.stopTest();

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        Account adm2 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test2 Administrative Account'];
        System.assert(adm1.Vip__c);
        System.assert(adm2.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test update a rule that grants access to a record
    */
    @isTest
    static void test_update_grant() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a1.Id, Role__c = 'test', Status__c = 'Former');
        insert r1;

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(!adm1.Vip__c);

        Test.startTest();

        r1.Status__c = 'Current';
        update r1;

        Test.stopTest();

        adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test update a rule that restricts access to a record
    */
    @isTest
    static void test_update_restrict() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', OverrideVip__c = true, Account__c = a1.Id, Role__c = 'test', Status__c = 'Current');
        insert r1;

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);

        Test.startTest();

        r1.Status__c = 'Former';
        update r1;

        Test.stopTest();

        adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(!adm1.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test update a rule that would restrict access to a record but
    * another rule exists that grants access to a record so access
    * should still be granted.
    */
    @isTest
    static void test_update_restrict_grant() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];
        Account a2 = [SELECT Id FROM Account WHERE Name = :'test_acc_2'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a1.Id, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r2 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a2.Id, Role__c = 'test', Status__c = 'Former');
        insert new List<AffiliationSecurityRule__c>{r1, r2};

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);

        Test.startTest();

        r1.Status__c = 'Former';
        update r1;

        Test.stopTest();

        adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test delete a rule that restricts access to a record
    */
    @isTest
    static void test_delete_restrict() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', OverrideVip__c = true, Account__c = a1.Id, Role__c = 'test', Status__c = 'Current');
        insert r1;

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);

        Test.startTest();

        delete r1;

        Test.stopTest();

        adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(!adm1.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test deletes a rule that would restrict access to a record but
    * another rule exists that grants access to a record so access
    * should still be granted.
    */
    @isTest
    static void test_delete_restrict_grant() {

        Account a1 = [SELECT Id FROM Account WHERE Name = :'test_acc_1'];
        Account a2 = [SELECT Id FROM Account WHERE Name = :'test_acc_2'];

        AffiliationSecurityRule__c r1 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a1.Id, Role__c = 'test', Status__c = 'Current');
        AffiliationSecurityRule__c r2 = new AffiliationSecurityRule__c(SecurityFieldName__c = 'Vip__c', Account__c = a2.Id, Role__c = 'test', Status__c = 'Former');
        insert new List<AffiliationSecurityRule__c>{r1, r2};

        Account adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);

        Test.startTest();

        delete r1;

        Test.stopTest();

        adm1 = [SELECT Id, Vip__c FROM Account WHERE Name = :'test1 Administrative Account'];
        System.assert(adm1.Vip__c);
    }

    /*********************************************************************************************************
    * @description Test setup method
    */
    @testSetup
    static void setup() {

        List<hed.TDTM_Global_API.TdtmToken> tokens = hed.TDTM_Global_API.getTdtmConfig();
        tokens.add(new hed.TDTM_Global_API.TdtmToken('AFFL_Security_TDTM', 'Affiliation__c', 'AfterInsert;AfterUpdate;AfterDelete', 5.0));
        tokens.add(new hed.TDTM_Global_API.TdtmToken('AFFL_SecurityRule_TDTM', 'AffiliationSecurityRule__c', 'AfterInsert;AfterUpdate;AfterDelete', 1.0));
        tokens.add(new hed.TDTM_Global_API.TdtmToken('AFFL_AccountVip_TDTM', 'Account', 'BeforeUpdate', 5.0));
        hed.TDTM_Global_API.setTdtmConfig(tokens);

        Account a1 = new Account(Name = 'test_acc_1');
        Account a2 = new Account(Name = 'test_acc_2');
        insert new List<Account>{a1, a2};

        Contact c1 = new Contact(LastName = 'test1');
        Contact c2 = new Contact(LastName = 'test2');
        Contact c3 = new Contact(LastName = 'test3');
        insert new List<Contact>{c1, c2, c3};
        c2 = [SELECT Id, AccountId FROM Contact WHERE Id = :c2.Id];

        Account adm2 = [SELECT Id, Vip__c FROM Account WHERE Id = :c2.AccountId];
        adm2.Vip__c = true;
        update adm2;

        hed__Affiliation__c affl1 = new hed__Affiliation__c(hed__Account__c = a1.Id, hed__Contact__c = c1.Id, hed__Role__c = 'test', hed__Status__c = 'Current');
        hed__Affiliation__c affl2 = new hed__Affiliation__c(hed__Account__c = a2.Id, hed__Contact__c = c1.Id, hed__Role__c = 'test', hed__Status__c = 'Former');
        hed__Affiliation__c affl3 = new hed__Affiliation__c(hed__Account__c = a1.Id, hed__Contact__c = c2.Id, hed__Role__c = 'test', hed__Status__c = 'Current');
        hed__Affiliation__c affl4 = new hed__Affiliation__c(hed__Account__c = a2.Id, hed__Contact__c = c2.Id, hed__Role__c = 'test', hed__Status__c = 'Former');
        hed__Affiliation__c affl5 = new hed__Affiliation__c(hed__Account__c = a1.Id, hed__Contact__c = c3.Id, hed__Role__c = 'test', hed__Status__c = 'Former');
        insert new List<hed__Affiliation__c>{affl1, affl2, affl3, affl4, affl5};
    }
}
