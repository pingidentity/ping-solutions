    
    it('500-branding_theme_set', () => {
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
      // go to experiences, check theme, content
      cy.get('[data-id="sidebar-section_experiences"]').click();
      cy.get('[data-id="sidebar-node_branding"]').click();
      cy.getIframeBody().find('.tile-button__grid').contains('Ping Focus');
      cy.getIframeBody().find('.tile-button__grid').contains('Ping Mural');
      cy.getIframeBody().find('.tile-button__grid').contains('Ping Slate');
      cy.getIframeBody().find('.tile-button__grid').contains('Ping Split');    
    })