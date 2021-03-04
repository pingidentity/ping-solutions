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


describe('Create worker app', () => {
    it('Visits ENV_NM PingOne Console and creates worker app', () => {
        cy.visit('https://console.pingone.com/?env=ENV_ID');
        //hide the new user guides, I don't wanna figure out clicking it.
        window.localStorage.setItem('ping-hideCompassGuide-ENV_ID','true')
        window.localStorage.setItem('ping-hideCompassGuide-MyPing-ENV_ID','true')
        window.localStorage.setItem('ping-hideCompassGuide-NavGuide-ENV_ID','true')
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
        //select new environment
        cy.get('.nav-sidebar__top-container').click();
        cy.get('.astro-environment-selector__trigger').click();
        cy.get('.astro-environment-selector__environment').contains('ENV_NM').should((elem) => {
            expect(elem.text()).to.equal('ENV_NM');
        }).click();
        cy.get('[data-id="sidebar-section_connections"]').click();
        cy.get('[data-id="sidebar-node_applications"]').click();
        cy.getIframeBody().find('[data-id="add-app-button"]').click();
        cy.getIframeBody().find('[data-id="app-type-selector-button-WORKER"]').click();
        cy.getIframeBody().find('[data-id="WORKER-protocol-panel-OPENID_CONNECT-button"]').click();
        cy.getIframeBody().find('[data-id="app-name-input"]').type("app_runner_worker");
        cy.getIframeBody().find('[data-id="worker-oidc-wizard-step-1-buttonbar-save"]').click();
        cy.getIframeBody().find('[data-id="worker-oidc-wizard-step-2-buttonbar-save"]').click();
        cy.getIframeBody().find('[data-id="enablement-toggle"]').first().click();
        cy.getIframeBody().find('[data-id="rocker-label_CONFIGURATION"]').click();
        cy.getIframeBody().find('[data-id="reveal"]').click();
        cy.getIframeBody().find("[data-id$=client-id]")
            .then($value => {
                const clientID = $value.text()
                cy.writeFile('/e2e/PROD_NM_client_id.txt', clientID)
            })
        cy.getIframeBody().find('[class=masked-value__value]')
            .then($value => {
                const clientID = $value.text()
                cy.writeFile('/e2e/PROD_NM_client_secret.txt', clientID)
            })
        cy.get('[data-id="sidebar-section_dashboard"]').click();
        cy.get('[data-id="sidebar-node_environment.properties"]').click();
        cy.getIframeBody().find('[data-id="environment-id-value"]')
            .then($value => {
                const envID = $value.text()
                cy.writeFile('/e2e/PROD_NM_envid.txt', envID)
            })
        //get on out of here!
        cy.get('[data-id="account"]').click();
        cy.get('[data-id="signoff.link"]').click();
    })
})