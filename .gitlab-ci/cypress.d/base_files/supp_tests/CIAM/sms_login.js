it('Test SMS passwordless login', () => {
    //opening the SMS sign in page, if app name changes we'll need to update that
    cy.visit('https://auth-staging.pingone.com/ENV_ID/saml20/idp/startsso?spEntityId=demo_app_2')
    cy.get('#username').type('TEST_USERNAME');
    cy.get('[data-id="submit-button"]').click();
    //this gets the SMS sent for login from the RingCentral API. wait 5 seconds to allow for latency with sending.
    cy.wait(7000).request({
        method: 'GET',
        url: 'https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/message-store?page=1&perPage=100',
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer RO_TOKEN'
        }
      }).then((response) => {
        cy.log(response)
        var mess_subject = response.body.records[0].subject
        var mess_id = response.body.records[0].id
        var num_pattern = /[0-9]+/g;
        var new_sub = mess_subject.match(num_pattern)
        var sms_number = JSON.stringify(new_sub).slice(2, -2)
        //fill in the SMS text
        cy.get('#otp-code').type(sms_number);
        cy.get('[data-id="sign-on"]').click();
        //delete message from RingCentral. keep this clean!
        cy.request({
            method: 'DELETE',
            url: 'https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/message-store/'+mess_id+'?purge=true',
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer RO_TOKEN'
            }
        })

     })
     //make sure we made it to httpbin. Not looking for anything special, but URL should include /anything
     cy.url().should('include', 'saml');
})
