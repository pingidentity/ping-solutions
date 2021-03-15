  
  it('300-user_populations_revert', () => {
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
    cy.get('[data-id="sidebar-section_users"]').click();
    cy.get('[data-id="sidebar-node_population"]').click();
    cy.getIframeBody().find('[data-id="searchBox-input"]').type('Employees');
    cy.getIframeBody().find('[data-id="populations-list"]').should('not.contain','Employees')
    cy.getIframeBody().find('[data-id="searchBox-input"]').focus().clear();
    cy.getIframeBody().find('[data-id="searchBox-input"]').type('Contrators');
    cy.getIframeBody().find('[data-id="populations-list"]').should('not.contain','Contractors')
    cy.getIframeBody().find('[data-id="searchBox-input"]').focus().clear();
    cy.getIframeBody().find('[data-id="searchBox-input"]').type('Sample Users');
    cy.getIframeBody().find('[data-id="populations-list"]').contains('Sample Users')
    cy.getIframeBody().find('[data-id="searchBox-input"]').focus().clear();
    cy.getIframeBody().find('[data-id="searchBox-input"]').type('More Sample Users');
    cy.getIframeBody().find('[data-id="populations-list"]').contains('More Sample Users');
  })
