restify = require 'restify'
server = restify.createServer()
config = require './config.json'
Model = require './models'

crypto = require 'crypto'

server.use restify.bodyParser()
server.use restify.queryParser()

restify.CORS.ALLOW_HEADERS.push 'key'
restify.CORS.ALLOW_HEADERS.push 'Content-Type'

server.use restify.CORS (origins: ['*'], methods: ['GET', 'POST', 'PUT'], headers: ['Content-Type', 'key'])

server.use (req, res, next) ->
   if req.headers.key isnt config.secret
      console.log "no key"
      res.send new BadRequestError 'wrong key'
   next()

server.post '/create', (req, res, next) ->
   {email, pass, json} = req.body

   parsed_json = JSON.parse json
   hashed_pass = crypto.createHash('sha256').update(pass).digest('hex')

   if not /^[a-z0-9\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)+/i.test email
      res.send 400, "Invalid email address"

   Model.findOne (email: email), (err, account) ->
      if err
         res.send 400, err
      if !account
         new_account = new Model email: email, pass: hashed_pass, data: parsed_json
         new_account.save (err) -> if err then console.log err else res.json id: new_account._id, email: new_account.email
      else
         console.log "Account pass: #{account.pass}, Hashed pass: #{hashed_pass}"
         if account.pass is hashed_pass
            res.json id: account._id, email: account.email
         else
            res.send 409, "Account already exists with that email"

server.post '/login', (req, res, next) ->
   {email, pass} = req.body

   hashed_pass = crypto.createHash('sha256').update(pass).digest('hex')

   Model.findOne (email: email), (err, account) ->
      if err
         res.send 400, err
      if account and account.pass is hashed_pass
         res.json id: account._id, email: account.email
      else if !account
         res.send 409, "No account exists with that email address"
      else
         res.send 409, "Wrong account details"

server.get '/accounts', (req, res, next) ->
   {id} = req.params

   Model.findOne (_id: id), (err, account) ->
      if err?
         res.send 400, err
      if account?
         res.json account.data
      else
         res.send 400, "No account with that id"

server.put '/accounts', (req, res, next) ->
   {id} = req.params
   {data} = req.body

   Model.findOne (_id: id), (err, account) ->
      if err?
         res.send 400, err
      if account?
         account.data = JSON.parse data
         account.save (err) -> if err then res.send 400, err else res.send 200
      else
         res.send 400, "No account with that id"

server.listen 8000, ->
   console.log "server listening on 8000"
