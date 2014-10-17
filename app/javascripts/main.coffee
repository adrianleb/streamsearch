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
          nextItems = @applyComparator(nextItems)

          @parent.setState items: nextItems


  applyComparator: (items) ->
    text = @parent.state.text.toLowerCase()

    rankRules =
      "shortTitle": 
        weight: -100
        func: (item) =>
          val = 0
          diff = item.length - text.length
          if diff > 0
            val += diff
          return val

      "exactMatch": 
        weight: 10000
        func: (item) => 
          # console.log item, text, item == text
          val = if item == text then 1 else 0
          return val

      "textInTitle":
        weight: 10
        func: (item) => 
          # console.log item, text, item.indexOf(text), text.length - text.indexOf(item)
          val = if item.indexOf(text) is -1 then 0 else (item.length - item.indexOf(text))
          return val
      "textInAfterDash":
        weight: 10
        func: (item) => 
          split = item.split(' - ')
          val = 0
          if split[1]?
            val = if item.indexOf(split[1]) is -1 then 0 else (split[1].length - split[1].indexOf(text))
          return val
      "textInBeforeDash":
        weight: 10
        func: (item) => 
          split = item.split(' - ')
          val = 0
          if split[0]?
            val = if item.indexOf(split[0]) is -1 then 0 else (split[0].length - split[0].indexOf(text))
          return val
      "fuzzyish":
        weight: 10
        func: (item) =>
          val = 0
          for split in text.split(' ')
            # console.log item, split, item.indexOf(split)
            val += item.indexOf(split)
          # console.log val, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

          return val


    # console.log items
    for item, i in items
      item.score = 0

      for k, v of rankRules
        # console.log item
        # console.log k + ": #{v.func(item.title.toLowerCase()) * v.weight}"
        item.score += (v.func(item.title.toLowerCase()) * v.weight)
        
      # console.log item.score, i


    items = _.sortBy items, (item) =>
      return -item.score

    console.log items
    # # console.log "bundle over:", items, "\n\n\n\n\n\n\n\n\n\n\n\n\n"

    return items






$ ->
  {ul, li, div, h3, h1, a, span, form, img, input, button} = React.DOM


  SearchResults = React.createClass

    renderItem: (item) ->
      (a {className: 'search-result', href:item.url, target:"_blank"},[
        (div {className:'result-image', style: backgroundImage:"url(#{item.img})"}),
        (span {className:'source'}, [item.source]),
        (div {className:"result-container"}, [
          (img {src:item.img}),
          (h3 {}, [item.title])
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
      isSearching: false

    onKey: (e) ->
      @setState searchCharCount: e.target.value.length
      @setState text: e.target.value


    handleSubmit: (e) ->
      nop e
      @setState items: []
      @setState isSearching: true
      @fetcher.fetch(this.state.text)

    componentWillMount: (e) ->
      @fetcher = new Fetcher(parent:@)

    render: ->
      div {}, [
        (div {className: "header #{if @state.isSearching then "small" else ""}"}, [
          (h1 {className:"header-title"}, 'Stream Sweep'),
          (h3 {className:"header-subtitle"}, 'Search simultaneously across multiple streaming platforms for the track you want to listen to right now.'),
          (form {onSubmit: @handleSubmit, className: 'header-form'}, [
            input onKeyUp: @onKey,
            button {}, 'Search'])
        ]),
        (div {className: "content"},
          SearchResults items: @state.items, searchCharCount: @state.searchCharCount
        )]

      

  React.renderComponent (MusicSearch {}), $('#main')[0]   
