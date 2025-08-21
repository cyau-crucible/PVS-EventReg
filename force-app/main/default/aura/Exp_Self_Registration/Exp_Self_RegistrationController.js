({
  doInit: function(component, event, helper) {
    component.set("v.isSpinning", true);
    console.log('begin init')
    helper.setCustomLabels(component);
    let biurl = component.get('v.backgroundImageUrl');
    if (biurl) component.set('v.backgroundImageStyle','background-image:url("'+biurl+'");');
    // Initialize v.form
    let form = {
      language: 'en',
      smsOptIn: true,
      grade: []
    };
    component.set('v.form', form);
    helper.getGradeOptionsJS(component);
    helper.getAccountDataJS(component);
    helper.setLanguage(component);
    // console.log(JSON.stringify(component.get('v.labels')));
    
    // Set the url for "Login" button
    let navService = component.find('navService');
    let pageRef = {
      type: 'comm__loginPage',
      attributes: {
        actionName: 'login'
      }
    }
    component.set('v.pageReference', pageRef);
    let defaultUrl = '#';
    navService.generateUrl(pageRef)
      .then($A.getCallback(url => {
        if (url) {
          // console.log('SCHOOOL ID ',component.get('v.schoolId'));
          // Remove the prefilled params
          url = url.substring(0,url.indexOf('?'));
          // Add my own
          let schoolId = component.get('v.schoolId');
          if (schoolId) url = url + '?schoolId='+component.get('v.schoolId');
        } else {
          url = defaultUrl;
        }
      console.log('URL ',component.get('v.url'));

        component.set('v.loginUrl', url);
      }), $A.getCallback(err => {
        component.set('v.url', defaultUrl);
      }));
    // console.log('URL ',component.get('v.url'));
    helper.isUserLoggedInJS(component);
    helper.extractUTMParameters(component);
    // helper.extractLeadSourceParameter(component);
    console.log(component.get('v.leadSource'));
    let harId = component.get('v.harId');
    if(harId!=null){
      // console.log('in the if before har logic');
      helper.getExistingHarJS(component, harId);
    }
    console.log("end init");

    component.set('v.disableAbandonBeacon', false);
    component.set("v.isSpinning", false);
    // console.log('zipCodeValid' , component.get('v.zipCodeValid'));
    // console.log('zipIsShowOnCommunity ', component.get('v.zipIsShowOnCommunity'));

  },

  trackInteraction: function (component, event, helper) {
    let interactionHistory = component.get("v.interactionHistory");
    let fieldName = event.getSource().get("v.name");

    // Avoid duplicate field entries
    if (!interactionHistory.includes(fieldName)) {
        interactionHistory.push(fieldName);
        component.set("v.interactionHistory", interactionHistory);
        console.log("User interacted with:", interactionHistory);
    }
  },

  handleLangChange: function(component, event, helper) {
    component.set('v.form.language', component.get('v.form.language') == 'en' ? 'es' : 'en');
    helper.setLanguage(component);
  },
  checkUserExists: function(component, event, helper) {


    $A.util.removeClass(component.find('esr-card'), 'hide-input-errors');

    component.set('v.errorMessage', '');
    let noEmail = component.get("v.noEmail");

    let email = component.get("v.form.email");
    let phone = component.get("v.form.phone");

    let idValue = (noEmail) ? phone : email;
    let idType = (noEmail) ? 'phone' : 'email';
    let formValid = helper.validateForm(component);
    console.log('formValid', formValid);

    if (!formValid) return;

    component.set("v.isSpinning", true);
    helper.checkUserExistsJS(component, idValue, idType);
  },
  closeModal : function(component, event, helper) {
    component.set("v.zipCodeValid", true);
  },
  handleExistingUserLoginClick: function(component, event, helper) {
    component.set('v.pwReset', event.target.id == 'pw-reset-link');
    let type = component.get('v.noEmail') ? 'phone' : 'email';
    let address = type == 'email' ? component.get('v.form.email') : component.get('v.form.phone');
    let schoolName = component.get('v.schoolName');
    let carrier = component.get('v.form.carrier');
    let vd = {address: address, type: type, sender: schoolName, carrier: carrier};
    console.log('Verif Dest: '+ JSON.stringify(vd));
    component.set('v.verificationDestination', vd);
    component.set('v.showUserVerifyModal', true);
  },

  updateShowGrades: function(component, event, helper) {
        var show = component.get('v.showGrades');
        component.set('v.showGrades', !show);
  },
  updateGradeString: function(component, event, helper) {
      var form = component.get('v.form');
      form.gradeString = form.grade.join(',')
      component.set('v.form', form);
      event.getSource().checkValidity();
  },
  handleCloseUserVerifyModal: function(component, event, helper) {
    component.set('v.showUserVerifyModal', false);
  },
  handleLogout: function(component, event, helper) {
    $A.get("e.force:logout").fire();
  },
  navHome: function(component, event, helper) {
    component.getSuper().navigate(0);
  },
  // handleZipChange: function(component, helper){
  //   console.log('handleZipChange');
  //   helper.zipCodeCheck(component);
  // },
  zipCodeCheck: function(component){
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
          console.log('result.showOnCommunity ',result.showOnCommunity);
          console.log('result.zipCodeValid ',result.zipValid);
          console.log('result.schlZipUrl ',result.zipcodeUrl);


          if(result.zipValid){
          this.callServerAction(component, 'register', { idValue: idValue, idType: idType, form: form, schoolId: schoolId,utmFields: utmFields, leadSource: leadSource
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
  Exp_input_change : function(component, event) {
    let updatedField = event.getSource().get('v.name');
    let fn = component.get('v.form.first_name');
    let ln = component.get('v.form.last_name');
    let email = component.get('v.form.email');
    let confirmEmail = component.get('v.form.email_confirm');
    let phone = component.get('v.form.phone');
    let leadSource = component.get('v.leadSource');

    // helper.formatPhoneNumber(component, event)
    // console.log(fn);
    // console.log(ln);
    // console.log(phone);
    // console.log('updatedField ',updatedField);
    // console.log('confirmEmail ',confirmEmail);
    // console.log('email ',email);

    if(confirmEmail!==undefined && email!==undefined){
      if(confirmEmail!=email){
        component.set('v.emailsDontMatch', true);
        component.set('v.emailsDontMatchText', component.get('v.labels.email_error'));
      }
      else if(confirmEmail===email){
        component.set('v.emailsDontMatch', false);
      }
    }
    if(updatedField == 'pvs-tel-nb'){
      var originalPhone = component.get('v.form.phone').replace(/\D/g,''); 
      phone = phone.replace(/\D/g,''); 
  

      if(phone.length >= originalPhone.length) {
          phone = phone.replace(/^1/, '');
          var formattedNumber = '+1-';
  
          if(phone.length > 0) formattedNumber += phone.substring(0,3);
          if(phone.length > 3) formattedNumber += '-' + phone.substring(3,6);
          if(phone.length > 6) formattedNumber += '-' + phone.substring(6,10);
  
          component.set('v.form.phone', formattedNumber);
      } else {
          component.set('v.form.phone', phone);
      }
    }

    let emailDontMatch = component.get('v.emailsDontMatch');
    console.log('emailDontMatch ', emailDontMatch);
    if((updatedField === 'pvs-e-mail' || updatedField === 'pvs-f-n' || updatedField === 'pvs-l-n' || updatedField === 'pvs-c-e-mail') && !emailDontMatch && fn!== undefined && ln!==undefined && email!==undefined){
      let action = component.get('c.checkExistingUser');
      action.setParams({fn : fn, ln : ln, email: email});
      action.setCallback(this, res => {
        let state = res.getState();
        if (state == 'SUCCESS') {
          // console.log('res  ', res[0].Id);
          let obj = res.getReturnValue();         
          component.set('v.existingRegistrant', obj);

          if(component.get('v.form.zip')===undefined || component.get('v.form.zip')==='')component.set('v.form.zip', obj.zip);
          if(component.get('v.form.state')===undefined || component.get('v.form.state')==='')component.set('v.form.state', obj.state);
          if(component.get('v.form.city')===undefined || component.get('v.form.city')==='')component.set('v.form.city', obj.city);
          if(component.get('v.form.address')===undefined || component.get('v.form.address')==='')component.set('v.form.address', obj.street);
          if(component.get('v.form.phone')===undefined || component.get('v.form.phone')==='') component.set('v.form.phone', obj.phone);
          if(component.get('v.form.state_interested')===undefined || component.get('v.form.state_interested')==='') component.set('v.form.state_interested', obj.StateOfInterest);
          if(component.get('v.form.gradeString')===undefined || component.get('v.form.gradeString')==='')component.set('v.form.gradeString', obj.gradesOfInterest);
          if(component.get('v.form.suffix')===undefined || component.get('v.form.suffix')==='')component.set('v.form.suffix', obj.suffix);


          let action2 = component.get('c.checkZipCode');
          let zip = component.get('v.form.zip')
          if(zip == undefined || zip == '' || zip.length !=5){
            component.set('v.zipCodeValid', true);
            return;
          }
          // else{
          //   component.set('v.zipCodeValid', false);
          // }
        
        action2.setParams({ zipCode: zip });
        action2.setCallback(this, res => {
            let state = res.getState();
            console.log('state ', state);
            if (state === 'SUCCESS') {
              // console.log('SUCCESS ', res.getReturnValue());
              component.set('v.zipCodeValid', res.getReturnValue().zipValid);
              component.set('v.showOnCommunity', res.getReturnValue().showOnCommunity);
              component.set('v.schlZipUrl', res.getReturnValue().zipcodeUrl);
              // console.log('Exp_input_change result.zipValid ',result.zipValid);
              // console.log('Exp_input_change result.showOnCommunity ',result.showOnCommunity);
              // console.log('Exp_input_change result.zipcodeUrl ',result.zipcodeUrl);
    
              if(res.getReturnValue()){
              this.callServerAction(component, 'register', { idValue: idValue, idType: idType, form: form, schoolId: schoolId, utmFields: utmFields, leadSource: leadSource
              }, (ths, res) => {
              //  console.log('******** res '+res);
               component.log(res);
             });
            }
            else{
              component.set('v.isSpinning', false);
            }
            } else {
                console.log(JSON.stringify(res.getError()));
            }
        });
        $A.enqueueAction(action2);
        } else {
          console.log(JSON.stringify(res.getError()));
        }
      });
      $A.enqueueAction(action);

    }
  },
  handleBlurEmail: function(component, event, helper) {
    let emailInput = component.find('email-input');
    helper.showInputValidity(emailInput, '');
    let email = component.get('v.form.email');
    if (email && emailInput.reportValidity()) {
      // Potential improvement: Do some preliminary validation here to avoid unnecessary server calls (like resetting custom validity and calling the standard validity check)
      helper.validateEmailJS(component, component.get('v.form.email'));
    } else {
      // Don't prevent form submission if email validation fails
      helper.showInputValidity(emailInput, '');
    }
  },
  handleBlurPhone: function(component, event, helper) {
    let phoneInput = component.find('phone-input');
    helper.showInputValidity(phoneInput, '');
    let phone = component.get('v.form.phone');
    if (phone && phoneInput.reportValidity()) {
      // Potential improvement: Do some preliminary validation here to avoid unnecessary server calls (like resetting custom validity and calling the standard validity check)
      helper.validatePhoneJS(component, component.get('v.form.phone'));
    } else {
      // Don't prevent form submission if phone validation fails
      helper.showInputValidity(phoneInput, '');
    }
  },
  handleChangeStreetAddress: function(component, event, helper) {
    let addressSuggestionTimeoutId = component.get('v.addressSuggestionTimeoutId');
    if (addressSuggestionTimeoutId) {
      clearTimeout(addressSuggestionTimeoutId);
    }
    addressSuggestionTimeoutId = setTimeout($A.getCallback(() => {
      helper.getAddressSuggestionsJS(component, component.get('v.form.address'));
    }), 300);
    component.set('v.addressSuggestionTimeoutId', addressSuggestionTimeoutId);
  },
  handleClickAddressSuggestion: function(component, event, helper) {
    let suggestionIndex = Number(event.target.dataset.suggestionIndex);
    if (isNaN(suggestionIndex)) return;
    let suggestions = component.get('v.addressSuggestions');
    let suggestion = suggestions[suggestionIndex];
    if (!suggestion) return;
    component.set('v.addressSuggestions', []);
    component.set('v.form.address', suggestion.addressline1);
    component.set('v.form.city', suggestion.cityOrLocality);
    component.set('v.form.state', suggestion.stateOrProvinceCode);
    component.set('v.form.zip', suggestion.postcodeComplete);
    console.log('about to check zip');
    helper.zipCodeCheckHelper(component);
  }
})