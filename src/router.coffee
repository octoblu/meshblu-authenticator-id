AuthenticatorController = require './controllers/authenticator-controller'

class Router
  constructor: ({ @authenticatorService }) ->
    throw new Error 'Missing authenticatorService' unless @authenticatorService?

  route: (app) =>
    autheticatorController = new AuthenticatorController { @authenticatorService }

    app.post '/exchange/:id', autheticatorController.exchange

module.exports = Router
