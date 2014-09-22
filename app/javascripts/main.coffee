nop = (e) ->
  e.preventDefault()
  return true


class Fetcher

  constructor: (arg) ->
    @parent = arg.parent
    @platforms = ['soundcloud', 'youtube', 'spotify']

  fetch: (q) ->
    for platform in @platforms
      $.ajax
        url: "/platforms/#{platform}?q=#{q}"
        success: (r) =>     
          nextItems = @parent.state.items.concat r
          @applyComparator nextItems
          @parent.setState items: nextItems

  applyComparator: (items) ->
    text = @parent.state.text.toLowerCase()

    rankRules =
      "exactMatch": 
        weight: 1000
        func: (item) => 
          val = if item is text then 1 else 0
          return val

      "textInTitle":
        weight: 10
        func: (item) => 
          # console.log item, text, item.indexOf(text), text.length - text.indexOf(item)
          val = if item.indexOf(text) is -1 then 0 else (item.length - item.indexOf(text))
          return val

    # console.log items
    for item, i in items
      item.score = 0

      for k, v of rankRules
        # console.log item
        console.log k + ": #{v.func(item.title.toLowerCase()) * v.weight}"
        item.score += (v.func(item.title.toLowerCase()) * v.weight)
        
    #   # console.log item.score, i


    items = _.sortBy items, (item) =>
      return item.score

    # # console.log "bundle over:", items, "\n\n\n\n\n\n\n\n\n\n\n\n\n"

    return items






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
          (h3 {className:"header-subtitle"}, 'Search simultaneously across multiple streaming platforms for the track you want to listen to right now.'),
          (form {onSubmit: @handleSubmit, className: 'header-form'}, [
            input onKeyUp: @onKey,
            button {}, 'Search'])
        ]),
        (div {className: "content"},
          SearchResults items: @state.items, searchCharCount: @state.searchCharCount
        )]

      

  React.renderComponent (MusicSearch {}), $('#main')[0]   
