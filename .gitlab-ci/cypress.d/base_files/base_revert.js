// Needed variables for this script
// ENV_ID
// ENV_NM
// TEST_USERNAME
// TEST_PASSWORD

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

describe('Perform PingOne reverted test scripts', () => {

