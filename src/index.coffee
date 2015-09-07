_ = require 'lodash'

module.exports = (System) ->
  ActivityItem = System.getModel 'ActivityItem'
  getUser = System.getMethod 'kerplunk-foursquare', 'getUser'
  getMyCheckins = System.getMethod 'kerplunk-foursquare', 'getMyCheckins'

  archiveRunning = false

  archiveSocket = null
  itemCount = 0

  getCount = (next) ->
    me = System.getMe()
    return next null, 0 unless me?._id
    ActivityItem.find
      identity: me._id
      platform: 'foursquare'
    .count (err, _count) ->
      count = 0
      count = _count if _count > count
      itemCount = _count if _count > 0
      #console.log 'getCount', err, _count, count
      next err, count

  reportTimeout = null
  lastCountReported = 0
  reportCount = (force = false) ->
    clearTimeout reportTimeout

    refreshIn = (time) ->
      reportTimeout = setTimeout ->
        if archiveRunning or force == true
          reportCount()
      , time

    userPromise = getUser()
    getCount (err, count) ->
      if lastCountReported == count
        return refreshIn 1000
      lastCountReported = count
      if err
        console.log 'archiver error', err
        archiveSocket.broadcast error: err
        return
      userPromise
      .then (user) ->
        archiveSocket.broadcast
          foursquareAvailable: !!user
          archiveRunning: archiveRunning
          itemCount: itemCount
        refreshIn 200

  startArchive = ->
    return if archiveRunning
    return console.log 'could not get getMyCheckins' unless getMyCheckins

    setArchiveStatus true
    reportCount()

    getAllMyCheckins = ->
      limit = 100
      offset = 0
      order = 'desc'
      total = 0
      tryAgain = ->
        getMyCheckins
          limiit: limit
          offset: offset
          order: order
        .then (items) ->
          total += items.length
          offset += limit
          if items.length > 1
            tryAgain()
          else
            total
      tryAgain()

    getAllMyCheckins()
    .then (total) ->
      setArchiveStatus false
    .catch (err) ->
      archiveSocket.broadcast error: err

  setArchiveStatus = (status) ->
    archiveRunning = status
    reportCount true
    archiveSocket.broadcast
      archiveRunning: archiveRunning
      itemCount: itemCount

  showArchive = (req, res, next) ->
    userPromise = getUser()

    getCount (err, count) ->
      console.error err?.stack ? err if err
      #console.log count
      userPromise
      .then (user) ->
        opt =
          foursquareAvailable: !!user
          archiveRunning: archiveRunning
          itemCount: count
        res.render 'archive', opt

  start = (req, res, next) ->
    userPromise = getUser()

    userPromise
    .then (user) ->
      startArchive()
      if req.params.format == 'json'
        res.send
          foursquareAvailable: !!user
          archiveRunning: archiveRunning
          itemCount: itemCount
      else
        res.send 'go!'

  routes:
    admin:
      '/admin/foursquare/archive': 'showArchive'
      '/admin/foursquare/archive/start': 'start'

  handlers:
    showArchive: showArchive
    start: start

  globals:
    public:
      nav:
        Admin:
          'Social Networks':
            Foursquare:
              Archive: '/admin/foursquare/archive'

  init: (next) ->
    archiveSocket = System.getSocket 'foursquare-archive'
    archiveSocket.on 'receive', (spark, data) ->
      if data?.archive
        console.log 'startArchive!'
        startArchive()
      else if data?.getCount
        console.log 'getCount!'
        reportCount()
      else
        console.log 'client said what?', data
    archiveSocket.on 'connection', (spark, data) ->
      console.log 'foursquare-archive connection'
      setArchiveStatus archiveRunning
      #throttledEmitter()

    next()
