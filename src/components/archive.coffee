_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    itemCount: @props.itemCount ? 0
    foursquareAvailable: @props.foursquareAvailable ? false
    archiveRunning: @props.archiveRunning ? false

  componentDidMount: ->
    @socket = @props.getSocket 'foursquare-archive'
    @socket.on 'data', (data) =>
      return unless @isMounted()
      console.log 'data', data
      @setState data

  startArchiving: (e) ->
    e.preventDefault()
    @socket.write
      archive: true
    @setState
      archiveRunning: true

  render: ->
    unavailable = DOM.div
      className: 'alert error'
    , 'Foursquare not available'

    count = @state.itemCount
    running = DOM.div null,
      DOM.h3 null, 'Archive Status'
      DOM.p null,
        DOM.em null, 'Archive running...'

    waiting = DOM.div null,
      DOM.h3 null, 'Start Archiving'
      DOM.button
        onClick: @startArchiving
      , 'Go!'

    available = DOM.div
      className: 'archiver-holder'
    ,
      if @state.archiveRunning then running else waiting
      DOM.p null,
        "Current archive contains #{count} item#{if count == 1 then '' else 's'}."

    DOM.section
      className: 'content'
    ,
      DOM.h2 null, 'Foursquare Archive'
      if @state.foursquareAvailable then available else unavailable
      DOM.button
        onClick: =>
          @socket.write
            getCount: true
          return
      , 'get count'
