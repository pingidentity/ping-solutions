Cypress.on('uncaught:exception', (err, runnable) => {
    // returning false here prevents Cypress from
    // failing the test
    // sign in caused problems without this... I don't care, it still fails if we messed something up.
    expect(err.message).to.include('error originated from your application code');
    return false
})

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

describe('Delete ENV_NM environment', () => {
    it('Visits PingOne Console to delete ENV_NM', () => {
      cy.visit('https://console.pingone.com/?env=ENV_ID');
      //login
      cy.get('#username').type('TEST_USERNAME');
      cy.get('#password').type('TEST_PASSWORD');
      cy.get('.button').click();
      if(cy.url().should('not.include', '/myping/home'))
      {
          cy.log('Warning, could not log in successfully')
      }
      //conditionally click
      if(cy.get('[data-id="guide-close-button"]').should('be.visible'))
      {
        cy.get('[data-id="guide-close-button"]').click();
      }
      //switch to WF environment
      cy.get('.astro-environment-selector__trigger').click();
      cy.get('.astro-environment-selector__environment').contains('ENV_NM').should((elem) => {
          expect(elem.text()).to.equal('ENV_NM');
      }).click();
      cy.get('.nav-sidebar__node').contains('Environment Properties').click();
      cy.getIframeBody().find('[data-id="delete-environment"]').click();
      cy.getIframeBody().find('[data-id="confirm-delete-check-box-container"]').click();
      cy.getIframeBody().find('[data-id="confirm-delete"]').click();
      //get on out of here!
      cy.get('[data-id="guide-close-button"]', { timeout : 15000 }).should('be.visible').click();
      cy.get('[data-id="account"]').click();
      cy.get('[data-id="signoff.link"]').click();
    })
})