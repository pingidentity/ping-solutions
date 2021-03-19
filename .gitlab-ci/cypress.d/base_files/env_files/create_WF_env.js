Cypress.Commands.add('getIframeBody', () => {
    // get the iframe > document > body
    // and retry until the body element is not empty
    return cy
    .get('iframe[data-id="content-iframe"]')
    .its('0.contentDocument.body').should('not.be.empty')
    // wraps "body" DOM element to allow
    // chaining more Cypress commands, like ".find(...)"
    // https://on.cypress.io/wrap
    .then(cy.wrap)
  })


describe('Creating new P14C environment', () => {
    it('Visits ENV_NM PingOne Console and creates base environment', () => {
      Cypress.on('uncaught:exception', (err, runnable) => {
        // returning false here prevents Cypress from
        // failing the test
        // sign in caused problems without this... I don't care, it still fails if we messed something up.
        expect(err.message).to.include('error originated from your application code');
        return false
    })
      cy.visit('https://console.pingone.com/?env=ENV_ID');
      //login
      cy.url().then(($url) => {
        if($url.includes('signon')) {
          cy.get('#username').type('TEST_USERNAME');
          cy.get('#password').type('TEST_PASSWORD');
          cy.get('.button').click();
        }
      })
      if(cy.url().should('not.include', '/myping/home'))
      {
          cy.log('Warning, could not log in successfully')
      }
      //conditionally click
      if(cy.get('[data-id="guide-close-button"]').should('be.visible'))
      {
        cy.get('[data-id="guide-close-button"]').click();
      }
      //select new environment
      cy.get('.nav-sidebar__top-container').click();
      //create environment
      cy.get('.astro-environment-selector__trigger').click();
      cy.get('.astro-environment-selector__environment').contains('Home').click();
      if(cy.get('[data-id="guide-close-button"]').should('be.visible'))
      {
          cy.get('[data-id="guide-close-button"]').click();
      }
      cy.getIframeBody().find('[data-id="add.env"]').click();
      cy.getIframeBody().find('[data-id="custom"]').click();
      cy.getIframeBody().find('[data-id="PING_ONE_BASE"]').trigger('mouseover');
      cy.getIframeBody().find('[data-id="select.btn"]').click();
      cy.getIframeBody().find('[data-id="PING_ID"]').trigger('mouseover');
      cy.getIframeBody().find('[data-id="select.btn"]').click();
      cy.getIframeBody().find('[data-id="PING_ONE_RISK"]').trigger('mouseover');
      cy.getIframeBody().find('[data-id="select.btn"]').click();
      cy.getIframeBody().find('[data-id="PING_ONE_VERIFY"]').trigger('mouseover');
      cy.getIframeBody().find('[data-id="select.btn"]').click();
      cy.getIframeBody().find('[data-id="next.btn"]').click();
      cy.getIframeBody().find('[data-id="next.btn"]').click();
      cy.getIframeBody().find('#name').type("ENV_NM");
      cy.getIframeBody().find('[data-id="sample-data-checkbox"]').click();
      cy.getIframeBody().find('#description').type(". Demo environment generated using Cypress.io.");
      cy.getIframeBody().find('#license').select('None');
      //we need to make sure the correct license is selected. Will need work to work with a P1 trial license.
      cy.getIframeBody().find('select[id=license] > option').contains('LIC_TYPE').then(element => cy.getIframeBody().find('#license').select(element.val()))
      cy.getIframeBody().find('[data-id="finish.btn"]').click();
      //get on out of here!
      cy.get('[data-id="account"]').click();
      cy.get('[data-id="signoff.link"]').click();
    })
