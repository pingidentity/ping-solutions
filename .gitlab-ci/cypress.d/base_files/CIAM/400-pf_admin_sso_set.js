    
    it('400-pf_admin_sso_set', () => {
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
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('pf-admin-role');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').contains('pf-admin-role');
      // go to admin account
      cy.get('[data-id="sidebar-node_user"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('PingFederateAdmin');
      cy.getIframeBody().find('[data-id="user-list"]').contains('PingFederateAdmin')
      // go to admin sso app
      cy.get('[data-id="sidebar-section_connections"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('PingFederate');
      cy.getIframeBody().find('[data-id="app-row"]').contains('PingFederate Admin SSO');
      cy.getIframeBody().find('[data-id="expand-btn"]').click();
      cy.getIframeBody().find('[data-id="rocker-label_ATTRIBUTES"]').click();
      cy.getIframeBody().find('[data-id="icon-content"]').contains('pf-admin-role');    
    })
