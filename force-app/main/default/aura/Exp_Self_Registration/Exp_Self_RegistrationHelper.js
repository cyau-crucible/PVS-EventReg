({
  /**
   * Gets the label for a field, translated to the current language
   */
  getLabel: function(component, name, language) {
    // `language` is an optional parameter. Recommended to provide it anyway to avoid unnecessary calls to `component.get()`
    if (language == null) language = component.get('v.form.language');
    name = name.toLowerCase();
    // Temporary implementation
    let labelMap = component.get('v.allLabels');
    try {
      return labelMap[name][language];
    } catch (e) {
      return 'ERROR: LABEL NOT FOUND: '+e.message;
    }
  },
  setLanguage: function(component) {
    let lang = component.get('v.form.language');
    let labelList = Object.keys(component.get('v.allLabels'));
    let labels = {};
    labelList.forEach(label => {
      labels[label] = this.getLabel(component,label,lang);
    });
    component.set('v.labels', labels);

    // Set spinner label language
    component.set('v.spinnerLanguage', lang == 'es' ? 'spanish' : '');
  },
  /**
   * Get Label Metadata
   */
  setCustomLabels: function(component) {
    let labels = {
      let_s_get_your_household_enrolled:{en:$A.get('$Label.c.Let_s_Get_Your_Household_Enrolled'),es:$A.get('$Label.c.Let_s_Get_Your_Household_Enrolled')},
      get_started_in_just_a_few_steps:{en:$A.get('$Label.c.Get_Started_in_just_a_Few_Steps_en'),es:$A.get('$Label.c.Get_Started_in_just_a_Few_Steps_es')},
      logged_in_user_1:{en:$A.get('$Label.c.Logged_in_User_1_en'),es:$A.get('$Label.c.Logged_in_User_1_es')},
      logout:{en:$A.get('$Label.c.logout_en'),es:$A.get('$Label.c.logout_es')},
      login_lower:{en:$A.get('$Label.c.login_en'),es:$A.get('$Label.c.login_es')},
      reset_your_password: {en:$A.get('$Label.c.to_reset_your_password_en'),es:$A.get('$Label.c.to_reset_your_password_es')},
      or:{en:$A.get('$Label.c.Or_en'),es:$A.get('$Label.c.Or_es')},
      view_your_dashboard:{en:$A.get('$Label.c.view_your_dashboard_en'),es:$A.get('$Label.c.view_your_dashboard_es')},
      continue:{en:$A.get('$Label.c.Continue_en'),es:$A.get('$Label.c.Continue_es')},
      email:{en:$A.get('$Label.c.Login_Email_en'),es:$A.get('$Label.c.Login_Email_es')},
      email_confirm:{en:$A.get('$Label.c.Login_Email_Confirm_en'),es:$A.get('$Label.c.Login_Email_Confirm_es')},
      zip_error_message:{en:$A.get('$Label.ycadmissions.New_Student_No_Schools'),es:$A.get('$Label.ycadmissions.New_Student_No_Schools')},
      warning:{en:$A.get('$Label.c.Warning'),es:$A.get('$Label.c.Warning')},
      email_error:{en:$A.get('$Label.c.Login_Email_Error_en'),es:$A.get('$Label.c.Login_Email_Error_es')},
      email_pattern_error:{en:$A.get('$Label.c.Login_Email_Pattern_Error_en'),es:$A.get('$Label.c.Login_Email_Pattern_Error_es')},
      first_name:{en:$A.get('$Label.c.Login_First_Name_en'),es:$A.get('$Label.c.Login_First_Name_es')},
      last_name:{en:$A.get('$Label.c.Login_Last_Name_en'),es:$A.get('$Label.c.Login_Last_Name_es')},
      password:{en:$A.get('$Label.c.Login_Password_Create_en'),es:$A.get('$Label.c.Login_Password_Create_es')},
      password_confirm:{en:$A.get('$Label.c.Login_Password_Confirm_en'),es:$A.get('$Label.c.Login_Password_Confirm_es')},
      password_error:{en:$A.get('$Label.c.Login_Password_Error_en'),es:$A.get('$Label.c.Login_Password_Error_es')},
      phone:{en:$A.get('$Label.c.Login_Phone_en'),es:$A.get('$Label.c.Login_Phone_es')},
      // phone_error:{en:$A.get('$Label.ycadmissions.Login_Phone_Error_en'),es:$A.get('$Label.ycadmissions.Login_Phone_Error_es')},
      phone_error:{en:$A.get('$Label.c.Login_Phone_Error_Reg_en'),es:$A.get('$Label.c.Login_Phone_Error_es')},
      submit_create:{en:$A.get('$Label.c.Login_Submit_Create_en'),es:$A.get('$Label.c.Login_Submit_Create_es')},
      carrier:{en:$A.get('$Label.c.Login_Carrier_en'),es:$A.get('$Label.c.Login_Carrier_es')},
      aura_title:{en:$A.get('$Label.c.Login_Aura_Title_en'),es:$A.get('$Label.c.Login_Aura_Title_es')},
      aura_subtitle:{en:$A.get('$Label.c.Login_Aura_Subtitle_en'),es:$A.get('$Label.c.Login_Aura_Subtitle_es')},
      aura_already_registered:{en:$A.get('$Label.c.Login_Aura_Already_Registered_en'),es:$A.get('$Label.c.Login_Aura_Already_Registered_es')},
      aura_helptext:{en:$A.get('$Label.c.Login_Aura_Helptext_en'),es:$A.get('$Label.c.Login_Aura_Helptext_es')},
      aura_footer_maintenance:{en:$A.get('$Label.c.Maintenance_Announcement'),es:$A.get('$Label.c.Maintenance_Announcement_Spanish')},
      aura_footer:{en:$A.get('$Label.c.Help_with_student_registration'),es:$A.get('$Label.c.Help_with_student_registration_Spanish')},
      aura_footer1:{en:$A.get('$Label.c.Help_with_student_registration1'),es:$A.get('$Label.c.Help_with_student_registration1_Spanish')},
	    aura_footer2:{en:$A.get('$Label.c.Terms_of_Use'),es:$A.get('$Label.c.Terms_of_Use_Spanish')},
      aura_footer3:{en:$A.get('$Label.c.Privacy_Policy'),es:$A.get('$Label.c.Privacy_Policy_Spanish')},
      aura_footer4:{en:$A.get('$Label.c.Help_with_student_registration2'),es:$A.get('$Label.c.Help_with_student_registration2_Spanish')},
	    aura_footer5:{en:$A.get('$Label.c.Contact_Us'),es:$A.get('$Label.c.Contact_Us_Spanish')},
      aura_footer6:{en:$A.get('$Label.c.Help_with_student_registration3'),es:$A.get('$Label.c.Help_with_student_registration3_Spanish')},
      aura_footer7:{en:$A.get('$Label.c.Terms_Of_Use_Link'),es:$A.get('$Label.c.Terms_Of_Use_Link')},
      aura_footer8:{en:$A.get('$Label.c.Privacy_Policy_Link'),es:$A.get('$Label.c.Privacy_Policy_Link')},
      aura_footer9:{en:$A.get('$Label.c.Contact_Us_Link'),es:$A.get('$Label.c.Contact_Us_Link')},
      aura_existing_user_1:{en:$A.get('$Label.c.Login_Aura_Existing_User_1_en'),es:$A.get('$Label.c.Login_Aura_Existing_User_1_es')},
      aura_existing_user_2:{en:$A.get('$Label.c.Login_Aura_Existing_User_2_en'),es:$A.get('$Label.c.Login_Aura_Existing_User_2_es')},
      aura_existing_user_3:{en:$A.get('$Label.c.Login_Aura_Existing_User_3_en'),es:$A.get('$Label.c.Login_Aura_Existing_User_3_es')},
      aura_logged_in_user_1:{en:$A.get('$Label.c.Login_Aura_Logged_In_User_1_en'),es:$A.get('$Label.c.Login_Aura_Logged_In_User_1_es')},
      aura_logged_in_user_2:{en:$A.get('$Label.c.Login_Aura_Logged_In_User_2_en'),es:$A.get('$Label.c.Login_Aura_Logged_In_User_2_es')},
      aura_logged_in_user_3:{en:$A.get('$Label.c.Login_Aura_Logged_In_User_3_en'),es:$A.get('$Label.c.Login_Aura_Logged_In_User_3_es')},
      here:{en:$A.get('$Label.c.Login_Here_en'),es:$A.get('$Label.c.Login_Here_es')},
      language:{en:$A.get('$Label.c.Login_Language_en'),es:$A.get('$Label.c.Login_Language_es')},
      aura_no_email_checkbox:{en:$A.get('$Label.c.Login_Aura_No_Email_Checkbox_en'),es:$A.get('$Label.c.Login_Aura_No_Email_Checkbox_es')},
      choose:{en:$A.get('$Label.c.Login_Choose_en'),es:$A.get('$Label.c.Login_Choose_es')},
      login:{en:$A.get('$Label.c.Login_Login_en'),es:$A.get('$Label.c.Login_Login_es')},
      otl_reset_header:{en:$A.get('$Label.c.Login_Otl_Reset_Header_en'),es:$A.get('$Label.c.Login_Otl_Reset_Header_es')},
      cancel:{en:$A.get('$Label.c.Login_Cancel_en'),es:$A.get('$Label.c.Login_Cancel_es')},
      email_subject:{en:$A.get('$Label.c.Login_Email_Subject_en'),es:$A.get('$Label.c.Login_Email_Subject_es')},
      your:{en:$A.get('$Label.c.Login_Your_en'),es:$A.get('$Label.c.Login_Your_es')},
      otl_btn_send:{en:$A.get('$Label.c.Login_Otl_Btn_Send_en'),es:$A.get('$Label.c.Login_Otl_Btn_Send_es')},
      otl_code_instructions:{en:$A.get('$Label.c.Login_Otl_Code_Instructions_en'),es:$A.get('$Label.c.Login_Otl_Code_Instructions_es')},
      otl_code:{en:$A.get('$Label.c.Login_Otl_Code_en'),es:$A.get('$Label.c.Login_Otl_Code_es')},
      otl_success:{en:$A.get('$Label.c.Login_Otl_Success_en'),es:$A.get('$Label.c.Login_Otl_Success_es')},
      otl_hud:{en:$A.get('$Label.c.Login_Otl_Hud_en'),es:$A.get('$Label.c.Login_Otl_Hud_es')},
      header_title:{en:$A.get('$Label.c.Login_Header_Title_en'),es:$A.get('$Label.c.Login_Header_Title_es')},
      spinning:{en:$A.get('$Label.c.Login_Spinning_en'),es:$A.get('$Label.c.Login_Spinning_es')},
      textvalid:{en:$A.get('$Label.c.Login_Valid_en'),es:$A.get('$Label.c.Login_Valid_es')},
      textinvalid:{en:$A.get('$Label.c.Login_Invalid_en'),es:$A.get('$Label.c.Login_Invalid_es')},
      requiredfieldmissing:{en:$A.get('$Label.c.Login_RequiredFieldMissing_en'),es:$A.get('$Label.c.Login_RequiredFieldMissing_es')},
      invalidformat:{en:$A.get('$Label.c.Login_InvalidFormat_en'),es:$A.get('$Label.c.Login_InvalidFormat_es')},
      numbersinname:{en:$A.get('$Label.c.Login_NumbersInNameFields_en'),es:$A.get('$Label.c.Login_NumbersInNameFields_es')},
      welcome_title:{en:$A.get('$Label.c.Login_Welcome_Title'),es:$A.get('$Label.c.Login_Welcome_Title_es')},
      sms_opt_in:{en:$A.get('$Label.c.Login_SMS_Opt_In'),es:$A.get('$Label.c.Login_SMS_Opt_In')},
      zip:{en:$A.get('$Label.c.Login_Zip_Code'),es:$A.get('$Label.c.Login_Zip_Code')},
      zip_error:{en:$A.get('$Label.c.Login_Zip_Code_Error'),es:$A.get('$Label.c.Login_Zip_Code_Error')},
      address:{en:$A.get('$Label.c.Login_Address'),es:$A.get('$Label.c.Login_Address')},
      state:{en:$A.get('$Label.c.Login_State'),es:$A.get('$Label.c.Login_State')},
      city:{en:$A.get('$Label.c.Login_City'),es:$A.get('$Label.c.Login_City')},
      state_interested:{en:$A.get('$Label.c.Login_Interested_State'),es:$A.get('$Label.c.Login_Interested_State')},
      grade:{en:$A.get('$Label.c.Login_Grades'),es:$A.get('$Label.c.Login_Grades')},
      grade_levels:{en:$A.get('$Label.c.Login_Grade_Levels'),es:$A.get('$Label.c.Login_Grade_Levels')},
      required_indication:{en:$A.get('$Label.c.Login_Indicates_Required'),es:$A.get('$Label.c.Login_Indicates_Required')},
      select_state:{en:$A.get('$Label.c.Login_Select_a_State'),es:$A.get('$Label.c.Login_Select_a_State')},
      email_invalid_format:{en:$A.get('$Label.c.Login_Email_Invalid_en')},
      phone_invalid_format:{en:$A.get('$Label.c.Login_Phone_Invalid_en')},
      phone_too_few_digits:{en:$A.get('$Label.c.Login_Phone_Too_Few_Digits_en')},
      city_required:{en:$A.get('$Label.c.Login_RequiredCityFieldMissing_en')},
      name_required:{en:$A.get('$Label.c.Login_RequiredNameFieldMissing_en')},
      email_required:{en:$A.get('$Label.c.Login_RequiredEmailFieldMissing_en')},
      address_required:{en:$A.get('$Label.c.Login_RequiredAddressFieldMissing_en')},
      state_required:{en:$A.get('$Label.c.Login_RequiredStateFieldMissing_en')},
      phone_required:{en:$A.get('$Label.c.Login_RequiredPhoneFieldMissing_en')},
      password_required:{en:$A.get('$Label.c.Login_RequiredPasswordFieldMissing_en')},
      attending_required:{en:$A.get('$Label.c.Login_RequiredAttendingFieldMissing_en')},
      suffix:{en:$A.get('$Label.c.Suffix'),es:$A.get('$Label.c.Suffix')},
      select_suffix:{en:$A.get('$Label.c.Select_Suffix'),es:$A.get('$Label.c.Select_Suffix')}
    };
    component.set('v.allLabels',labels);
    console.log('labels = ' + JSON.stringify(labels));
  },
  setAccountBranding: function(component, branding) {
    //TODO: ADD CUSTOM FONT GATHERING FROM STATIC RESOURCES
    let headerStyle = '';
    let bodyStyle = '';
    // Header
    // POTENTIAL BUG: quotes in font name could cause issues, Salesforce's js parser doesn't like escaping them
    if (branding.ycadmissions__Header_Font_Name__c) headerStyle += `font-family:'` + branding.ycadmissions__Header_Font_Name__c + `',Roboto,'Salesforce Sans',Arial;`;

    let fsize = branding.ycadmissions__Header_Font_Size__c;
    if (fsize) {
      // Add `px` unit if fsize ends with a digit
      if (/\d$/g.test(fsize.toString())) fsize += 'px';
      headerStyle += 'font-size:' + fsize + ';';
    }

    // Body
    if (branding.ycadmissions__Body_Font_Name__c) bodyStyle += "font-family:'" + branding.ycadmissions__Body_Font_Name__c + "',Roboto,'Salesforce Sans',Arial;";
    fsize = branding.ycadmissions__Body_Font_Size__c;
    if (fsize) {
      // Add `px` unit if fsize ends with a digit
      if (/\d$/g.test(fsize.toString())) fsize += 'px';
      bodyStyle += 'font-size:' + fsize + ';';
    }

    // Font Color
    let fcolor = branding.ycadmissions__Font_Color__c;
    let colorStyle = '';
    if (fcolor) {
      // If fcolor is a hex code -> prepend with #
      if (/^[0-9a-fA-F]{6}$/g.test(fcolor)) fcolor = '#' + fcolor;
      colorStyle += 'color:' + fcolor + ';';
    }

    // Set it in the DOM
    component.set('v.headerStyle', headerStyle);
    component.set('v.bodyStyle', bodyStyle);
    component.set('v.colorStyle', colorStyle);

    // Set the other things
    component.set('v.logo', branding.ycadmissions__School_Logo__c);
    if(branding.ycadmissions__School_Logo__c != undefined)
        component.set('v.logoStyle', 'background-image:url("'+branding.ycadmissions__School_Logo__c+'");');
    if(branding.ycadmissions__School__r != undefined)
        component.set('v.schoolName', branding.ycadmissions__School__r.Name);

    // Load font families
    //if (branding.Header_Font_Name__c)
    //component.set('v.colorStyle', '@font-face{font-family:\'Roboto\';src:url(/resource/Fonts/Roboto.ttf);}');
  },

  getGradeOptionsJS: function(component){
    let action = component.get('c.getGradeOptions');
    action.setCallback(this, res => {
        console.log(res.getReturnValue())
      switch (res.getState()) {
        case 'SUCCESS':
        console.log(res.getState())
          component.set('v.gradeOptions', res.getReturnValue().gradeOptions);
          component.set('v.stateOptions', res.getReturnValue().stateOptions);
          component.set('v.suffixOptions', res.getReturnValue().suffixOptions);
          break;
        case 'INCOMPLETE':
          console.log('getGradeOptions responded status: INCOMPLETE');
          break;
        case 'ERROR':
          var errors = res.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              console.log("getGradeOptions ERROR: ", errors[0].message);
            }
          } else {
            console.log("Unknown error");
          }
          break;
        default:
          console.log('getGradeOptions returned unrecgonized state: '+res.getState());
      }
    });
    $A.enqueueAction(action);
  },


  getExistingHarJS: function(component, harId){
    let action = component.get('c.getExistingHar');
    action.setParam('harId', harId);
    action.setCallback(this, res => {
        console.log(res.getReturnValue())
      switch (res.getState()) {
        case 'SUCCESS':
          let result = res.getReturnValue();
          component.set('v.form.first_name', result.FirstName);
          component.set('v.form.last_name', result.LastName);
          component.set('v.form.email', result.Email);
          component.set('v.form.email_confirm', result.Email);
          component.set('v.form.phone', result.Phone);
          component.set('v.form.AccountId', result.AccountId);

          if(result.FirstName!=null && result.FirstName!=undefined){
            component.set('v.disableHarFirstName', true);
          }
          if(result.LastName!=null && result.LastName!=undefined){
            component.set('v.disableHarLastName', true);
          }
          if(result.Email!=null && result.Email!=undefined){
            component.set('v.disableHarEmails', true);
          }
          if(result.Phone!=null && result.Phone!=undefined){
            component.set('v.disableHarPhone', true);
          }
          //$A
          // <aura:attribute name="disableHarFirstName" type="Boolean" default="false"/>
          // <aura:attribute name="disableHarLastName" type="Boolean" default="false"/>
          // <aura:attribute name="disableHarEmails" type="Boolean" default="false"/>
          // <aura:attribute name="disableHarPhone" type="Boolean" default="false"/>
          //
          break;
        case 'INCOMPLETE':
          console.log('getExistingHarJS responded status: INCOMPLETE');
          break;
        case 'ERROR':
          var errors = res.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              console.log("getExistingHarJS ERROR: ", errors[0].message);
            }
          } else {
            console.log("Unknown error");
          }
          break;
        default:
          console.log('getGradeOptions returned unrecgonized state: '+res.getState());
      }
    });
    $A.enqueueAction(action);
  },

  getAccountDataJS: function(component) {
    var urlString = window.location.href;
    var url = new URL(urlString);
    var schoolId = url.searchParams.get('schoolId');
  
    // Set the value of v.schoolId
    component.set('v.schoolId', schoolId);
    let accountId = component.get('v.schoolId');
    /*if (!accountId) {
      accountId = component.get("v.pageReference").state.schoolId;
      console.log('Acnt Id: ' + accountId);
    } else {console.log('Given Acnt Id: ' + accountId);}*/
    if (accountId == null || accountId == '') {
      console.error('No schoolId given.');
      return null;
    }
    let action = component.get('c.getAccountData');
    action.setParam('accountId', accountId);
    action.setCallback(this, res => {
        console.log(res.getReturnValue())
      switch (res.getState()) {
        case 'SUCCESS':
        console.log(res.getState())
          this.setAccountBranding(component, res.getReturnValue().branding);
          // component.set('v.allowCellPhone', res.getReturnValue().account.Allow_Cell_Phone_Login__c);
          component.set('v.allowCellPhone', false);

          if(res.getReturnValue().orgSettingAllowCellPhone === false){
            component.set('v.allowCellPhone', false);
          }
          this.setLanguage(component);
          break;
        case 'INCOMPLETE':
          console.log('getAccountBranding responded status: INCOMPLETE');
          break;
        case 'ERROR':
          var errors = res.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              console.log("getAccountBranding ERROR: ", errors[0].message);
            }
          } else {
            console.log("Unknown error");
          }
          break;
        default:
          console.log('getAccountBranding returned unrecgonized state: '+res.getState());
      }
    });
    $A.enqueueAction(action);
  },
  getAllowCellPhoneJS: function(component) {
    let schoolId = component.get('v.schoolId');
    console.log('schoolId ', schoolId);
    if (!schoolId) {
        console.log('No schoolId given.');
        return;
    }
    console.log('Here1');
    let action = component.get('c.getAllowCellPhone');
    action.setParams({
      accountId: schoolId,
   });
   action.setCallback(this, (a) => {
       console.log(a.getReturnValue())
       if(a.getReturnValue() != null){
          component.set('v.allowCellPhone', a.getReturnValue().Allow_Cell_Phone_Login__c);           
       }
   });
   $A.enqueueAction(action);
    // action.setCallback(this, response => {
    //     let state = response.getState();
    //     if (state === 'SUCCESS') {
    //         let allowCellphone = response.getReturnValue();
    //         component.set('v.allowCellPhone', allowCellphone.Allow_Cell_Phone_Login__c);
    //     } else if (state === 'ERROR') {
    //         let errors = response.getError();
    //         if (errors && errors[0] && errors[0].message) {
    //             console.log('Error: ' + errors[0].message);
    //         } else {
    //             console.log('Unknown error occurred.');
    //         }
    //     }
    //     else{
    //       console.log('ELSE');
    //     }
    // });
    console.log('--- ',JSON.stringify(action.getError()));
    console.log('Here3');
  },
  callServerAction: function(component, methodName, params, successHandler) {
    let action = component.get("c." + methodName);

    //console.log('Calling Action: ' + methodName + ' Params: ' + JSON.stringify(params));
    if (params) action.setParams(params);

    action.setCallback(this, function (response) {
      let state = response.getState();
      console.log('response '+response.getReturnValue());
      component.set("v.isSpinning", false);
      console.log('******* STATE: '+state);
      if (state === "SUCCESS") {
        let result = response.getReturnValue();

        console.log("Result from server: ", result);
        successHandler(this, result);
      } else if (state === "INCOMPLETE") {
        console.log("Incomplete");
        // do something
      } else if (state === "ERROR") {
        let errors = response.getError();

        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("errors[0].message", errors[0].message);
            console.log("errors", errors);
            console.log("errors[0]", errors[0]);
            console.log("errors[1]", errors[1]);

            component.set('v.errorMessage', errors[0].message.replace(/^\[?([A-Z_]+: )?([^\]]*)\]?$/, '$2'));
            let lang = component.get('v.form.language');
            let errmsg = component.get('v.errorMessage');
            if(lang == 'es' && errmsg.startsWith(this.getLabel(component,'numbersinname','en'))){
              component.set('v.errorMessage',this.getLabel(component,'numbersinname','es'));
            }
            
            console.log("Error message", JSON.stringify(errors[0]));
          }
        } else {
          console.log("Unknown error");
        }
      }
    });

    $A.enqueueAction(action);
  },
  checkUserExistsJS: function(component, idValue, idType) {
    this.callServerAction(component, 'userExists', { idValue : idValue, idType : idType }, function(ths, result) {
        component.set('v.userExists', result);

        component.set('v.errorMessage', '');
        if (!result) {
          console.log('**** result '+result);
          ths.registerJS(component, idValue, idType);
        }
    });
  },
  // zipCodeCheck: function(component){
  //   let action = component.get('c.checkZipCode');
  //   action.setParams({ zipCode: zip });
  //   action.setCallback(this, res => {
  //       let state = res.getState();
  //       console.log('state ', state);
  //       if (state === 'SUCCESS') {
  //         console.log('SUCCESS ', res.getReturnValue());
  //         component.set('v.zipCodeValid', res.getReturnValue());

  //         if(res.getReturnValue()){
  //         this.callServerAction(component, 'register', { idValue: idValue, idType: idType, form: form, schoolId: schoolId,utmFields: utmFields
  //         }, (ths, res) => {
  //          console.log('******** res '+res);
  //          component.log(res);
  //        });
  //       }
  //       else{
  //         component.set('v.isSpinning', false);
  //       }
  //       } else {
  //           console.log(JSON.stringify(res.getError()));
  //       }
  //   });
  //   $A.enqueueAction(action);
  // },
  registerJS: function(component, idValue, idType) {
    console.log('registerJS');
    // Validate form
    let formValid = this.validateForm(component);
    if (!formValid) {
      return;
    }
    component.set('v.isSpinning', true);

    let form = component.get('v.form');
    form.grade = '';
    console.log('form ', form);
    let zip = form.zip;
    let schoolId = component.get('v.schoolId');
    let utmFields = this.getUTMParameters(component);
    let leadSource = component.get('v.leadSource');
    component.set('v.disableAbandonBeacon', true);

    /*let action = component.get('c.checkZipCode');
    action.setParams({ zipCode: zip });
    action.setCallback(this, res => {
        let state = res.getState();
        console.log('state ', state);
        if (state === 'SUCCESS') {
          console.log('SUCCESS ', res.getReturnValue());
          component.set('v.zipCodeValid', res.getReturnValue());

          if(res.getReturnValue()){*/
            this.callServerAction(component, 'register', { idValue: idValue, idType: idType, form: form, schoolId: schoolId,utmFields: utmFields, leadSource: leadSource
            }, (ths, res) => {
             console.log('******** res '+res);
             component.log(res);
           });
          /*}
          else{
            component.set('v.isSpinning', false);
          }
        } else {
            console.log(JSON.stringify(res.getError()));
        }
    });
    $A.enqueueAction(action);*/
  },

