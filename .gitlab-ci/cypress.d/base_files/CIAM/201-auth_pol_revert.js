    
    it('201-auth_pol_revert', () => {
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
      //go to authentication policies
      cy.get('[data-id="sidebar-section_experiences"]').click();
      cy.get('[data-id="sidebar-node_signonpolicies"]').click();
      //find no remaining values
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').should('not.have.text', 'Demo_Self-Registration_Login_Policy');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').should('not.have.text', 'Demo_Passwordless_Any_Method_Login_Policy');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').should('not.have.text', 'Demo_Passwordless_SMS_Login_Policy');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').should('not.have.text', 'Demo_Multi_Factor_Login_Policy');    
    })
