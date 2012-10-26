#
# Used by everyone to manipulate chrome.storage
# Legacy settings from localStorage are propagated into chrome.storage
#

root = exports ? window
root.Settings = Settings =

  storage:
    chrome.storage.sync

  storageOperationOK: (msg) ->
    console.log "chrome.storage.sync error: #{msg} #{chrome.storage.sync.message}" if chrome.runtime.lastError
    not chrome.runtime.lastError
  
  get: (key, callback) ->
    @storage.get key,
      (items) ->
        if Settings.storageOperationOK "get #{key}"
          # yikes! what do we do now?
          callback Settings.defaults[key]
          return

        # where might we get a value from?
        #   1st choice, the value passed from @storage
        #   2nd choice, a legacy value from localStorage
        #   3rd choice, the default value
        callback(
          if items and key of items
            # we have a value from chrome.storage
            if key of localStorage
              # we also have a legacy value in localStorage, choose the value
              # from chrome.storage and delete the key/value in localStorage
              delete localStorage[k] 
            items[key]
          else
            if key of localStorage
              value = JSON.parse localStorage[key]
              # propagate legacy setting to chrome storage and delete it
              Settings.set key, value,
                (k,v) ->
                  if k of localStorage
                    delete localStorage[k] 
              # yield legacy value
              value
            else
              Settings.defaults[key] ) if callback

  # set key to value, or clear key if value is equal to the default (thereby allowing defaults to be changed in future)
  # call callback(key,value) -- optional -- but only there are no errors
  set: (key, value, callback) ->
    # BUG: the following is ALWAYS false for keys with numeric default values (such as scrollStepSize)
    if value == @defaults[key]
      @clear key, callback
    else
      item = {}
      item[key] = value
      @storage.set item,
        ->
          if Settings.storageOperationOK "set #{key}" and callback
            callback key, value

  clear: (key, callback) ->
    @storage.clear key,
      ->
        if Settings.storageOperationOK "clear #{key}" and callback
          callback key, Settings.defaults[key]

  # @has() doesn't make much sense with this asynchronous interface
  # here, @has calls callback with a boolean (if the caller wanted the value, they would have used get!)
  has: (key, callback) ->
    if callback
      @get key,
        (value) ->
          callback( value != Settings.defaults[key] )
  
  defaults:
    scrollStepSize: 60
    linkHintCharacters: "sadfjklewcmpgh"
    filterLinkHints: false
    hideHud: false
    userDefinedLinkHintCss:
      """
      div > .vimiumHintMarker {
      /* linkhint boxes */
      background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#FFF785),
        color-stop(100%,#FFC542));
      border: 1px solid #E3BE23;
      }

      div > .vimiumHintMarker span {
      /* linkhint text */
      color: black;
      font-weight: bold;
      font-size: 12px;
      }

      div > .vimiumHintMarker > .matchingCharacter {
      }
      """
    excludedUrls:
      """
      http*://mail.google.com/*
      http*://www.google.com/reader/*
      """
    # NOTE : If a page contains both a single angle-bracket link and a double angle-bracket link, then in
    # most cases the single bracket link will be "prev/next page" and the double bracket link will be
    # "first/last page", so we put the single bracket first in the pattern string so that it gets searched
    # for first.

    # "\bprev\b,\bprevious\b,\bback\b,<,←,«,≪,<<"
    previousPatterns: "prev,previous,back,<,\u2190,\xab,\u226a,<<"
    # "\bnext\b,\bmore\b,>,→,»,≫,>>"
    nextPatterns: "next,more,>,\u2192,\xbb,\u226b,>>"
    # default/fall back search engine
    searchUrl: "http://www.google.com/search?q="

# Initialization code.
# We use this parameter to coordinate any necessary schema changes.
Settings.set("settingsVersion", Utils.getCurrentVersion())
