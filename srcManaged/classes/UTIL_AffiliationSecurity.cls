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
* @description Utility class for affiliation security
*/
public class UTIL_AffiliationSecurity {

    /*******************************************************************************************************
    * @description Compares affiliation to an affiliation rule to see if they match
    * @param rule Affiliation Security Rule to compare to
    * @param affliation Affiliation to test
    * @param isVip Whether or not account for this affiliation is a VIP account
    * @return Boolean true if affiliation matches affiliation security rule
    */
    public static Boolean AffiliationMatches(AffiliationSecurityRule__c rule, hed__Affiliation__c affliation, Boolean isVip) {

        // Return false if contact is a VIP and rule doesn't override VIP
        if (!rule.OverrideVip__c && isVip)
            return false;

        // Return false if accounts don't match
        if (rule.Account__c != affliation.hed__Account__c)
            return false;

        // Return false if rule calls for primary and affiliation isn't primary
        if (rule.Primary__c && !affliation.hed__Primary__c)
            return false;

        // Return false if rule role field doesn't contain affiliation's role
        if (String.isNotBlank(rule.Role__c)) {
            Set<String> roles = new Set<String>();
            for (String s:rule.Role__c.split(';'))
                roles.add(s.trim());
            if (!roles.contains(affliation.hed__Role__c))
                return false;
        }

        // Return false if rule status field doesn't contain affiliation's status
        if (String.isNotBlank(rule.Status__c)) {
            Set<String> statuses = new Set<String>();
            for (String s:rule.Status__c.split(';'))
                statuses.add(s.trim());
            if (!statuses.contains(affliation.hed__Status__c))
                return false;
        }

        return true; // Return true if false hasn't been returned so far
    }
    
    /*******************************************************************************************************
    * @description Queries administrative accounts based on parameters
    * @param fieldNames Set of field names to include in query
    * @param accountIds Set of Account record its to include in query result
    * @return Map<Id, Account> Map of Accounts with Account ID as key
    */
    public static Map<Id, Account> GetAdminAccountMap(Set<String> fieldNames, Set<Id> accountIds) {
        
        fieldNames.add('vip__c'); // Make sure vip is being queried
        
        // Build query
        String query = 'SELECT ';
        for (String f:fieldNames)
            query += (f + ', ');
        query += 'Id FROM Account WHERE Id IN :accountIds';
        
        // Query and return map
        return new Map<Id, Account>((List<Account>)Database.query(query));
    }
    
    /*******************************************************************************************************
    * @description Inserts trigger handlers for affiliation security
    * @return void
    */
    public static void CreateTriggerHandlers() {
        List<hed__Trigger_Handler__c> handlers = new List<hed__Trigger_Handler__c>();

        handlers.add(new hed__Trigger_Handler__c(hed__Active__c = true, hed__Asynchronous__c = false,
            hed__Class__c = 'AFFL_Security_TDTM', hed__Load_Order__c = 5, hed__Object__c = 'Affiliation__c',
            hed__Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        handlers.add(new hed__Trigger_Handler__c(hed__Active__c = true, hed__Asynchronous__c = false,
            hed__Class__c = 'AFFL_SecurityRule_TDTM', hed__Load_Order__c = 1, hed__Object__c = 'AffiliationSecurityRule__c',
            hed__Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        handlers.add(new hed__Trigger_Handler__c(hed__Active__c = true, hed__Asynchronous__c = false,
            hed__Class__c = 'AFFL_AccountVip_TDTM', hed__Load_Order__c = 5, hed__Object__c = 'Account',
            hed__Trigger_Action__c = 'BeforeUpdate'));

        insert handlers;
    }
}
