// Needed variables for this script
// Console URL for P1 Environment
// ENV_NM
// CONSOLE_USERNAME
// CONSOLE_PASSWORD

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

describe('Perform PingOne configured test scripts', () => {    
    it('100-pass_policy_set', () => {
      cy.visit(Cypress.env('baseUrl'));
      //login
      cy.url().then(($url) => {
        if($url.includes('signon')) {
          cy.get('#username').type(Cypress.env('CONSOLE_USERNAME'));
          cy.get('#password').type(Cypress.env('CONSOLE_PASSWORD'));
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
      cy.get('.astro-environment-selector__environment').contains(Cypress.env('ENV_NM')).click();
      //finally, let's look at some password policies!
      cy.get('[data-id="sidebar-section_experiences"]').click();
      cy.get('.nav-sidebar__node').contains('Password Policies').click();
      cy.getIframeBody().find('[data-id="policy-name-field-input"]').should('have.value','Passphrase');
    })
  })