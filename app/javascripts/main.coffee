nop = (e) ->
  e.preventDefault()
  return true


class Fetcher

  constructor: (arg) ->
    @parent = arg.parent
    @platforms = ['soundcloud', 'youtube', 'spotify', 'vimeo']

  fetch: (q) ->
    @totalPendingRequests = @platforms.length
    @parent.setState status:'loading'


    for platform, i in @platforms
      $.ajax
        url: "/platforms/#{platform}?q=#{encodeURIComponent(q)}"
        success: (r) =>     
          r.id = parseFloat(""+i+r.id)
          nextItems = @parent.state.items.concat r
          nextItems = @applyComparator(nextItems)

          @parent.setState items: nextItems

          @totalPendingRequests -= 1

          if @totalPendingRequests is 0
            @parent.setState status:'finished'
        error: (e, r) =>
          @totalPendingRequests -= 1
          @parent.setState status: 'error'

            



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
          val = if item == text then 1 else 0
          return val

      "textInTitle":
        weight: 10
        func: (item) => 
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
            val += item.indexOf(split)

          return val


    for item, i in items
      item.score = 0

      for k, v of rankRules
        item.score += (v.func(item.title.toLowerCase()) * v.weight)
        


    items = _.sortBy items, (item) =>
      return -item.score

    # console.log items

    return items






$ ->
  {ul, li, div, h3, h1, a, p, span, form, label, img, input, button} = React.DOM

  Route = ReactRouter.Route
  Routes = ReactRouter.Routes
  Link = ReactRouter.Link



        

  SearchResults = React.createClass


    onCardClick: (e) ->
      console.log e.target.getAttribute('data-href')

    onAnchorClick: (e) ->
      console.log 'clicked anchor aye?'
      el = $(e.currentTarget).parents('.search-result')
      ga('send', 'event', 'opened', el.attr('data-source'), el.attr('data-title'))




    renderItem: (item, i) ->
      if @props.filtersObj[item.source]
        image = item.img
        if item.nsfw
          image = "/nsfw.png"
        (div {key:item.id, className: "search-result", "data-visible":@props.filtersObj[item.source], "data-source":item.source, "data-title":item.title, onClick:@onCardClick},[
          (div {className:'result-image', style: backgroundImage:"url(#{item.img})"}),
          (span {className:'source'}, [(a {href:item.url, target:"_blank", onClick:@onAnchorClick},[item.source])]),
          (div {className:"result-container"}, [
            (img {src:image}),
            (h3 {}, [
              (a {href:item.url, target:"_blank", onClick:@onAnchorClick},[item.title])
            ])
          ])
        ])

    render: ->
      div {},
        ul {className:"search-results"}, [@props.items.map @renderItem]

  MusicSearch = React.createClass

    mixins: [ ReactRouter.Navigation ]

    getInitialState: ->
      results: []
      items: []
      filtersObj:
        'spotify':true
        'youtube':true
        'soundcloud':true
        'vimeo':true

      text: ""
      searchCharCount: 0
      status: "idle"
      isSearching: false


    onChange: (e) ->
      name = e.target.parentNode.firstChild.textContent
      state = @state.filtersObj
      if name is 'all'
        for k, v of state
          state[k] = true
      else
        state[name] = e.target.checked
      @setState filtersObj: state



    onKey: (e) ->
      @setState text: e.target.value



    handleSubmit: (e) ->
      nop e
      text = e.currentTarget.childNodes[0].value
      @sendSearchSignal text, true


    sendSearchSignal: (q, navigate)->
      unless q.length is 0
        @setState 
          items: []
          isSearching: true
          text: q
          searchCharCount: q.length

        @fetcher.fetch(q) 
        if navigate
          ga('send', 'event', 'search', 'submitted', q)
          @transitionTo("/", null, {q:q})
        else
          ga('send', 'event', 'search', 'landed', q)




    componentWillMount: (e) ->
      @fetcher = new Fetcher(parent:@)

    componentDidMount: ->
      if @props.query.q
        @sendSearchSignal @props.query.q, false


      $(window).on 'popstate pushstate', (e) =>
        unless @props.query.q is @state.text
          @sendSearchSignal @props.query.q, false
          



    render: ->
      inputs = []
      renderAll = false
      statusMsg = ""
      if @state.status is 'error'
        statusMsg = "There was an error with your query, try again."
      else if @state.status is "loading"
        statusMsg = "Waiting for #{@fetcher.totalPendingRequests} sources..."
      else if @state.status is "finished"
        statusMsg = "Done!"

      for k, v of @state.filtersObj
        inputs.push (label {key:k ,className:"filter #{if v then 'checked' else ''}"},[
          (span {}, k),
          input {onChange: @onChange, type:"checkbox", checked:v }])
        if not v
          renderAll = true

      if renderAll
        inputs.push (label {key:'all' ,className: "filter"},[
            (span {}, 'all'),
            input {onChange: @onChange, type:"checkbox", checked:false }])

      div {}, [
        (div {className: "header #{if @state.isSearching then "small" else "" }"}, [
          (h1 {className:"header-title"}, 'Stream Sweep'),
          (h3 {className:"header-subtitle"}, 'Search simultaneously across multiple streaming platforms for the track you want to listen to right now.'),
          (form {onSubmit: @handleSubmit, className: 'header-form'}, [
            input {value:@state.text, placeholder: "track title", onChange:@onKey},
            button {}, 'Search']),
          (ul {className:"search-filters"}, inputs),
          (p {className:"status #{@state.status}"}, [statusMsg])

        ]),
        (div {className: "content"},
          SearchResults items: @state.items, searchCharCount: @state.searchCharCount, filtersObj:@state.filtersObj
        )]

      

      
  # routes 
  window.routes = 
    Routes({location:'history'}, 
      (Route {name: "app", path: "/*", handler:MusicSearch}),
    )
  

  React.renderComponent (window.routes), $('#main')[0]   
