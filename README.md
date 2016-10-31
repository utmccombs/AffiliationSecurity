# Affiliation Security

Salesforce Higher-Ed Data Architecture (HEDA) Affiliation-Based Security for Salesforce

## Description

When we started our Salesforce implementation at the McCombs School of Business (University of Texas at Austin), we found that Contact record sharing amongst various departments around the college was an interesting problem that needed solving. We needed to share and un-share Contact records as our students progressed through the student lifecycle. When the Salesforce Foundation released the Higher-Ed Data Architecture (HEDA), we determined that a security solution based on the Affiliations object would be ideal. We then built a solution that allows admins to define an Affiliation "template" and share a Contact record with a group of users if the Contact had an Affiliation that fit said template.

## Requirements

* Installation of the <a href="https://github.com/SalesforceFoundation/HEDAP" target="\_blank" >Higher-Ed Data Architecture (HEDA)</a> version 1.20 or later (managed or open-source). For managed package installations, this version is set to be pushed to sandbox instances on 10/31 and production instances on 11/15. You can install the release earlier by going <a href="https://github.com/SalesforceFoundation/HEDAP/releases/tag/rel%2F1.20" target="\_blank" >here</a>.
* Administrative Account model configuration for HEDA

## Installation

Affiliation Security is released under the open source BSD license. Contributions (code and otherwise) are welcome and encouraged. You can fork this repository and deploy the unmanaged version of the code into a Salesforce org of your choice.

* Fork the repository by clicking on the "Fork" button in the upper-righthand corner. This creates your own copy of Affiliation Security for your Github user.
* Clone your fork to your local machine via the command line
```sh
$ git clone https://github.com/YOUR-USERNAME/AffiliationSecurity.git
```
* You now have a local copy on your machine. Affiliation Security has some built-in scripts to make deploying to your Salesforce org easier. Utilizing ant and the Force.com Migration tool, you can push your local copy of Affiliation Security to the org of your choice. You'll need to provide a build.properties to tell ant where to deploy. An example file might look like:

```
sf.username= YOUR_ORG_USERNAME
sf.password = YOUR_ORG_PASSWORD
sf.serverurl = https://login.salesforce.com ##or test.salesforce.com for sandbox environments
sf.maxPoll = 20
```

* Now deploy to your org utilizing ant

Open-source installation of HEDA:
```sh
$ cd AffiliationSecurity
$ ant deploy -buildfile build.xml
```

Managed package installation of HEDA:
```sh
$ cd AffiliationSecurity
$ ant deployManaged -buildfile build.xml
```

* If you get a test failure with the message "UNABLE_TO_LOCK_ROW", go to Setup>Develop>Apex Test Execution>Options and check the "Disable Parallel Apex Testing" checkbox.
* You'll need to give the System Administrator profile access to the fields on the newly-created Affiliation Security Rule object as well as the Affiliation Security Rules tab. Additionally, you'll need to give access to the VIP field on Account.
* Go to the Developer Console and run the following in an Execute Anonymous window:

```
UTIL_AffiliationSecurity.CreateTriggerHandlers();
```

## Using Affiliation Security

Once installed, you'll want to set up your first Affiliation Security Rule. To do so, follow these instructions:

1. Create a checkbox field on the Account object that will be used to control access to a business unit
  * Only the System Administrator profile should have access to this field
2. Create a criteria-based sharing rule on the Account object
  * Criteria should require the checkbox you just created to equal True
  * The "Share with" section should be populated with the group of users to grant access to
  * Default Account, Contract, and Asset Access should be Read/Write
  * Default Contact Access should be Read/Write
3. Navigate to the Affiliation Security Rules tab and create a new rule
  * This rule will define the "template" for the type of Affiliation that needs to exist to grant access
  * Note: Security Field Name is the API name of the field you created in step 1
  * If Override VIP is checked, this rule will grant access even if the Contact's Administrative Account is marked as a "VIP" (Vip__c checkbox on Account)

That's it! Now any contact with an Affiliation matching the template you defined will be shared with the group of users you specified.
