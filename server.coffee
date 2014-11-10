
express = require 'express'
unirest = require('unirest')
path = require('path')
app = express()



app.use(express.static __dirname+'/public')

platforms =

  itunes:
    url:(q) -> return "https://itunes.apple.com/search?term=#{q.split(' ').join('+')}&entity=song" 
    headers: {}

    parser: (request) ->
      request = JSON.parse(request)
      res = []
      if request.results?.length 
        for item in request.results 
          obj = {
            img: item.artworkUrl100
            title: item.artistName + " - " + item.trackName
            id: item.trackId
            url: item.radioStationUrl
            source: "itunes"
          }
          res.push obj
      return res

  youtube:
    url: (q) -> return "https://www.googleapis.com/youtube/v3/search?part=snippet&q=#{q}&key=#{process.env['YT_KEY']}"
    headers: {}
    parser: (request) ->
      res = []
      if request.items?.length
        for item in request.items 
          console.log item
          console.log ""
          console.log ""
          console.log ""
          console.log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


          obj = {
            img: item.snippet.thumbnails?.high?.url or ""
            title: item.snippet.title
            id: item.id.videoId
            url: "http://youtube.com/watch?v=#{item.id.videoId}"
            source: "youtube"
          }
          res.push obj
      return res



  spotify:
    url: (q) -> return "https://api.spotify.com/v1/search?q=#{q}&type=track"
    headers: {}
    parser: (request) ->
      res = []
      if request.tracks?.items?.length
        for item in request.tracks.items
          if item?
            title = if item.artists?[0]? then "#{item.artists[0].name} - " else ""
            title += item.name
            obj = {
              title: title
              id: item.id  
              img: item.album.images[0].url
              url: item.external_urls.spotify
              source: "spotify"
            }
            res.push obj
      return res


  soundcloud:
    url: (q) -> return "http://api.soundcloud.com/tracks.json?client_id=#{process.env['SC_KEY']}&q=#{q}&limit=10"
    headers: {}
    parser: (request) ->

      imageSrc = (item) ->
        avatar = "http://placekitten.com/700/700"
        if item.artwork_url? 
              avatar = item.artwork_url.replace('large', 't500x500').split('?')[0] 
        else 
          unless item.user?.avatar_url.indexOf('default_avatar') > -1
            avatar = item.user?.avatar_url.replace('large', 't500x500').split('?')[0] 
        return avatar

      res = []

      if request?.length 
        for item in request

          title = item.title
          unless (title.indexOf(" - ") > 0 )
            title = item.user.username + " - " + item.title

          obj = {
            img: imageSrc(item)
            id: item.id
            title: title
            url: item.permalink_url
            source: "soundcloud"
          }
          res.push obj
      return res


  vimeo:
    url: (q) -> return "https://api.vimeo.com/videos?query=#{q}&per_page=10"
    headers: {
      'Authorization' : "#{process.env["VIMEO_AUTH"]}"
      'Accept': 'application/vnd.vimeo.*+json;version=3.0'
    }
    parser: (request) ->
      request = JSON.parse(request)
      # console.log request
      res = []
      if request?.data?.length 
        for item in request.data

            obj = {
              img: item.pictures[0].link
              id: item.uri
              nsfw: 'nudity' in item.content_rating 
              title: item.name
              url: item.link
              source: "vimeo"
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


app.listen process.env.PORT || 3001

