nop = (e) ->
  e.preventDefault()
  return true


class Fetcher

  constructor: (arg) ->
    @parent = arg.parent
    @platforms = ['soundcloud']

  fetch: (q) ->
    for platform in @platforms
      $.ajax
        url: "/platforms/#{platform}?q=#{q}"
        success: (r) =>     
          console.log r 
          #           obj = {
          #   title: r.snippet.title
          #   img: r.snippet.thumbnails?.high?.url or ""
          #   source: "youtube"
          #   url: "http://youtube.com/watch?v=#{r.id.videoId}"
          # }
          # nextItems = @parent.state.items.concat [obj]
          # @parent.setState items: nextItems




$ ->
  {ul, li, div, h3, h1, a, span, form, input, button} = React.DOM


  SearchResults = React.createClass

    renderItem: (item) ->
      (li {className: 'search-result'},[
        (a {className:"result-container", href:item.url, target:"_blank"}, [
          (div {className:'result-image', style: backgroundImage:"url(#{item.img})"}),
          (h3 {}, [item.title]),
          span {className:'source'}, [item.source]
        ])
      ])

    render: ->
      div {},
        ul {className:"search-results"}, [@props.items.map @renderItem]

  MusicSearch = React.createClass

    getInitialState: ->
      results: []
      items: []
      text: ''
      searchCharCount: 0

    onKey: (e) ->
      @setState searchCharCount: e.target.value.length
      @setState text: e.target.value

    handleSubmit: (e) ->
      nop e
      @setState items: []
      @fetcher.fetch(this.state.text)

    componentWillMount: (e) ->
      @fetcher = new Fetcher(parent:@)

    render: ->
      div {}, [
        (div {className: 'header'}, [
          (h1 {className:"header-title"}, 'streamsear.ch'),
          (h3 {className:"header-subtitle"}, 'Search simultaneously across multiple platforms for the track you want to listen to right now on.'),
          (form {onSubmit: @handleSubmit, className: 'header-form'}, [
            input onKeyUp: @onKey,
            button {}, 'Search'])
        ]),
        (div {className: "content"},
          SearchResults items: @state.items, searchCharCount: @state.searchCharCount
        )]

      

  React.renderComponent (MusicSearch {}), $('#main')[0]   
