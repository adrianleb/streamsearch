
express = require 'express'
unirest = require('unirest')
path = require('path')
app = express()



app.use(express.static __dirname+'/public')

platforms = 
  youtube:
    url: (q) -> return "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{q}&key=AIzaSyAblW50IPEIhbEqcAkgXwYeRR_3rYDDIms"
    headers: {}
    parser: (request) ->
      # console.log request, request.error?.errors?
      res = []
      if request.items? for item in request.items 
        obj = {
          img: item.snippet.thumbnails?.high?.url or ""
          title: item.snippet.title
          url: "http://youtube.com/watch?v=#{item.id.videoId}"
          source: "youtube"
        }
        console.log obj
        res.push obj
      return res


  spotify:
    url: (q) -> return "https://api.spotify.com/v1/search?q=#{q}&type=track"
    headers: {}
    parser: (request) ->
      console.log request
      res = []
        
      for item in request.tracks?.items
        title = if item.artists?[0]? then "#{item.artists[0].name} - " else ""
        title += item.name
        obj = {
          title: title
          img: item.album.images[0].url
          url: item.external_urls.spotify
          source: "spotify"
        }
        res.push obj
        console.log item
      return res


  soundcloud:
    url: (q) -> return "http://api.soundcloud.com/tracks.json?client_id=c280d0c248513cfc78d7ee05b52bf15e&q=#{q}&limit=10"
    headers: {}
    parser: (request) ->
      res = []
      if request.length 
        for item in request
          obj = {
            img: if item.artwork_url? then item.artwork_url.replace('large', 't500x500').split('?')[0] else item.user?.avatar_url.replace('large', 't500x500').split('?')[0]
            title: item.user.username + " - " + item.title
            url: item.permalink_url
            source: "soundcloud"
          }
          res.push obj
      return res




sendPlatformRequest = (q, platform, callback) ->
  unless platform in Object.keys(platforms)
    callback {r:'sorry, no can do'}
    return false

  unirest.get(platforms[platform].url(q)).headers(platforms[platform].headers).end (r) ->
    callback platforms[platform].parser(r.body)


# ROUTES


app.get '/', (req, res) -> res.sendFile path.join(__dirname, '/public', 'index.html')

app.get '/platforms/:platform', (req, res) -> 
  sendPlatformRequest req.query.q, req.param("platform"), (r) =>
    res.json r


app.listen 3001

