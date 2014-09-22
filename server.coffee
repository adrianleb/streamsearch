
express = require 'express'
unirest = require('unirest')
app = express()

# BrunchServer = require './lib/server'
# {config} = require './config'

app.use(express.static __dirname+'/public')




# startServer = (port, path, callback) ->


sendPlatformRequest = (q, platform, callback) ->

  platforms = 
    youtube:
      url: (q) -> return "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{q}&key=AIzaSyCO9Dzu-D6dHTA_CRoRtuHKREpXu7U35_I"
      headers: {}

    soundcloud:
      url: (q) -> return "http://api.soundcloud.com/tracks.json?client_id=c280d0c248513cfc78d7ee05b52bf15e&q=#{q}&limit=10"
      headers: {}


  unless platform in Object.keys(platforms)
    callback {r:'sorry, no can do'}
    return false


  unirest.get(platforms[platform].url(q)).headers(platforms[platform].headers).end (r) ->
    callback r.body


# bsvr = new BrunchServer(config)
# io = require('socket.io').listen bsvr.server, logger: bsvr.logger
# io.set 'log level', 2 
# sockets = require('./express/sockets')(io)

# bsvr.on 'reload', ->
#     sockets.emit '/brunch/reload', 1000
#     sockets.destroy()
#     sockets = require('./express/sockets')(io)

# bsvr.start(port, callback)
# bsvr

# ROUTES


app.get '/', (req, res) -> res.sendfile './public/index.html'

app.get '/platforms/:platform', (req, res) -> 
  sendPlatformRequest req.query.q, req.param("platform"), (r) =>
    res.json r


app.listen 3001

