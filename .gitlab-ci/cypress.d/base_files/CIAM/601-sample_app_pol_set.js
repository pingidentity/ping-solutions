    
    it('601-sample_app_pol_set', () => {
      cy.visit('https://console.pingone.com/?env=ENV_ID');
       //login
       cy.url().then(($url) => {
        if($url.includes('signon')) {
          cy.get('#username').type('TEST_USERNAME');
          cy.get('#password').type('TEST_PASSWORD');
          cy.get('.button').click();
        }
      })
      //conditionally click
      if(cy.get('[data-id="guide-close-button"]').should('be.visible'))
      {
        cy.get('[data-id="guide-close-button"]').click();
      }      
      //switch to environment
      cy.get('.astro-environment-selector__trigger').click();
      cy.get('.astro-environment-selector__environment').contains('ENV_NM').click();
      // go to sso apps, check policies
      cy.get('[data-id="sidebar-section_connections"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('Any');
      cy.getIframeBody().find('[data-id="app-row"]').contains('Demo App - Passwordless Login Any Method')
      cy.getIframeBody().find('[data-id="expand-btn"]').click();
      cy.getIframeBody().find('[data-id="rocker-label_POLICIES"]').click();
      cy.getIframeBody().find('[data-id="page-section"]').contains('Demo_Passwordless_Any_Method_Login_Policy')
      cy.getIframeBody().find('[data-id="searchBox-input"]').focus().clear();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('SMS');
      cy.getIframeBody().find('[data-id="app-row"]').contains('Demo App - Passwordless Login SMS Only')
      cy.getIframeBody().find('[data-id="expand-btn"]').click();
      cy.getIframeBody().find('[data-id="rocker-label_POLICIES"]').click();
      cy.getIframeBody().find('[data-id="page-section"]').contains('Demo_Passwordless_SMS_Login_Policy')
      cy.getIframeBody().find('[data-id="searchBox-input"]').focus().clear();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('Registration');
      cy.getIframeBody().find('[data-id="app-row"]').contains('Demo App - Self-Service Registration')
      cy.getIframeBody().find('[data-id="expand-btn"]').click();
      cy.getIframeBody().find('[data-id="rocker-label_POLICIES"]').click();
      cy.getIframeBody().find('[data-id="page-section"]').contains('Demo_Self-Registration_Login_Policy'); 
    })