validateForm: function(component) {
    let form = component.get('v.form');
    let noEmail = component.get('v.noEmail');
    var emailsMatch = true;
    var errorMessage = '';
    // Check that email fields match
    console.log('validateForm');
    if (!noEmail && form.email != undefined && form.email_confirm != undefined && form.email.toLowerCase() != form.email_confirm.toLowerCase()) {
        errorMessage += component.get('v.labels.email_error') +'<br /> ';
      emailsMatch = false;
    }
    var zipCodeValid = true;
    var firstNameValid = true;
    var middleNameValid = true;
    var lastNameValid = true;


    let zipCode = form.zip;
    if(zipCode != '' && zipCode != undefined){
        zipCodeValid = /(^\d{5}$)|(^\d{5}-\d{4}$)/.test(zipCode);
        if(!zipCodeValid){
            errorMessage += component.get('v.labels.zip_error') +'<br />  ';
        }
    }
    let firstName = form.first_name;
    console.log('firstName ',firstName);

    const regexStr = "^[A-Za-zÀ-ÖØ-öø-əḈ-ỹ\\s\\-']+$";
    const regex = new RegExp(regexStr);
    console.log('regex ',regex);
    if(firstName != '' && firstName != undefined){
      firstNameValid = regex.test(firstName);
    }
    let lastName = form.last_name;
    if(lastName != '' && lastName != undefined){
        lastNameValid = regex.test(lastName);
    }
    console.log('firstNameValid ',firstNameValid);
    console.log('lastNameValid ',lastNameValid);

    if(!firstNameValid || !lastNameValid){
      errorMessage += component.get('v.labels.numbersinname') +'<br />  ';
  }

    var phoneValid = true;
    let phone = form.phone;
    if(phone != '' && phone != undefined){
        phoneValid = /(^\+1-\d{3}-\d{3}-\d{4}$)/.test(phone);
        if(!phoneValid){
            errorMessage += component.get('v.labels.phone_error') +'<br />  ';
        }
    }

    let allInputs = component.find('input');
    let emailInput = component.find('email-input');
    if (emailInput) allInputs.push(emailInput);
    let phoneInput = component.find('phone-input');
    if (phoneInput) allInputs.push(phoneInput);

    var focusOnFirst = false;
    console.log('focusOnFirst ', focusOnFirst)

    let allValid = allInputs.flat().reduce(function (validSoFar, inputCmp) {
      inputCmp.reportValidity();
      if(!inputCmp.checkValidity() && !focusOnFirst){         
          console.log('SHOULD BE FOCUSING ON INPUT');  
          inputCmp.focus();
          focusOnFirst = true;
      }
      return validSoFar && inputCmp.checkValidity();
    }, true);
    console.log('ErrorMEssage: ', errorMessage);
    component.set('v.errorMessage', errorMessage);
    if (!firstNameValid || !lastNameValid || !allValid || !emailsMatch || !zipCodeValid || !phoneValid || !component.get('v.zipCodeValid')) return false;
    if (noEmail) allValid = component.get('v.form.carrier') != '';
    console.log('allValid ',allValid);
    return allValid;
  },
  

  isUserLoggedInJS: function(component) {
    let action = component.get('c.isUserLoggedIn');
    action.setCallback(this, res => {
      let state = res.getState();
      if (state == 'SUCCESS') {
        component.set('v.userLoggedIn', res.getReturnValue());
      } else {
        console.log(JSON.stringify(res.getError()));
      }
    });
    $A.enqueueAction(action);
  },


  getUTMParameters: function(component) {

    var utmFields = {
        utmCampaign: component.get("v.utmCampaign"),
        utmContent: component.get("v.utmContent"),
        utmSource: component.get("v.utmSource"),
        utmTerm: component.get("v.utmTerm"),
        utmMedium: component.get("v.utmMedium"),
        utmClickId: component.get("v.utmClickId"),
        utmClientId: component.get("v.utmClientId"),
        utmDevice: component.get("v.utmDevice"),
        utmDeviceType: component.get("v.utmDeviceType"),
        referringPage: component.get("v.referringPage"),
        vwo_variation_name: component.get("v.vwo_variation_name"),
        vwo_variation_id: component.get("v.vwo_variation_id"),
        vwo_campaign_name: component.get("v.vwo_campaign_name"),
        vwo_campaign_id: component.get("v.vwo_campaign_id")
    };
    console.log('utmFields ', utmFields)
    var userAgent = navigator.userAgent;
    console.log('userAgent', userAgent);
    return utmFields;
  },

  // extractLeadSourceParameter: function(component) {
  //   console.log('extractLeadSourceParameter');
  //   var urlString = window.location.href;
  //   var url = new URL(urlString);
  //   component.set("v.leadSource", url.searchParams.get("ls"));
  // },

  extractUTMParameters: function(component) {
    console.log('extractUTMParameters');
    console.log('document.referrer ', document.referrer);
    var urlString = window.location.href;
    var url = new URL(urlString);
    if(document.referrer === 'https://www.connectionsacademy.com/'){
      component.set("v.leadSource", 'aemweb');
      // component.set("v.referringPage", document.referrer);
    }
    if(document.referrer === 'https://learn.connectionsacademy.com/'){
      component.set("v.leadSource", 'aemlp');
      // component.set("v.referringPage", document.referrer);
    }

    component.set("v.leadSource", url.searchParams.get("ls"));
    component.set("v.referringPage", document.referrer);
    component.set("v.utmCampaign", url.searchParams.get("utm_campaign"));
    component.set("v.utmContent", url.searchParams.get("utm_content"));
    component.set("v.utmSource", url.searchParams.get("utm_source"));
    component.set("v.utmTerm", url.searchParams.get("utm_term"));
    component.set("v.utmMedium", url.searchParams.get("utm_medium"));
    component.set("v.utmClickId", url.searchParams.get("gclid"));
    component.set("v.utmClientId", url.searchParams.get("_ga"));
    component.set("v.harId", url.searchParams.get("harId"));
    component.set("v.vwo_variation_name", url.searchParams.get("vwo_variation_name"));
    component.set("v.vwo_variation_id", url.searchParams.get("vwo_variation_id"));
    component.set("v.vwo_campaign_name", url.searchParams.get("vwo_campaign_name"));
    component.set("v.vwo_campaign_id", url.searchParams.get("vwo_campaign_id"));

    var userAgent = navigator.userAgent;
    component.set("v.utmDevice", userAgent);

    var width = window.screen.availWidth;
    var height = window.screen.availHeight;
    var screenType;
      if(width <=520 || height <= 520) {
      screenType = "mobile";
    } else if (width <= 756 || height <= 756) {
      screenType = "tablet";
    } else {
      screenType = "desktop";
    }
    component.set("v.utmDeviceType", screenType);
    var utmData = {
      utmCampaign: url.searchParams.get("utm_campaign"),
      utmContent: url.searchParams.get("utm_content"),
      utmSource: url.searchParams.get("utm_source"),
      utmTerm: url.searchParams.get("utm_term"),
      utmMedium: url.searchParams.get("utm_medium"),
      utmClickId: url.searchParams.get("gclid"),
      utmClientId: url.searchParams.get("_ga"),
      harId: url.searchParams.get("harId"),
      utmDevice: navigator.userAgent,
      utmDeviceType: screenType,
      leadSource: url.searchParams.get("ls"),
      referringPage: component.get("v.referringPage")
    };
    component.set("v.utmData", utmData);
    console.log('utmData', utmData);
    console.log('userAgent', userAgent);
  }, 

  formatPhoneNumber: function(component, event) {
    // Get the input value
    var phoneNumber = component.find("phoneNumber").get("v.value");

    // Remove non-numeric characters from the input
    var cleanedPhoneNumber = phoneNumber.replace(/\D/g, '');

    // Format the phone number
    var formattedPhoneNumber = '';
    if (cleanedPhoneNumber.length >= 1) {
        formattedPhoneNumber += "+";
    }
    if (cleanedPhoneNumber.length >= 2) {
        formattedPhoneNumber += cleanedPhoneNumber.substring(0, 1) + "-";
    }
    if (cleanedPhoneNumber.length >= 4) {
        formattedPhoneNumber += cleanedPhoneNumber.substring(1, 4) + "-";
    }
    if (cleanedPhoneNumber.length >= 7) {
        formattedPhoneNumber += cleanedPhoneNumber.substring(4, 7) + "-";
    }
    if (cleanedPhoneNumber.length >= 10) {
        formattedPhoneNumber += cleanedPhoneNumber.substring(7);
    }

    // Set the formatted phone number back to the input field
    component.find("phoneNumber").set("v.value", formattedPhoneNumber);
  },
  validateEmailJS: function(component, email) {
    let emailInput = component.find('email-input');
    this.showInputValidity(emailInput, '');
    let action = component.get('c.validateEmail');
    action.setParams({ email: email });
    action.setCallback(this, res => {
      let state = res.getState();
      if (state === 'SUCCESS') {
        let emailValid = res.getReturnValue();
        //console.log('emailValid: ', emailValid);
        this.showInputValidity(emailInput, emailValid ? '' : component.get('v.labels.email_invalid_format'));
      } else {
        // Don't prevent form submission if email validation fails
        this.showInputValidity(emailInput, '');
        console.error('ERROR validating email: ', JSON.stringify(res.getError()));
      }
    });
    $A.enqueueAction(action);
  },
  validatePhoneJS: function(component, phoneNumber) {
    let phoneInput = component.find('phone-input');
    this.showInputValidity(phoneInput, '');
    let action = component.get('c.validatePhone');
    action.setParams({ phoneNumber: phoneNumber });
    action.setCallback(this, res => {
      let state = res.getState();
      if (state === 'SUCCESS') {
        let phoneValid = res.getReturnValue();
        //console.log('phoneValid: ', phoneValid);
        let validityMessage = '';
        if (!phoneValid) {
          if (phoneNumber && phoneNumber.replace(/[- )(]/g, '').length < 11) {
            validityMessage = component.get('v.labels.phone_too_few_digits');
          } else {
            validityMessage = component.get('v.labels.phone_invalid_format');
          }
        }
        this.showInputValidity(phoneInput, validityMessage);
      } else {
        // Don't prevent form submission if phone validation fails
        this.showInputValidity(phoneInput, '');
        console.error('ERROR validating phone number: ', JSON.stringify(res.getError()));
      }
    });
    $A.enqueueAction(action);
  },
  showInputValidity: function(input, message) {
    if (!input) return;
    if (!Array.isArray(input)) input = [input];
    for (const elem of input) {
      elem.setCustomValidity(message);
      elem.reportValidity();
    }
  },
  zipCodeCheckHelper: function(component){
    console.log('Zip Code Check');
    let action = component.get('c.checkZipCode');
    let zip = component.get('v.form.zip');
    let leadSource = component.get('v.leadSource');
    // console.log('zip.length ',zip.length);
    if(zip == undefined || zip == '' || zip.length !=5){
        component.set('v.zipCodeValid', true);
        return;
    }
    // else{
    //   component.set('v.zipCodeValid', false);
    // }
    
    action.setParams({ zipCode: zip });
    action.setCallback(this, res => {
        let state = res.getState();
        console.log('state ', state);
        if (state === 'SUCCESS') {
          console.log('SUCCESS ', res.getReturnValue());
          let result  = res.getReturnValue();
          component.set('v.zipIsShowOnCommunity', result.showOnCommunity);
          component.set('v.zipCodeValid', result.zipValid);
          // component.set('v.zipIsShowOnCommunity', result.showOnCommunity);
          component.set('v.schlZipUrl', result.zipcodeUrl);

          if(result.zipValid){
          this.callServerAction(component, 'register', { idValue: idValue, idType: idType, form: form, schoolId: schoolId,utmFields: utmFields, leadSource : leadSource
          }, (ths, res) => {
          //  console.log('******** res '+res);
         });
        }
        else{
          component.set('v.isSpinning', false);
        }
        } else {
            console.log(JSON.stringify(res.getError()));
        }
    });
    $A.enqueueAction(action);
  },
  getAddressSuggestionsJS: function(component, streetAddress) {
    let action = component.get('c.getAddressSuggestions');
    action.setParams({ streetAddress: streetAddress });
    action.setCallback(this, res => {
      let state = res.getState();
      if (state === 'SUCCESS') {
        //console.log('address suggestions: ', JSON.stringify(res.getReturnValue()));
        let suggestions = res.getReturnValue().addressDoctorTypeResponse;
        /* Removed because it's not in the original site, but this is a good idea because it removes the nonsense suggestion that just copies the input if you enter an invalid address
        suggestions = suggestions.filter ? suggestions.filter(suggestion => suggestion.matchcode !== 'Q0') : suggestions;
        */
        let suggestionsToDisplay = [];
        for (const suggestion of suggestions) {
          if (!suggestion.addressline1) continue;
          suggestion.displayValue = (
            suggestion.addressline1 + ',' +
            (suggestion.cityOrLocality ? ' ' + suggestion.cityOrLocality : '') +
            (suggestion.stateOrProvinceCode ? ' ' + suggestion.stateOrProvinceCode : '') +
            (suggestion.postalcodeComplete ? ' ' + suggestion.postalcodeComplete : '')
          ).replace(/,$/, '');
          suggestionsToDisplay.push(suggestion);
        }
        component.set('v.addressSuggestions', suggestionsToDisplay);
      } else {
        console.error('ERROR getting address suggestions: ', JSON.stringify(res.getError()));
      }
    });
    $A.enqueueAction(action);
  },
  toggleShowGrades: function (component) {
    var showGrades = component.get("v.showGrades");
    component.set("v.showGrades", !showGrades);
  },
})