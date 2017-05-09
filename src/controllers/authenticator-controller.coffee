class AuthenticatorController
  constructor: ({@authenticatorService}) ->
    throw new Error 'Missing authenticatorService' unless @authenticatorService?

  exchange: (request, response) =>
    { id } = request.params
    return response.sendStatus(422) unless id?
    { metadata } = request.body
    @authenticatorService.exchange { id, metadata }, (error, result) =>
      return response.sendError(error) if error?
      response.status(200).send(result)

module.exports = AuthenticatorController
