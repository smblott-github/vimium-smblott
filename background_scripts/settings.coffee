#
# Used by everyone to manipulate localStorage.
#

root = exports ? window
root.Settings = Settings =
# get: (key) ->
#   if (key of localStorage) then JSON.parse(localStorage[key]) else @defaults[key]

# set: (key, value) ->
#   # don't store the value if it is equal to the default, so we can change the defaults in the future
#   if (value == @defaults[key])
#     @clear(key)
#   else
#     localStorage[key] = JSON.stringify(value)

# clear: (key) -> delete localStorage[key]

# has: (key) -> key of localStorage

  storage:
    chrome.storage.sync

  storage_error: (msg) ->
    if chrome.runtime.lastError
      console.log "chrome.storage.sync error: #{msg} #{chrome.storage.sync.message}"
      false
    else
      true
  
  get: (key, callback) ->
    @storage.get key,
      (items) ->
        if Settings.storage_error "get #{key}" # yikes! what do we do here?
          callback Settings.defaults[key]
          return

        callback ( if key of items                      # 1st choice, a value from synced storage
                     items[key]
                   else
                     if key of localStorage             # 2nd choice, a legacy value from localStorage
                       v = JSON.parse localStorage[key]
                       # propagate legacy setting to synced storage
                       Settings.set key, v,
                         (k,v) ->
                           if k of localStorage
                             delete localStorage[k]
                       v
                     else
                       Settings.defaults[key] )         # 3rd choice, a default value

  # set key to value, or clear key if value is equal to default (thereby allowing defaults to change in future)
  # call callback, if provided, but only if no error arises
  set: (key, value, callback) ->
    if value == @defaults[key]
      @storage.clear key,
        ->
          Settings.storage_error "clear #{key}"
          callback key, @defaults[key] if callback and not chrome.runtime.lastError
    else
      item = {}
      item[key] = value
      @storage.set item,
        ->
          Settings.storage_error "set #{key}"
          callback key, value if callback and not chrome.runtime.lastError

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
