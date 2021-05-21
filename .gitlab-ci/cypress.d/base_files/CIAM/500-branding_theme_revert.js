    
    it('500-branding_theme_revert', () => {
      cy.visit('https://console-staging.pingone.com/?env=ENV_ID');
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
      // go to experiences, check theme, content
      cy.get('[data-id="sidebar-section_experiences"]').click();
      cy.get('[data-id="sidebar-node_branding"]').click();
      cy.getIframeBody().find('.tile-button__grid').should('not.contain','Ping Focus');
      cy.getIframeBody().find('.tile-button__grid').should('not.contain','Ping Mural');
      cy.getIframeBody().find('.tile-button__grid').should('not.contain','Ping Slate');
      cy.getIframeBody().find('.tile-button__grid').should('not.contain','Ping Split');  
    })
