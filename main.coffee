restify = require 'restify'
server = restify.createServer()
config = require './config.json'
Model = require './models'
chalk = require 'chalk'
prettyjson = require 'prettyjson'

crypto = require 'crypto'

server.use restify.bodyParser()
server.use restify.queryParser()

restify.CORS.ALLOW_HEADERS.push 'key'
restify.CORS.ALLOW_HEADERS.push 'Content-Type'

server.use restify.CORS (origins: ['*'], methods: ['GET', 'POST', 'PUT'], headers: ['Content-Type', 'key'])

server.use (req, res, next) ->
   if req.headers.key isnt config.secret
      console.log chalk.red "No key is available!"
      res.send new BadRequestError 'wrong key'
   next()

server.post '/create', (req, res, next) ->
   {email, pass, json} = req.body

   parsed_json = JSON.parse json
   hashed_pass = crypto.createHash('sha256').update(pass).digest('hex')

   console.log "#{chalk.blue '[POST]'} request for creating a new account\n#{prettyjson.render (email: email, pass: hashed_pass)}"

   if not /^[a-z0-9\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)+/i.test email
      res.send 400, "Invalid email address"

   Model.findOne (email: email), (err, account) ->
      if err
         res.send 400, err
      if !account
         new_account = new Model email: email, pass: hashed_pass, data: parsed_json
         console.log "#{chalk.green 'ACCOUNT CREATED!'}\n#{prettyjson.render (email:email, password: hashed_pass)}\n"
         new_account.save (err) -> if err then console.log err else res.json id: new_account._id, email: new_account.email
      else
         console.log "#{chalk.blue 'ACCOUNT FOUND!'}\n#{prettyjson.render (AccountPassword: account.pass, HashedPassword: hashed_pass)}\n"
         if account.pass is hashed_pass
            res.json id: account._id, email: account.email
         else
            console.log "#{chalk.red 'ACCOUNT ALREADY EXISTS'} an account already exists with this email"
            res.send 409, "Account already exists with that email"

server.post '/login', (req, res, next) ->
   {email, pass} = req.body

   hashed_pass = crypto.createHash('sha256').update(pass).digest('hex')

   console.log "#{chalk.blue '[POST]'} request for logging in\n#{prettyjson.render (email: email, pass: hashed_pass)}\n"

   Model.findOne (email: email), (err, account) ->
      if err
         res.send 400, err
      if account and account.pass is hashed_pass
         console.log "#{chalk.green 'ACCOUNT FOUND!'} returning ID: #{account._id}\n"
         res.json id: account._id, email: account.email
      else if !account
         console.log "#{chalk.red 'ACCOUNT NOT FOUND!'} No account exists with the email address that was given\n"
         res.send 409, "No account exists with that email address"
      else
         console.log "#{chalk.red 'WRONG ACCOUNT DETAILS'}\n#{prettyjson.render (AccountPass: account.pass, HashedPass: hashed_pass)}\n"
         res.send 409, "Wrong account details"

server.get '/accounts', (req, res, next) ->
   {id} = req.params

   console.log "#{chalk.blue '[GET]'} ID: #{id}"

   Model.findOne (_id: id), (err, account) ->
      if err?
         res.send 400, err
      if account?
         console.log "#{chalk.green 'ACCOUNT FOUND!'}\n#{prettyjson.render (id: id)}\n\nSpitting out data\n\n#{prettyjson.render account.data}\n"
         res.json account.data
      else
         res.send 400, "No account with that id"

server.put '/accounts', (req, res, next) ->
   {id} = req.params
   {data} = req.body

   console.log "#{chalk.blue '[PUT]'} request for saving\n#{prettyjson.render (id: id)}\n\n#{prettyjson.render (NewData: JSON.parse data)}\n"

   Model.findOne (_id: id), (err, account) ->
      if err?
         res.send 400, err
      if account?
         account.data = JSON.parse data
         console.log "#{chalk.green 'ACCOUNT FOUND!'} ID: #{id}\n\n#{prettyjson.render JSON.parse data}\n"
         account.save (err) -> if err then res.send 400, err else res.send 200
      else
         res.send 400, "No account with that id"

server.listen 8000, ->
   console.log "#{chalk.cyan 'server listening on 8000'}"
