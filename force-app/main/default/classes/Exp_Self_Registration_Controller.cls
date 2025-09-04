public without sharing class Exp_Self_Registration_Controller {

  public class AccountWrapper{
    @AuraEnabled
    public ycadmissions__Admissions_Branding__c branding;
    @AuraEnabled
    public Account account;
    @AuraEnabled
    public Boolean orgSettingAllowCellPhone;
    @AuraEnabled
    public List<Option> gradeOptions;
  }

  public class OptionWrapper{
    @AuraEnabled
    public List<Option> gradeOptions;
    @AuraEnabled
    public List<Option> stateOptions;
    @AuraEnabled
    public List<Option> suffixOptions;
  }

  public class Option{
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }

  public class ExistingRegistrant{
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String street;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String state;    
    @AuraEnabled
    public String zip;   
    @AuraEnabled
    public String phone;   
    @AuraEnabled
    public String StateOfInterest;   
    @AuraEnabled
    public String gradesOfInterest;   
    @AuraEnabled
    public String suffix;  
    
  }

  public class ExistingHAR{
    @AuraEnabled
    public String FirstName;
    @AuraEnabled
    public String LastName;
    @AuraEnabled
    public String Email;
    @AuraEnabled
    public String Phone;    
    @AuraEnabled
    public String AccountId;    
  }

  public class ZipWrapper{
    @AuraEnabled
    public boolean zipValid;
    @AuraEnabled
    public boolean showOnCommunity; 
    @AuraEnabled
    public String zipcodeUrl; 
  }


  @AuraEnabled
  public static OptionWrapper getGradeOptions(){
    OptionWrapper ow = new OptionWrapper();
    ow.gradeOptions = new List<Exp_Self_Registration_Controller.Option>();
    Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get('What_grade_levels_are_you_interested_in__c').getDescribe();
      List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
      for (Schema.PicklistEntry entry : picklistValues) {
        Option option = new Option();
        option.label =  entry.getLabel();
        option.value = entry.getValue();
        ow.gradeOptions.add(option);
      }
    ow.stateOptions = new List<Exp_Self_Registration_Controller.Option>();
    fieldDescribe = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get('State_Interested_in_Attending__c').getDescribe();
    picklistValues = fieldDescribe.getPicklistValues();
    for (Schema.PicklistEntry entry : picklistValues) {
      Option option = new Option();
      option.label =  entry.getLabel();
      option.value = entry.getValue();
      ow.stateOptions.add(option);
    }
    ow.suffixOptions = new List<Exp_Self_Registration_Controller.Option>();
    fieldDescribe = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get('ycadmissions__Suffix__c').getDescribe();
    picklistValues = fieldDescribe.getPicklistValues();
      Option nullOption = new Option();
      nullOption.label =  '';
      nullOption.value = null;
      ow.suffixOptions.add(nullOption);
      for (Schema.PicklistEntry entry : picklistValues) {
        Option option = new Option();
        option.label =  entry.getLabel();
        option.value = entry.getValue();
        ow.suffixOptions.add(option);
      }
    return ow;
  }

  @AuraEnabled
  public static ExistingHAR getExistingHar(String harId){
    ExistingHAR eh = new ExistingHAR();
    ycadmissions__Household_Access_Request__c har = [SELECT Id, ycadmissions__First_Name__c, ycadmissions__Household__c, ycadmissions__Last_Name__c, ycadmissions__Email__c, ycadmissions__Phone_Number__c FROM ycadmissions__Household_Access_Request__c WHERE Id =: harId Limit 1];
    eh.FirstName = har.ycadmissions__First_Name__c;
    eh.LastName = har.ycadmissions__Last_Name__c;
    eh.Email = har.ycadmissions__Email__c;
    eh.Phone = har.ycadmissions__Phone_Number__c;
    eh.AccountId = har.ycadmissions__Household__c;
    return eh;
  }
  
  @AuraEnabled
  public static AccountWrapper getAccountData(Id accountId) {

    try {

      AccountWrapper w = new AccountWrapper();
      try{
      ycadmissions__Admissions_Branding__c branding = [
        SELECT ycadmissions__Body_Font_Name__c, ycadmissions__Body_Font_Size__c, ycadmissions__Current__c,
              ycadmissions__Font_Color__c, ycadmissions__Header_Font_Name__c,
              ycadmissions__Header_Font_Size__c, ycadmissions__School_Logo__c, ycadmissions__Account__r.Name
        FROM ycadmissions__Admissions_Branding__c
        WHERE ycadmissions__Account__c = :accountId
        AND ycadmissions__Current__c = true
        LIMIT 1];
      system.debug('1');
      w.branding = branding;
      system.debug('2');
      }catch(exception E){}
      GlobalSettings__c setting = GlobalSettings__c.getInstance();
      w.orgSettingAllowCellPhone = setting.Allow_Cell_Phone__c;
      System.debug('************ setting.Allow_Cell_Phone__c '+setting.Allow_Cell_Phone__c);

      if(accountId != NULL){
      Account school = [SELECT Id, Allow_Cell_Phone_Login__c FROM Account WHERE Id = : accountId LIMIT 1];
      System.debug(school.Allow_Cell_Phone_Login__c);
      w.orgSettingAllowCellPhone = school.Allow_Cell_Phone_Login__c;
      w.account = school;
      }

      return w;
    } catch (Exception e) {
    system.debug(e.getmessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll('[^\\d]', '');
    system.debug('cleanNumber '+cleanNumber);
    if(cleanNumber.length() == 11) {
      system.debug('+1-' + 
      cleanNumber.substring(1,4) + '-' + 
      cleanNumber.substring(4,7) +  '-' + 
      cleanNumber.substring(7,11));
        return '+1-' + 
               cleanNumber.substring(1,4) + '-' + 
               cleanNumber.substring(4,7) +  '-' + 
               cleanNumber.substring(7,11);
    } else if(cleanNumber.length() == 10){
      system.debug('+1-' + 
      cleanNumber.substring(0,3) + '-' + 
      cleanNumber.substring(3,6) + '-' + 
      cleanNumber.substring(6,10));
      return '+1-' + 
      cleanNumber.substring(0,3) + '-' + 
      cleanNumber.substring(3,6) + '-' + 
      cleanNumber.substring(6,10);
    }
    else{
      system.debug('return null ');
        return '';
    }
  }

  @AuraEnabled
  public static ExistingRegistrant checkExistingUser(String fn, String ln, String email){
    try {
      ExistingRegistrant er = new ExistingRegistrant();
      List<Contact> con = new List<Contact>([SELECT Id, MailingStreet, MailingState,State_Interested_in_Attending__c, ycadmissions__Suffix__c, What_grade_levels_are_you_interested_in__c, MailingCity, MailingPostalCode, MobilePhone, lastModifiedDate FROM Contact WHERE FirstName = :fn AND LastName = :ln AND Email = :email]);
      List<Lead> ld = new List<Lead>([SELECT Id, City, Street, State, State_of_Interest__c, PostalCode,Phone, lastModifiedDate FROM Lead WHERE FirstName = :fn AND LastName = :ln AND Email = :email]);
      if(con.isEmpty() && ld.isEmpty()){
        return null;
      }
      else if(!con.isEmpty() && !ld.isEmpty()){
        if(con.get(0).lastModifiedDate < ld.get(0).lastModifiedDate){
          er.city = ld.get(0).City;
          er.street = ld.get(0).Street;
          er.state = ld.get(0).State;
          er.zip = ld.get(0).PostalCode;
          er.StateOfInterest = ld.get(0).State_of_Interest__c;
          if(ld.get(0).Phone!=null){
            er.phone = formatPhoneNumber(ld.get(0).Phone);
          }
          er.Id = ld.get(0).Id;
        }
        else{
          er.city = con.get(0).MailingCity;
          er.street = con.get(0).MailingStreet;
          er.state = con.get(0).MailingState;
          er.zip = con.get(0).MailingPostalCode;
          er.StateOfInterest = con.get(0).State_Interested_in_Attending__c;
          er.gradesOfInterest = con.get(0).What_grade_levels_are_you_interested_in__c;
          er.suffix = con.get(0).ycadmissions__Suffix__c;
          if(con.get(0).MobilePhone!=null){
            er.phone = formatPhoneNumber(con.get(0).MobilePhone);
          }
          er.Id = con.get(0).Id;
        }
      }
      else if(!con.isEmpty()){
        er.city = con.get(0).MailingCity;
        er.street = con.get(0).MailingStreet;
        er.state = con.get(0).MailingState;
        er.zip = con.get(0).MailingPostalCode;
        er.StateOfInterest = con.get(0).State_Interested_in_Attending__c;
        er.gradesOfInterest = con.get(0).What_grade_levels_are_you_interested_in__c;
        er.suffix = con.get(0).ycadmissions__Suffix__c;
        if(con.get(0).MobilePhone!=null){
          er.phone = formatPhoneNumber(con.get(0).MobilePhone);
        }
        er.Id = con.get(0).Id;
      }
      else if(!ld.isEmpty()){
        er.city = ld.get(0).City;
        er.street = ld.get(0).Street;
        er.state = ld.get(0).State;
        er.zip = ld.get(0).PostalCode;
        er.StateOfInterest = ld.get(0).State_of_Interest__c;
        if(ld.get(0).Phone!=null){
          er.phone = formatPhoneNumber(ld.get(0).Phone);
        }
        er.Id = ld.get(0).Id;

      }
      return er;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static ZipWrapper checkZipCode(String zipCode) {
    ZipWrapper zw = new ZipWrapper();
    zw.zipValid = false;
    zw.showOnCommunity = true;
    zw.zipcodeUrl = '';
    // zw.showOnCommunity = false;

    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();  
    Id schoolRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__School_RecordType_Developer_Name__c).getRecordTypeId();
    List<Account> schools = [SELECT Id,ycadmissions__Zip_Codes__c, ycadmissions__Show_On_Community__c,zipcode_url__c FROM Account WHERE RecordTypeId =:schoolRecordTypeId]; //ycadmissions__Show_On_Community__c = true];
    for(Account schl : schools){
      if(schl.ycadmissions__Zip_Codes__c!=null){
        List<String> allZips = schl.ycadmissions__Zip_Codes__c.split(';');
        for(String zip : allZips){
          if(zip == zipCode) {
            zw.zipValid = true;
            zw.showOnCommunity = schl.ycadmissions__Show_On_Community__c;
            zw.zipcodeUrl = schl.zipcode_url__c!=null ? schl.zipcode_url__c : '';
          }
          if(zw.showOnCommunity && zw.zipValid) break;
        }
        if(zw.showOnCommunity && zw.zipValid) break;
      }
    }
    return zw;
  }

  @AuraEnabled
  public static ycadmissions__Admissions_Branding__c getLoginAccountBranding(Id accountId) {
    if (accountId == null) return null;
    return getAccountData(accountId).branding;
  }

  @AuraEnabled
  public static Boolean userExists(String idValue, String idType) {
    if ((idValue == null) || (idType == null)) {
      return false;
    }

    idValue = idValue.trim();

    List<User> users = new List<User>();
    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();       

    // TODO: Figure out profiles
    Profile cprofile = [SELECT Id FROM Profile WHERE Name = :FS.ycadmissions__Default_Community_Profile_Name__c];
    Id profileId = cprofile.id;

    if (idType.equalsIgnoreCase('email')) {
      users = [SELECT Id
               FROM User
               WHERE Email = :idValue
               AND ProfileId = :profileId
               AND IsActive = TRUE];

    } else if (idType.equalsIgnoreCase('phone')) {
      String username = getUsernameForPhone(idValue);

      users = [SELECT Id
               FROM User
               WHERE Username = :username
               AND ProfileId = :profileId
               AND IsActive = TRUE];

    } else {
      // TODO - throw an exception?
      System.debug('Invalid idType - ' + idType);
    }

    // TODO - what if there's more than one?
    return !users.isEmpty();
  }

  /**
   * Create a new User, Contact, Email?, Account
   */
  @AuraEnabled
  public static String register(String idValue, String idType, Map<String, String> form, Id schoolId, Map<String, String> utmFields, String leadSource) {
    // try{
    Id newUserId = null;

    idType.toLowerCase();
    if (!(new List<String>{'email','phone'}.contains(idType))) throw new IllegalArgumentException('Invalid idType.');
    /* GET ADMIN USER */
    // Used to set user owner
    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();       
    System.debug('FS.ycadmissions__Default_Record_Owner_Alias__c '+FS.ycadmissions__Default_Record_Owner_Alias__c);

    User adminUser = [SELECT UserRoleId FROM User WHERE IsActive = TRUE AND userRoleId != NULL AND Alias = :FS.ycadmissions__Default_Record_Owner_Alias__c LIMIT 1];
                      /*AND UserRoleId = :opsRoleId
                      ORDER BY CreatedDate  // this is so the query is deterministic
                      LIMIT 1];*/
    System.debug('adminUser '+adminUser);
    /* SEARCH FOR EXISTING CONTACT AND LEAD */
    //Map<String,List<sObject>> matches = findMatchingContactsAndLeads(idValue, idType, form.get('first_name'), form.get('last_name'));

    List<Contact> matchedContacts = findDupContactAndLeads(form.get('first_name'), form.get('last_name'), form.get('email'), 'Contact');//(List<Contact>) matches.get('Contacts');
    List<Lead> matchedLeads = findDupContactAndLeads(form.get('first_name'), form.get('last_name'), form.get('email'), 'Lead'); //(List<Lead>) matches.get('Leads');

    Contact foundContact = matchedContacts.isEmpty() ? null : [SELECT Id, Email, leadsource, MailingPostalCode, AccountId, External_User_ID__c, LastName FROM Contact WHERE Id = :matchedContacts[0].Id LIMIT 1];
    String smsOptIn = form.get('smsOptIn');
    if(smsOptIn == null){
      smsOptIn = 'false';
    }

    if (matchedContacts.isEmpty() && matchedLeads.isEmpty()) {
      /* NEITHER FOUND */
      Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__HH_Member_RecordType_Developer_Name__c).getRecordTypeId();
      // Create a new Account and Contact for the user

      Contact con = new Contact(
        FirstName=form.get('first_name'), LastName=form.get('last_name'), MobilePhone = form.get('phone'),
        // MailingStreet = form.get('address'), MailingCity = form.get('city'), MailingState = form.get('state'),
        // State_Interested_in_Attending__c = form.get('state_interested'), 
        ycadmissions__Suffix__c = form.get('suffix'),
        // What_grade_levels_are_you_interested_in__c = form.get('gradeString').replace(',', ';'),
        MailingPostalCode=form.get('zip'), 
        // MailingCountry='United States',
        RecordTypeId=contactRecordTypeId,/*Added by R*///Community_User_Name__c =getUsernameForPhone(idValue)/*Added by R*/,
        OwnerId=adminUser.Id, ycadmissions__InitialSchool__c=schoolId, LeadSource='Direct-to-App',External_User_ID__c=null,
        // OtherStreet = form.get('address'), OtherCity = form.get('city'), OtherState = form.get('state'),
        OtherPostalCode=form.get('zip')
        // OtherCountry='United States'
      );
      Account acnt = new Account();
      if(form.get('AccountId')!=null && form.get('AccountId')!=''){
        acnt = [SELECT Id, Household_Status__c FROM Account WHERE Id = :form.get('AccountId') ];
        if(acnt.Id !=null && acnt.Household_Status__c == null){
          acnt.Household_Status__c = 'Prospect'; // When changing account logic, make sure to also update the logic in the updateConvertedLeadAccount method
          acnt.vwo_campaign_id__c = utmFields.get('vwo_campaign_id');
          acnt.vwo_campaign_name__c = utmFields.get('vwo_campaign_name');
          acnt.vwo_variation_id__c = utmFields.get('vwo_variation_id');
          acnt.vwo_variation_name__c = utmFields.get('vwo_variation_name');
          update acnt;
        }
        con.AccountId = acnt.Id;
      }
      // else if(form.get('AccountId')==null || form.get('AccountId')==''){
      //   con.accountId = form.get('AccountId');
      // }
      else{
        acnt = createAccount(form.get('first_name') + ' ' + form.get('last_name'), adminUser.Id, utmFields);
        con.AccountId = acnt.Id;
      }                           
      if (idType == 'email') {
        con.Email = idValue;
      } else if (idType == 'phone') {
        con.MobilePhone = System.UserManagement.formatPhoneNumber('1', formatPhone(idValue));
        con.Email = idValue + '@'+ form.get('carrier');
      }

      con.SMS_Opt_In__c = smsOptIn;
      con.hed__SMS_Opt_Out__c = smsOptIn == 'false';
      con.et4ae5__HasOptedOutOfMobile__c = TRUE;  
      con.UTM_Campaign__c = utmFields.get('utmCampaign');
      con.UTM_Content__c = utmFields.get('utmContent');
      con.UTM_Source__c = utmFields.get('utmSource');
      con.UTM_Term__c = utmFields.get('utmTerm');
      con.UTM_Medium__c = utmFields.get('utmMedium');
      con.UTM_ClickId__c = utmFields.get('utmClickId');
      con.UTM_ClientId__c = utmFields.get('utmClientId');
      con.UTM_Device__c = utmFields.get('utmDevice');
      con.UTM_Device_Type__c = utmFields.get('utmDeviceType');
      con.vwo_campaign_id__c = utmFields.get('vwo_campaign_id');
      con.vwo_campaign_name__c = utmFields.get('vwo_campaign_name');
      con.vwo_variation_id__c = utmFields.get('vwo_variation_id');
      con.vwo_variation_name__c = utmFields.get('vwo_variation_name');

      if(utmFields.get('referringPage')!=null) con.Registration_Referring_Page__c  = utmFields.get('referringPage');

      List<Registration_Lead_Source_Mapping__mdt> lsMtd = new List<Registration_Lead_Source_Mapping__mdt>([SELECT value__c, url_Parameter__c FROM Registration_Lead_Source_Mapping__mdt WHERE url_Parameter__c=:leadSource LIMIT 1]);
      con.LeadSource = !lsMtd.isEmpty() ? lsMtd[0].value__c : 'Direct-to-App';

      try{
        insert con;

      }
      catch(Exception e){
        if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
          String eMessage = e.getMessage().replace('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ','');
          String [] eMess = eMessage.Split(':');
          throw new AuraHandledException(eMess[0]);
        }
        else{
          throw new AuraHandledException(e.getMessage());
        }
      }
      foundContact = con;
    } else if (!matchedContacts.isEmpty() && matchedLeads.isEmpty()) {
      /* CONTACTS FOUND */
      if(!Test.isRunningTest())updateConvertedLeadAccount(foundContact.AccountId, adminUser.Id, foundContact.LastName, form.get('zip'));
    } else if (matchedContacts.isEmpty() && !matchedLeads.isEmpty()) {
      /* LEADS FOUND */
      foundContact = convertLead(matchedLeads[0], adminUser.UserRoleId, adminUser.Id, form.get('zip'));
    } else {
      /* BOTH FOUND */
      foundContact = convertLead(matchedLeads[0], adminUser.UserRoleId, foundContact, adminUser.Id, form.get('zip'));
    }

    if (!matchedContacts.isEmpty() || !matchedLeads.isEmpty()) {
      if(foundContact.External_User_ID__c==null){ foundContact.FirstName = form.get('first_name'); }
      foundContact.SMS_Opt_In__c = smsOptIn;
      foundContact.hed__SMS_Opt_Out__c = smsOptIn == 'false';
      foundContact.MobilePhone = form.get('phone');
      foundContact.MailingPostalCode=form.get('zip');
      foundContact.MailingCity=null;
      foundContact.MailingState=null;
      foundContact.MailingStreet=null;
      foundContact.OtherPostalCode=form.get('zip');
      foundContact.OtherCity=null;
      foundContact.OtherState=null;
      foundContact.OtherStreet=null;
      // String beforeGrade = form.get('gradeString');
      // List<String> splitGrades = beforeGrade.split(',');
      // foundContact.What_grade_levels_are_you_interested_in__c=String.join(splitGrades,';');
      // foundContact.State_Interested_in_Attending__c=form.get('state_interested');

      update foundContact;
    }

    /* CREATE USER */
    Profile cprofile = [SELECT Id FROM Profile WHERE Name=:FS.ycadmissions__Default_Community_Profile_Name__c];
    Id profileId = cprofile.id;
    Map<SObjectField, String> registrationAttributes = new Map<SObjectField, String>();
    if (foundContact != null) registrationAttributes.put(User.contactId, foundContact.Id);
    registrationAttributes.put(User.FirstName, form.get('first_name'));
    registrationAttributes.put(User.LastName, form.get('last_name'));
    registrationAttributes.put(User.Suffix__c, form.get('suffix'));
    registrationAttributes.put(User.LANGUAGELOCALEKEY, form.get('language') == 'en' ? 'en_US' : 'es_MX');
    String timeString = String.valueOf(Datetime.now().getTime());
    registrationAttributes.put(User.Alias, form.get('first_name').toLowerCase().left(1)+form.get('last_name').toLowerCase().left(4));
    String nickName = form.get('first_name') + ' ' + form.get('last_name') + timeString.right(8);
    // Truncate the nickName to 40 characters if it's longer
    if (nickName.length() > 40) {
        nickName = nickName.substring(0, 40);
    }
    registrationAttributes.put(User.CommunityNickname, nickName);
    registrationAttributes.put(User.ycadmissions__InitialSchool__c, schoolId);

    if (idType == 'email') {
      registrationAttributes.put(User.Email, idValue);
      // registrationAttributes.put(User.Username, idValue + '.' + Datetime.now().getTime());
      registrationAttributes.put(User.Username, idValue);
    } else if (idType == 'phone') {
      String formatNum = System.UserManagement.formatPhoneNumber('1', formatPhone(idValue));
      registrationAttributes.put(User.MobilePhone, formatNum);
      // registrationAttributes.put(User.Username, getUsernameForPhone(idValue));
      registrationAttributes.put(User.Username, getUsernameForPhone(idValue));
      System.debug('getUsernameForPhone(idValue) '+ getUsernameForPhone(idValue));
      registrationAttributes.put(User.Email, idValue + '@'+ form.get('carrier'));
    }

    System.debug('foundContact.AccountId '+foundContact.AccountId);
    
    newUserId = createUser(foundContact.AccountId, profileId, registrationAttributes, form.get('password'), foundContact, utmFields.get('termIdUrlParam'), utmFields.get('bypassTerm'));
    Contact updateFoundCon = new Contact(Id = foundContact.Id,
                                         UTM_Campaign__c = utmFields.get('utmCampaign'),
                                         UTM_Content__c = utmFields.get('utmContent'),
                                         UTM_Source__c = utmFields.get('utmSource'),
                                         UTM_Term__c = utmFields.get('utmTerm'),
                                         UTM_Medium__c = utmFields.get('utmMedium'),
                                         UTM_ClickId__c = utmFields.get('utmClickId'),
                                         UTM_ClientId__c = utmFields.get('utmClientId'),
                                         UTM_Device__c = utmFields.get('utmDevice'),
                                         UTM_Device_Type__c = utmFields.get('utmDeviceType'),
                                         vwo_campaign_id__c = utmFields.get('vwo_campaign_id'),
                                         vwo_campaign_name__c = utmFields.get('vwo_campaign_name'),
                                         vwo_variation_id__c = utmFields.get('vwo_variation_id'),
                                         vwo_variation_name__c = utmFields.get('vwo_variation_name')
                                         );
    if(utmFields.get('referringPage')!=null) updateFoundCon.Registration_Referring_Page__c  = utmFields.get('referringPage');
    List<Registration_Lead_Source_Mapping__mdt> lsMtd = new List<Registration_Lead_Source_Mapping__mdt>([SELECT value__c, url_Parameter__c FROM Registration_Lead_Source_Mapping__mdt WHERE url_Parameter__c=:leadSource LIMIT 1]);
    updateFoundcon.LeadSource = !lsMtd.isEmpty() ? lsMtd[0].value__c : 'Direct-to-App';
                                        // Community_User_Name__c = newUserId.Username);//Added by R

    update updateFoundcon;     
    FoundContact = [SELECT Id, leadsource, LastName,UTM_Campaign__c,UTM_Content__c,UTM_Source__c,UTM_Term__c,AccountId,MailingPostalCode,
                           UTM_Medium__c, UTM_ClickId__c, UTM_ClientId__c, UTM_Device__c , UTM_Device_Type__c    
                           FROM Contact where Id = :updateFoundCon.Id limit 1];
   //create account platform event

    Map<String, String> params = new Map<String, String>();
    params.put('account_creation', 'Start');
    params.put('householdId', foundContact.AccountId);
    params.put('local_hit_timestamp', system.now().format());
    params.put('campaignName', foundContact.UTM_Campaign__c);
    params.put('campaignContent', foundContact.UTM_Content__c);
    params.put('campaignSource', foundContact.UTM_Source__c);
    params.put('campaignTerm', foundContact.UTM_Term__c);
    params.put('campaignMedium', foundContact.UTM_Medium__c);
    params.put('googleClickId', foundContact.UTM_ClickId__c);
    params.put('clientId', foundContact.UTM_ClientId__c);
    params.put('campaigndevice', foundContact.UTM_Device__c);        
    params.put('campaignDeviceType', foundContact.UTM_Device_Type__c);
    Marketing_Event__e ev = new Marketing_Event__e(ContactId__c = foundContact.Id,
                                                   parameters__c = (Google_Analytics_Utility.getJSON('create_account', params, null)));
    System.debug('------- ev '+ev);
    List<Marketing_Event__e> events = new List<Marketing_Event__e>();
    events.add(ev);
    List<Database.SaveResult> results = EventBus.publish(events);
    for (Database.SaveResult sr : results) {
      if (sr.isSuccess()) {
          System.debug('Successfully published event.');
      } else {
          for(Database.Error err : sr.getErrors()) {
              System.debug('Error returned: ' +
                      err.getStatusCode() +
                      ' - ' +
                      err.getMessage());
          }
      }
    }
    //end create account platform event
    return 'success';
  }

  /**
   * This method should create a user and insert it
   * Password can be null
   * Return null or throw an exception to fail creation
   * Note: u.Id is null on success, does Site.createExternalUser not update the user id? Besides returning null it's working fine, so I'm just gonna leave it as is.
   */
  private static Id createUser(Id accountId, Id profileId, Map<SObjectField, String> registrationAttributes, String password, Contact foundId, String termIdUrlParam, String bypassTerm) {
    // Make sure required fields are set
    User u = new User();
    u.ProfileId = profileId;
    //u.PortalRole = 'PersonAccount';
    
    for (SObjectField field : registrationAttributes.keySet()) {
      String value = registrationAttributes.get(field);
      u.put(field, value);
    }

    if (!Test.isRunningTest()) Site.validatePassword(u, password, password);


    if(u.LANGUAGELOCALEKEY == NULL){
      u.languagelocalekey = UserInfo.getLocale();
    }
    u.localesidkey = UserInfo.getLocale();
    u.emailEncodingKey = 'UTF-8';
    u.timeZoneSidKey = UserInfo.getTimezone().getID();
    // if(foundId != NULL) u.ContactId = foundId;
    // Database.DMLOptions dlo = new Database.DMLOptions();

    // dlo.EmailHeader.triggeruseremail = false;
    // database.insert(u, dlo);
    // System.debug('*******User '+u);
    // System.debug('*******password '+password);

    // try{
    //   system.setPassword(u.id, password);
    // }
    // catch(Exception e){
    //   System.debug('failed');
    //   system.debug(e.getMessage());
    // }
    // System.debug('password set');
    // ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();  
    // Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__Household_RecordType_Developer_Name__c).getRecordTypeId();
    // Account userAcc = new Account(recordtypeId=accountRecordTypeId, name='temp');
    List<Contact> otherContactsInHH = new List<Contact>([SELECT Id, Email FROM Contact WHERE Email =:foundId.Email AND AccountId = :foundId.AccountId AND Id != :foundId.Id]);
    if(!otherContactsInHH.isEmpty()){
      for(Contact c : otherContactsInHH){
        c.email = c.Id + '@placeholder.com';
      }
    }
    update otherContactsInHH;
    // insert userAcc;
    Site.createExternalUser(u, accountId, password, false);
    //Added by Reshma
    List<Contact> contacttoUpdate = new List<Contact>();
    List<Contact> contactIns =new List<Contact>();
    Set<Id> contactIds = new Set<Id>();
    List<User> createdUser = [SELECT Id, Name, ContactId, Username, AccountId, Email, ProfileId,IsPortalEnabled FROM User WHERE Username = :u.Username LIMIT 1];
    if(!otherContactsInHH.isEmpty()){
      for(Contact c : otherContactsInHH){
        c.email = foundId.Email;
      }
    }
    update otherContactsInHH;

    //SYstem.debug('createdUser.get(0).contactId '+createdUser.get(0).contactId);
    System.debug('foundId '+foundId);
    if(createdUser!=null && createdUser.size()>0 && foundId!=null){
      // createdUser.get(0).IsPortalEnabled = false;
      // update createdUser;
      // Database.MergeResult results = Database.merge(foundId, createdUser.get(0).ContactId, false);
      // System.debug('results '+results);
      // Contact testCon = [SELECT Id, accountId FROM contact where Id = :foundId.Id];
      // System.debug('testCon '+testCon);

      // Account accToDelete = new Account(id=createdUser.get(0).AccountId);
      // delete accToDelete;
    }    

    if(createdUser!=null && createdUser.size()>0){
        for(User usr :createdUser){
          contactIds.add(usr.ContactId);  
        }
    }
    if(contactIds!=null && contactIds.size()>0){
      contactIns =[Select Id,Community_User_Name__c from Contact where Id = :foundId.Id];  
    }
    System.debug('Contacts :: '+contactIns);
    if(contactIns!=null && contactIns.size()>0){
        for(Contact cn : contactIns){
            for(User us: createdUser){
                //if(us.ContactId ==cn.Id){
                cn.Community_User_Name__c =us.Username;
                contacttoUpdate.add(cn);   
                //}
            }    
        }
    }
      System.debug('ContactstoU :: '+contacttoUpdate);
    if(contacttoUpdate!=null && contacttoUpdate.size()>0){
        update contacttoUpdate;
    }
     //Added by Reshma
    ApexPages.PageReference lgn = Site.login(u.username, password, '/s/new-student');
    System.debug('termIdUrlParam '+termIdUrlParam);
    System.debug('bypassTerm '+bypassTerm);

    if(termIdUrlParam !=null && bypassTerm=='1'){
      lgn = Site.login(u.username, password, '/s/new-student?termId='+termIdUrlParam+'&bypassTerm='+bypassTerm);

    }
    List<hed__Application__c> apps = new List<hed__Application__c>([SELECT Id FROM hed__Application__c WHERE Household__c = :accountId]);
    //System.debug('*************** getSiteTypeLabel() '+site.getSiteTypeLabel());
    //System.debug('*************** getDomain() '+site.getDomain());
    //System.debug('*************** getExperienceId() '+site.getExperienceId());
    //System.debug('*************** getBaseUrl() '+site.getBaseUrl());

    if(!apps.isEmpty()){
      lgn = Site.login(u.username, password, null);
    }
    if (!Test.isRunningTest()) aura.redirect(lgn);

    return u.id;
  }

  @future
  public static void correctUserContact(id userId, id vcontactId){
      update new User(id = userId, contactId = vcontactId);
  }
  private static String formatPhone(String phone) {
    if (phone == null) return null;

    Matcher matcher = Pattern.compile('[^0-9]').matcher(phone);
    phone = matcher.replaceAll('');

    if (phone.length() > 10) {
      if (phone.startsWith('1')) {
        phone = phone.substring(1);  // remove leading 1
      }
      phone = phone.left(10);  // take the first 10 digits, ignore any extensions that might have been added
    }

    return phone;
  }

  @TestVisible
  private static String getUsernameForPhone(String phone) {
    if (phone == null) return null;
    string baseurl =  system.URL.getSalesforceBaseUrl().toExternalForm();
    List<string> urlList = baseurl.split('\\.');
    string phoneEmail = urlList.get(0).substring(8, urlList.get(0).length());
    return 'phone' + formatPhone(phone) + '@'+phoneEmail+'.com';  // TODO - should be specific to this org, sandbox, etc. - not hardcoded
  }


  /**
   * Find contacts and leads that match
   * Must match both via id AND name
   */
  public static Map<String,List<sObject>> findMatchingContactsAndLeads(String idValue, String idType, String firstName, String lastName) {
    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();       
    Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__HH_Member_RecordType_Developer_Name__c).getRecordTypeId();
    Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__Household_RecordType_Developer_Name__c).getRecordTypeId();
    // Get id matches
    idType = idType.toLowerCase();
    List<List<sObject>> idMatches;

      if (idType == 'email') {
        List<Contact> foundContacts = [SELECT Id, MailingPostalCode, LastName FROM Contact
                                       WHERE (Email=:idValue)
                                       AND RecordTypeId=:contactRecordTypeId
                                       AND Account.RecordTypeId=:accountRecordTypeId];
        List<Lead> foundLeads = [SELECT Id FROM Lead
                                 WHERE (Email=:idValue)
                                 AND IsConverted=false];
        idMatches = new List<List<SObject>>{foundLeads, foundContacts};
      } else if (idType == 'phone') {
        List<Contact> foundContacts = [SELECT Id, MailingPostalCode, LastName FROM Contact
                                       WHERE (MobilePhone=:idValue OR Phone=:idValue OR HomePhone=:idValue OR OtherPhone=:idValue )
                                       AND RecordTypeId=:contactRecordTypeId
                                       AND Account.RecordTypeId=:accountRecordTypeId];
        List<Lead> foundLeads = [SELECT Id FROM Lead
                                 WHERE (MobilePhone=:idValue OR Phone=:idValue)
                                 AND IsConverted=false];
        idMatches = new List<List<SObject>>{foundLeads, foundContacts};
      } else {
        throw new IllegalArgumentException('idValue is of unknown type: '+idValue);
      }


    if (idMatches.get(0).size() < 1 && idMatches.get(1).size() < 1) return makeFmlRet(idMatches);
    Set<Id> lIds = new Set<Id>();
    Set<Id> cIds = new Set<Id>();
    for (Lead l : (List<Lead>) idMatches.get(0)) lIds.add(l.Id);
    for (Contact c : (List<Contact>) idMatches.get(1)) cIds.add(c.Id);

    // Get name matches
    List<List<sObject>> nameMatches;
    if (Test.isRunningTest()) {
      List<Lead> testLeads = [SELECT Id, OwnerId FROM Lead WHERE Id IN :lIds];
      List<Contact> testContacts = [SELECT AccountId, OwnerId, LastName FROM Contact WHERE Id IN :cIds];
      nameMatches = new List<List<sObject>>{testLeads,testContacts};
    } else {
      nameMatches = [FIND :(firstName+' '+lastName) IN NAME FIELDS RETURNING Lead(Name, Id, OwnerId WHERE Id IN :lIds), Contact(Name, AccountId, OwnerId, LastName WHERE Id IN :cIds)];
    }

    System.debug(nameMatches);
    
    return makeFmlRet(nameMatches);

  }

  private static Map<String,List<sObject>> makeFmlRet(List<List<sObject>> ll) {
    Map<String,List<sObject>> m = new Map<String,List<sObject>>();
    m.put('Leads',ll.get(0));
    m.put('Contacts',ll.get(1));
    return m;
  }

  private static Account createAccount(String n, Id owner, Map<String, String> utmFields) {
    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();  
    Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__Household_RecordType_Developer_Name__c).getRecordTypeId();
    Account acnt = new Account(RecordTypeId=accountRecordTypeId, Name=n, OwnerId=owner, Account_Record_Type_Text__c = 'Household Account', Household_Status__c = 'Prospect');
    acnt.vwo_campaign_id__c = utmFields.get('vwo_campaign_id');
    acnt.vwo_campaign_name__c = utmFields.get('vwo_campaign_name');
    acnt.vwo_variation_id__c = utmFields.get('vwo_variation_id');
    acnt.vwo_variation_name__c = utmFields.get('vwo_variation_name');
    try{
      System.debug('*** acnt '+acnt);
      insert acnt;
    }
    catch(Exception e){
      System.debug('***** '+e.getMessage());
    }
    return acnt;
  }

  public static List<SObject> findDupContactAndLeads(String firstName, String lastName, String email, String objectType){

    Map<Id, SObject> duplicates = new Map<Id, SObject>();
    List<Datacloud.FindDuplicatesResult> results = new List<Datacloud.FindDuplicatesResult>();
    if(objectType == 'Contact'){
      Contact con = new Contact();
      con.FirstName = firstName;
      con.LastName = lastName;
      con.Email = email;
      List<Contact> contactList = new List<Contact>();
      contactList.add(con); 
      results = Datacloud.FindDuplicates.findDuplicates(contactList);
    }
    else if(objectType == 'Lead'){
      Lead ld = new Lead();
      ld.FirstName = firstName;
      ld.LastName = lastName;
      ld.Email = email;
      List<Lead> leadList = new List<Lead>();
      leadList.add(ld); 
      results = Datacloud.FindDuplicates.findDuplicates(leadList);
    }
    for (Datacloud.FindDuplicatesResult findDupeResult : results) {
      for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
          if(!matchResult.getRule().startsWith('yc')) continue;
          for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
              if(String.valueOf(matchRecord.getRecord().getSObjectType()) == objectType){
                duplicates.put(matchRecord.getRecord().Id, matchRecord.getRecord());
              }
          }
        }
      }
    }
    return duplicates.values();
  }

  public static void updateConvertedLeadAccount(Id acntId, Id adminUserId, String lastName, String Zip) {
    ycadmissions__Admissions_Form_Object_Settings__c FS = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();  
    Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(FS.ycadmissions__Household_RecordType_Developer_Name__c).getRecordTypeId();
    Account acnt = [SELECT OwnerId, Owner.UserRoleId, ShippingCity, ShippingCountry, ShippingState, ShippingStreet, BillingPostalCode, BillingCity, BillingCountry, BillingState, BillingStreet, ShippingPostalCode, RecordTypeId, Household_Status__c FROM Account WHERE Id=:acntId LIMIT 1];
    acnt.OwnerId = adminUserId;
    if(zip!=null){
      acnt.BillingPostalCode = zip;
      acnt.BillingCity = null;
      acnt.BillingCountry = null;
      acnt.BillingState = null;
      acnt.BillingStreet = null;
      acnt.ShippingPostalCode = zip;
      acnt.ShippingCity = null;
      acnt.ShippingCountry = null;
      acnt.ShippingState = null;
      acnt.ShippingStreet = null;
    }
    // Require the account owner to have a role
    // if (acnt.Owner.UserRoleId == null) {
    //   User newUser = new User(Id = acnt.OwnerId, UserRoleId = urId);
    //   update newUser;
    // }
    if (acnt.recordTypeId != accountRecordTypeId) {
      acnt.recordTypeId = accountRecordTypeId;
      acnt.Account_Record_Type_Text__c = 'Household Account';
      acnt.Name = lastName + ' Household';
    }

    if (acnt.Household_Status__c == null) {
      acnt.Household_Status__c = 'Prospect'; // When changing account logic, make sure to also update the logic in the register method when no contact/lead is found
    }

    update acnt;
    System.debug('acnt '+ acnt);
    // return acnt;
  }

  public static Contact convertLead(Lead mLead, Id ownerRoleId, Id adminId, String zip) {
    return convertLead(mLead, ownerRoleId, null, adminId, zip);
  }
  
  public static Contact convertLead(Lead mLead, Id ownerRoleId, Contact con, Id adminId, String Zip) {
    // Make sure new Owner is a User
    // Id ownerId = mLead.OwnerId;
    Id ownerId = adminId;
    if (ownerId?.getSobjectType() != User.SObjectType) {
      if (con?.OwnerId?.getSobjectType() != User.SObjectType) {
        // Use default owner
        String ownerAlias = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults().ycadmissions__Default_Record_Owner_Alias__c;
        User owner = [SELECT Id FROM User WHERE Alias=:ownerAlias LIMIT 1];
        ownerId = owner.Id;
      } else {
        ownerId = con.OwnerId;
      }
    }

    // Convert the lead
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(mLead.Id);
    lc.setOwnerId(ownerId);
    System.debug('Current User: '+UserInfo.getUserId());
    lc.setDoNotCreateOpportunity(true);
    if (con != null) {
      lc.setContactId(con.Id);
      lc.setAccountId(con.AccountId);
    }
    LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
    lc.setConvertedStatus(convertStatus.MasterLabel);
    Database.LeadConvertResult lcr = Database.convertLead(lc);

    // Handle the converted stuff
    if (!lcr.isSuccess()) throw new SObjectException('Failed to convert the lead.');

    if (con == null || con.Id == null) con = [SELECT Id, Email, FirstName, LastName, MailingPostalCode, AccountId, External_User_ID__c FROM Contact WHERE Id=:lcr.getContactId() LIMIT 1];
    if(!Test.isRunningTest())updateConvertedLeadAccount(con.AccountId, ownerId, con.LastName, Zip);
    System.debug('con.AccountId ' + con.AccountId);
    //NEW CHUNK
    Map<Id, List<ycadmissions__Child__c>> childMap = new Map<Id, List<ycadmissions__Child__c>>();
    ycadmissions__Admissions_Form_Object_Settings__c orgSetting = ycadmissions__Admissions_Form_Object_Settings__c.getOrgDefaults();
        
    Id ScholarRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(orgSetting.ycadmissions__Student_RecordType_Developer_Name__c).getRecordTypeId();       
    List<Contact> insertList = new LIst<Contact>();

    for(ycadmissions__Child__c C : [SELECT Id, ycadmissions__First_Name__c, ycadmissions__Last_Name__c, ycadmissions__Grade_Interested_In__c, ycadmissions__Date_of_Birth__c, ycadmissions__Address__c,  ycadmissions__Status__c , ycadmissions__X1st_Choice_School__c FROM ycadmissions__Child__c WHERE ycadmissions__Lead__c =:mLead.Id] ){
      insertList.add(new Contact(LastName = C.ycadmissions__Last_Name__c,
                                              FirstName = C.ycadmissions__First_Name__c,
                                              Birthdate = C.ycadmissions__Date_of_Birth__c,
                                              recordTypeId = ScholarRecordTypeId ,
                                              ycadmissions__Child_Record__c = C.id,     
                                              ycadmissions__Grade_Interested_In__c = C.ycadmissions__Grade_Interested_In__c,                                                
                                              ycadmissions__X1st_Choice_School__c = C.ycadmissions__X1st_Choice_School__c,                                                   
                                              MailingStreet = C.ycadmissions__Address__c,                                                   
                                              accountId = con.AccountId));
                                           
    }
    insert insertList;
    // End NEW CHUNK

    return con;
  }

  @AuraEnabled
  public static Boolean isUserLoggedIn() {
    return UserInfo.getUserType() != 'Guest';
  }

  @AuraEnabled
  public static Boolean validateEmail(String email) {
    yc_EDQ_Email_Validator emailValidator = new yc_EDQ_Email_Validator(email);
    emailValidator.addMetadata = false;
    yc_EDQ_Email_Validator.Response response = emailValidator.send();
    return response.result.verbose == 'verified' || response.result.verbose == 'acceptAll';
  }

  @AuraEnabled
  public static Boolean validatePhone(String phoneNumber) {
    yc_EDQ_Phone_Validator phoneValidator = new yc_EDQ_Phone_Validator(phoneNumber);
    phoneValidator.addMetadata = false;
    yc_EDQ_Phone_Validator.Response response = phoneValidator.send();
    return response.result.confidence != 'unverified';
  }

  @AuraEnabled
  public static Map<String,Object> getAddressSuggestions(String streetAddress) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:Pearson_PGI/us/pvs-ad/avs');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setBody(JSON.serialize(new List<Map<String,String>>{new Map<String,String>{
      'addressComplete' => streetAddress,
      'country' => 'USA'
    }}));
    HttpResponse response = new Http().send(request);
    return (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
  }

}