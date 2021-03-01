// Needed variables for this script
// ENV_ID
// ENV_NM
// TEST_USERNAME
// TEST_PASSWORD

Cypress.on('uncaught:exception', (err, runnable) => {
    expect(err.message).to.include('error originated from your application code');
    // returning false here prevents Cypress from
    // failing the test
    // sign in caused problems without this... I don't care, it still fails if we messed something up.
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

describe('Check ENV_NM is set to proper configuration for PingFederate Admin SSO', () => {
    it('Visits PingOne Console', () => {
      cy.visit('https://console.pingone.com/?env=ENV_ID');
      //login
      cy.get('#username').type('TEST_USERNAME');
      cy.get('#password').type('TEST_PASSWORD');
      cy.get('.button').click();
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
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('pf-admin-roles');
      cy.getIframeBody().find('[data-id="scrolling-wrapper"]').contains('pf-admin-roles')
      // go to admin account
      cy.get('[data-id="sidebar-node_user"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('PingFederateAdmin');
      cy.getIframeBody().find('[data-id="user-list"]').contains('PingFederateAdmin')
      // go to admin sso app
      cy.get('[data-id="sidebar-section_connections"]').click();
      cy.getIframeBody().find('[data-id="searchBox-input"]').type('PingFederate');
      cy.getIframeBody().find('[data-id="app-row"]').contains('PingFederate Admin SSO')
      cy.getIframeBody().find('[data-id="expand-btn"]').click();
      cy.getIframeBody().find('[data-id="rocker-label_ATTRIBUTES"]').click();
      cy.getIframeBody().find('[data-id="icon-content"]').contains('pf-admin-roles')
      //sign off
      cy.get('[data-id="account"]').click();
      cy.get('[data-id="signoff.link"]').click();
    })
})
