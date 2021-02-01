// jshint esversion: 6
Cypress.Commands.add('pickCategory', function(option) {
    cy.get('#form_category_fieldset label').contains(option).click();
});
Cypress.Commands.add('pickSubcategory', function(option, selector) {
    cy.get(selector).select(option);
});
