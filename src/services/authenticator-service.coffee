_                       = require 'lodash'
moment                  = require 'moment'
MeshbluHttp             = require 'meshblu-http'
{ DeviceAuthenticator } = require 'meshblu-authenticator-core'
debug                   = require('debug')('meshblu-authenticator-id:authenticator-service')
DEFAULT_PASSWORD        = 'no-need-for-this'

class AuthenticatorService
  constructor: ({ meshbluConfig }) ->
    throw new Error 'AuthenticatorService: requires meshbluConfig' unless meshbluConfig?
    @authenticatorName = 'Meshblu Authenticator ID'
    @authenticatorUuid = meshbluConfig.uuid
    throw new Error 'AuthenticatorService: requires an authenticator uuid' unless @authenticatorUuid?
    @meshbluHttp = new MeshbluHttp meshbluConfig
    @meshbluHttp.setPrivateKey(meshbluConfig.privateKey)
    @deviceModel = new DeviceAuthenticator {
      @authenticatorUuid
      @authenticatorName
      @meshbluHttp
    }

  exchange: ({ id }, callback) =>
    @_findOrCreate { id }, (error, uuid) =>
      return callback error if error?
      @_generateToken { uuid }, (error, { uuid, token }={}) =>
        return callback error if error?
        callback null, { uuid, token }

  _createError: (message='Internal Server Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _createDevice: ({ id }, callback) =>
    searchId = @_generateSearchId { id }
    query = {}
    query['meshblu.search.terms'] = { $in: [ searchId ] }
    @deviceModel.create {
      query: query
      data: { user: { id } }
      user_id: searchId
      secret: DEFAULT_PASSWORD
    }, (error, device) =>
      return callback error if error?
      callback null, _.get(device, 'uuid')

  _findDevice: ({ id }, callback) =>
    searchId = @_generateSearchId { id }
    query = {}
    query['meshblu.search.terms'] = { $in: [searchId] }
    @deviceModel.findVerified { query, password: DEFAULT_PASSWORD }, (error, device) =>
      return callback error if error?
      callback null, _.get device, 'uuid'

  _findOrCreate: ({ id }, callback) =>
    debug 'maybe create device', { id }
    @_findDevice { id }, (error, uuid) =>
      return callback error if error?
      return @_updateDevice { uuid, id }, callback if uuid?
      @_createDevice { id }, (error, uuid) =>
        return callback error if error?
        @_updateDevice { uuid, id }, callback

  _generateSearchId: ({ id }) =>
    return "authenticator:#{@authenticatorUuid}:#{id}"

  _generateToken: ({ uuid }, callback) =>
    debug 'generate token', uuid
    @meshbluHttp.generateAndStoreToken uuid, callback

  _updateDevice: ({ uuid, id }, callback) =>
    searchId = @_generateSearchId { id }
    user = {}
    user.id = id
    user.updatedAt = moment().utc().toJSON()
    user.loggedOutAt = null
    query =
      $addToSet: { 'meshblu.search.terms': searchId }
      $set: { user }
    @meshbluHttp.updateDangerously uuid, query, (error) =>
      return callback error if error?
      callback null, uuid

module.exports = AuthenticatorService
