    
    it('400-pf_admin_sso_revert', () => {
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
      // go to admin sso attribute, find expected value
      cy.get('[data-id="sidebar-section_users"]').click();
      cy.get('[data-id="sidebar-node_attributes"]').click();
      cy.wait(1000).getIframeBody().find('[data-id="searchBox-input"]').type('pf-admin-role');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').should('not.contain','pf-admin-role')
      // go to admin account
      cy.get('[data-id="sidebar-node_user"]').click();
      cy.getIframeBody().find('[data-id="messages"]').should('not.contain','PingFederateAdmin')
      // go to admin sso app
      cy.get('[data-id="sidebar-section_connections"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('PingFederate');
      cy.getIframeBody().find('[data-id="batch"]').should('not.contain','PingFederate Admin SSO');
    })
