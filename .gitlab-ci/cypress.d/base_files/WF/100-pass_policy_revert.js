    
    it('100-pass_policy_revert', () => {
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
      //finally, let's look at some password policies!
      cy.get('[data-id="sidebar-section_experiences"]').click();
      cy.get('.nav-sidebar__node').contains('Password Policies').click();
      cy.getIframeBody().find('[data-id="policy-name-field-input"]').should('have.value','Basic');
    })
