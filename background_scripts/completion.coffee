# This file contains the definition of the completers used for the Vomnibox's suggestion UI. A completer will
# take a query (whatever the user typed into the Vomnibox) and return a list of Suggestions, e.g. bookmarks,
# domains, URLs from history.
#
# The Vomnibox frontend script makes a "filterCompleter" request to the background page, which in turn calls
# filter() on each these completers.
#
# A completer is a class which has two functions:
#  - filter(query, onComplete): "query" will be whatever the user typed into the Vomnibox.
#  - refresh(): (optional) refreshes the completer's data source (e.g. refetches the list of bookmarks).

# A Suggestion is a bookmark or history entry which matches the current query.
# It also has an attached "computeRelevancyFunction" which determines how well this item matches the given
# query terms.
class Suggestion
  showRelevancy: true # Set this to true to render relevancy when debugging the ranking scores.

  # - type: one of [bookmark, history, tab].
  # - computeRelevancyFunction: a function which takes a Suggestion and returns a relevancy score
  #   between [0, 1]
  # - extraRelevancyData: data (like the History item itself) which may be used by the relevancy function.
  constructor: (@queryTerms, @type, @url, @title, @computeRelevancyFunction, @extraRelevancyData) ->
    @title ||= ""

  computeRelevancy: -> @relevancy = @computeRelevancyFunction(this)

  generateHtml: ->
    return @html if @html
    relevancyHtml = if @showRelevancy then "<span class='relevancy'>#{@computeRelevancy()}</span>" else ""
    # NOTE(philc): We're using these vimium-specific class names so we don't collide with the page's CSS.
    @html =
      """
      <div class="vimiumReset vomnibarTopHalf">
         <span class="vimiumReset vomnibarSource">#{@type}</span>
         <span class="vimiumReset vomnibarTitle">#{@highlightTerms(Utils.escapeHtml(@title))}</span>
       </div>
       <div class="vimiumReset vomnibarBottomHalf">
        <span class="vimiumReset vomnibarUrl">#{@shortenUrl(@highlightTerms(@url))}</span>
        #{relevancyHtml}
      </div>
      """

  shortenUrl: (url) -> @stripTrailingSlash(url).replace(/^http:\/\//, "")

  stripTrailingSlash: (url) ->
    url = url.substring(url, url.length - 1) if url[url.length - 1] == "/"
    url

  # Push the ranges within `string` which match `term` onto `ranges`.
  pushMatchingRanges: (string,term,ranges) ->
    textPosition = 0
    # Split `string` into a (flat) list of pairs:
    #   - for i=0,2,4,6,...
    #     - splits[i] is unmatched text
    #     - splits[i+1] is the following matched text (matching `term`)
    #       (except for the final element, for which there is no following matched text).
    # Example:
    #   - string = "Abacab"
    #   - term = "a"
    #   - splits = [ "", "A",    "b", "a",    "c", "a",    b" ]
    #                UM   M       UM   M       UM   M      UM      (M=Matched, UM=Unmatched)
    splits = string.split(RegexpCache.get(term, "(", ")"))
    for index in [0..splits.length-2] by 2
      unmatchedText = splits[index]
      matchedText = splits[index+1]
      # Add the indices spanning `matchedText` to `ranges`.
      textPosition += unmatchedText.length
      ranges.push([textPosition, textPosition + matchedText.length])
      textPosition += matchedText.length

  # Wraps each occurence of the query terms in the given string in a <span>.
  highlightTerms: (string) ->
    ranges = []
    for term in @queryTerms
      @pushMatchingRanges string, term, ranges

    return string if ranges.length == 0

    ranges = @mergeRanges(ranges.sort (a, b) -> a[0] - b[0])
    # Replace portions of the string from right to left.
    ranges = ranges.sort (a, b) -> b[0] - a[0]
    for [start, end] in ranges
      string =
        string.substring(0, start) +
        "<span class='vomnibarMatch'>#{string.substring(start, end)}</span>" +
        string.substring(end)
    string

  # Merges the given list of ranges such that any overlapping regions are combined. E.g.
  #   mergeRanges([0, 4], [3, 6]) => [0, 6].  A range is [startIndex, endIndex].
  mergeRanges: (ranges) ->
    previous = ranges.shift()
    mergedRanges = [previous]
    ranges.forEach (range) ->
      if previous[1] >= range[0]
        previous[1] = Math.max(range[1], previous[1])
      else
        mergedRanges.push(range)
        previous = range
    mergedRanges


class BookmarkCompleter
  currentSearch: null
  # These bookmarks are loaded asynchronously when refresh() is called.
  bookmarks: null

  filter: (@queryTerms, @onComplete) ->
    @currentSearch = { queryTerms: @queryTerms, onComplete: @onComplete }
    @performSearch() if @bookmarks

  onBookmarksLoaded: -> @performSearch() if @currentSearch

  performSearch: ->
    results =
      if @currentSearch.queryTerms.length > 0
        @bookmarks.filter (bookmark) =>
          RankingUtils.matches(@currentSearch.queryTerms, bookmark.url, bookmark.title)
      else
        []
    HistoryCache.use (history) =>
      suggestions = results.map (bookmark) =>
        i = HistoryCache.binarySearch { url: bookmark.url }, history, HistoryCache.compareHistoryByUrl
        historyEntry = if history[i]?.url == bookmark.url then history[i] else null
        new Suggestion(@currentSearch.queryTerms, "bookmark", bookmark.url, bookmark.title, @computeRelevancy, historyEntry)
      onComplete = @currentSearch.onComplete
      @currentSearch = null
      onComplete(suggestions)

  refresh: ->
    @bookmarks = null
    chrome.bookmarks.getTree (bookmarks) =>
      @bookmarks = @traverseBookmarks(bookmarks).filter((bookmark) -> bookmark.url?)
      @onBookmarksLoaded()

  # Traverses the bookmark hierarchy, and returns a flattened list of all bookmarks.
  traverseBookmarks: (bookmarks) ->
    includeBookmarkFolders = Settings.get("includeBookmarkFolders")
    parents = {} if includeBookmarkFolders
    results = []
    toVisit = bookmarks.reverse()
    while toVisit.length > 0
      bookmark = toVisit.pop()
      results.push(bookmark)
      if includeBookmarkFolders
        parentTitle = parents[bookmark.id]?.title || ""
        bookmark.title = parentTitle + "/" + bookmark.title if bookmark.title
      # Schedule processing of children.
      if bookmark.children
        if includeBookmarkFolders
          bookmark.children.map (bm) -> parents[bm.id] = bookmark
        toVisit.push.apply(toVisit, bookmark.children.reverse())
    results

  computeRelevancy: (suggestion) ->
    lastVisitTime = suggestion?.extraRelevancyData?.lastVisitTime || 0.0
    recencyScore = RankingUtils.recencyScore(lastVisitTime)
    wordRelevancy = RankingUtils.wordRelevancy(suggestion.queryTerms, suggestion.url, suggestion.title)
    (wordRelevancy + Math.max(recencyScore, wordRelevancy)) / 2

class HistoryCompleter
  filter: (queryTerms, onComplete) ->
    @currentSearch = { queryTerms: @queryTerms, onComplete: @onComplete }
    results = []
    HistoryCache.use (history) =>
      results =
        if queryTerms.length > 0
          history.filter (entry) -> RankingUtils.matches(queryTerms, entry.url, entry.title)
        else
          []
      suggestions = results.map (entry) =>
        new Suggestion(queryTerms, "history", entry.url, entry.title, @computeRelevancy, entry)
      onComplete(suggestions)

  computeRelevancy: (suggestion) ->
    historyEntry = suggestion.extraRelevancyData
    recencyScore = RankingUtils.recencyScore(historyEntry.lastVisitTime)
    wordRelevancy = RankingUtils.wordRelevancy(suggestion.queryTerms, suggestion.url, suggestion.title)
    # Average out the word score and the recency. Recency has the ability to pull the score up, but not down.
    score = (wordRelevancy + Math.max(recencyScore, wordRelevancy)) / 2

  refresh: ->

# The domain completer is designed to match a single-word query which looks like it is a domain. This supports
# the user experience where they quickly type a partial domain, hit tab -> enter, and expect to arrive there.
class DomainCompleter
  domains: null # A map of domain -> history

  filter: (queryTerms, onComplete) ->
    return onComplete([]) if queryTerms.length > 1
    if @domains
      @performSearch(queryTerms, onComplete)
    else
      @populateDomains => @performSearch(queryTerms, onComplete)

  performSearch: (queryTerms, onComplete) ->
    query = queryTerms[0]
    domainCandidates = (domain for domain of @domains when domain.indexOf(query) >= 0)
    domains = @sortDomainsByRelevancy(queryTerms, domainCandidates)
    return onComplete([]) if domains.length == 0
    topDomain = domains[0][0]
    onComplete([new Suggestion(queryTerms, "domain", topDomain, null, @computeRelevancy)])

  # Returns a list of domains of the form: [ [domain, relevancy], ... ]
  sortDomainsByRelevancy: (queryTerms, domainCandidates) ->
    results = []
    for domain in domainCandidates
      recencyScore = RankingUtils.recencyScore(@domains[domain].lastVisitTime || 0)
      wordRelevancy = RankingUtils.wordRelevancy(queryTerms, domain, null)
      score = (wordRelevancy + Math.max(recencyScore, wordRelevancy)) / 2
      results.push([domain, score])
    results.sort (a, b) -> b[1] - a[1]
    results

  populateDomains: (onComplete) ->
    HistoryCache.use (history) =>
      @domains = {}
      history.forEach (entry) =>
        # We want each key in our domains hash to point to the most recent History entry for that domain.
        domain = @parseDomain(entry.url)
        if domain
          previousEntry = @domains[domain]
          @domains[domain] = entry if !previousEntry || (previousEntry.lastVisitTime < entry.lastVisitTime)
      chrome.history.onVisited.addListener(@onPageVisited.bind(this))
      onComplete()

  onPageVisited: (newPage) ->
    domain = @parseDomain(newPage.url)
    @domains[domain] = newPage if domain

  parseDomain: (url) -> url.split("/")[2] || ""

  # Suggestions from the Domain completer have the maximum relevancy. They should be shown first in the list.
  computeRelevancy: -> 1

# Searches through all open tabs, matching on title and URL.
class TabCompleter
  filter: (queryTerms, onComplete) ->
    # NOTE(philc): We search all tabs, not just those in the current window. I'm not sure if this is the
    # correct UX.
    chrome.tabs.query {}, (tabs) =>
      results = tabs.filter (tab) -> RankingUtils.matches(queryTerms, tab.url, tab.title)
      suggestions = results.map (tab) =>
        suggestion = new Suggestion(queryTerms, "tab", tab.url, tab.title, @computeRelevancy)
        suggestion.tabId = tab.id
        suggestion
      onComplete(suggestions)

  computeRelevancy: (suggestion) ->
    RankingUtils.wordRelevancy(suggestion.queryTerms, suggestion.url, suggestion.title)

# A completer which calls filter() on many completers, aggregates the results, ranks them, and returns the top
# 10. Queries from the vomnibar frontend script come through a multi completer.
class MultiCompleter
  constructor: (@completers) -> @maxResults = 10

  refresh: -> completer.refresh() for completer in @completers when completer.refresh

  filter: (queryTerms, onComplete) ->
    # Allow only one query to run at a time.
    if @filterInProgress
      @mostRecentQuery = { queryTerms: queryTerms, onComplete: onComplete }
      return
    RegexpCache.clear()
    @mostRecentQuery = null
    @filterInProgress = true
    suggestions = []
    completersFinished = 0
    for completer in @completers
      # Call filter() on every source completer and wait for them all to finish before returning results.
      completer.filter queryTerms, (newSuggestions) =>
        suggestions = suggestions.concat(newSuggestions)
        completersFinished += 1
        if completersFinished >= @completers.length
          results = @sortSuggestions(suggestions)[0...@maxResults]
          result.generateHtml() for result in results
          onComplete(results)
          @filterInProgress = false
          @filter(@mostRecentQuery.queryTerms, @mostRecentQuery.onComplete) if @mostRecentQuery

  sortSuggestions: (suggestions) ->
    suggestion.computeRelevancy(@queryTerms) for suggestion in suggestions
    suggestions.sort (a, b) -> b.relevancy - a.relevancy
    suggestions

# Utilities which help us compute a relevancy score for a given item.
RankingUtils =
  # Whether the given things (usually URLs or titles) match any one of the query terms.
  # This is used to prune out irrelevant suggestions before we try to rank them, and for calculating word relevancy.
  # Every term must match at least one thing.
  matches: (queryTerms, things...) ->
    for term in queryTerms
      regexp = RegexpCache.get(term)
      matchedTerm = false
      for thing in things
        matchedTerm ||= thing.match regexp
      return false unless matchedTerm
    true

  # Weights used for scoring matches.
  # `matchWeights.maximumScore` must be the sum of the three weights above it.
  # TODO: These are fudge factors, they can be tuned.
  matchWeights:
    {
      matchAnywhere:     1
      matchStartOfWord:  1
      matchWholeWord:    1
      # The following must be the sum of the weights above; it is used for normalization.
      # TODO: This can be calculated at runtime.
      maximumScore:      3
      #
      # Calibration factor for balancing word relevancy and recency.
      recencyCalibrator: 2.0/3.0
      # The current value of 2.0/3.0 has the effect of:
      #   - favoring the contribution of recency when matches are not on word boundaries   ( because 2.0/3.0 > (1)/3     )
      #   - retaining the existing balance when matches are at the starts of words         ( because 2.0/3.0 = (1+1)/3   )
      #   - favoring the contribution of word relevance when matches are on whole words    ( because 2.0/3.0 < (1+1+1)/3 )
    }

  # Calculate a score for matching `term` against `string`.
  # The score is in the range [0, `matchWeights.maximumScore`], see above.
  scoreTerm: (term, string) ->
    score = 0
    if string.match RegexpCache.get term
      # Have match.
      score += RankingUtils.matchWeights.matchAnywhere
      if string.match RegexpCache.get term, "\\b"
        # Have match at start of word.
        score += RankingUtils.matchWeights.matchStartOfWord
        if string.match RegexpCache.get term, "\\b", "\\b"
          # Have match of whole word.
          score += RankingUtils.matchWeights.matchWholeWord
    score

  # TODO: Remove this explanatory comment.
  #
  # The differences between the following version of `wordRelevancy` and the old one are:
  #   - It reduces the score of matches which are not at the start of a word by a factor of 1/3.
  #   - It reduces the score of other matches, but which are not whole words, by a factor of 2/3.
  #   - These values come from the fudge factors in `matchWeights`, above.
  #   - It makes no change to the score for matches which are whole words.
  #   - It doesn't allow a poor urlScore to pull down the titleScore.
  # 
  # In the absence of matches on word boundaries, the relative ordering of
  # scores for URLs and titles is unchanged vis-a-vis the old version.
  #
  # Overall, this change has two effects:
  #
  #   - It changes the *relative order* of scores awarded for word relevancy.
  #     This is ok.  In fact, it's good: that is the intention.
  #
  #   - However, it also has another effect ...
  #
  #     It reduces the *absolute values* of word-relevancy scores, on average.
  #
  #     Overall, ranking depends both on word relevancy and recency.  Were the
  #     absolute values of recency scores not *similarly adjusted*, recency
  #     would dominate the overall ordering. This is why the fudge factor
  #     `matchWeights.recencyCalibrator` has been introduced.
  #
  #     See also the comment in the definition of `matchWeights`, above.

  # Returns a number between [0, 1] indicating how often the query terms appear in the url and title.
  wordRelevancy: (queryTerms, url, title) ->
    debugging = true
    queryLength = 0
    urlScore = 0.0
    titleScore = 0.0

    # Calculate initial scores.
    for term in queryTerms
      queryLength += term.length
      urlScore += RankingUtils.scoreTerm term, url
      titleScore += RankingUtils.scoreTerm term, title if title

    maximumPossibleScore = RankingUtils.matchWeights.maximumScore * queryTerms.length

    # Normalize urlScore.
    urlScore /= maximumPossibleScore
    console.log "THIS SHOULD NOT HAPPEN: urlScore exceeds 1.0: #{urlScore} #{url}" if debugging and 1.0 < urlScore
    urlScore *= RankingUtils.normalizeDifference queryLength, url.length

    if title
      # Normalize titleScore (same as for urlScore, above).
      # TODO: (smblott)
      #       We've got basically the same code here, same as just as above.  Factor it out?
      titleScore /= maximumPossibleScore
      console.log "THIS SHOULD NOT HAPPEN: titleScore exceeds 1.0: #{titleScore} #{title}" if debugging and 1.0 < titleScore
      # TODO: (smblott)
      #       The intuition hehind the following is (I think) to award higher
      #       scores when there's good coverage of the title by the query
      #       terms, and vice versa.  So shorter queries matching longer titles
      #       are pushed down the ranking.
      #       Suggest:  A query term may match in multiple places. So the
      #       calculation should account for the *number of characters matched*
      #       by the query, not just its length.
      #       Example: Query is "BBC", title is "BBC (BBCr4)".  The coverage of
      #       the match should be 6/11, rather than 3/11 (as it is currently).
      #       Obviously, the same applies to urlScore, above.
      titleScore *= RankingUtils.normalizeDifference queryLength, title.length
    else
      titleScore = urlScore

    # ######################################################
    # Up to this point, things are pretty much the same as they were in the old
    # version, just with additional tests and their corresponding weights.
    #
    # However, there are three possible endings to this story ...

    # ######################################################
    # Ending #1: The old ending ...
    #
    # return (urlScore + titleScore) / 2
    #
    # It's difficult to argue with that.

    # ######################################################
    # Ending #2: An ending favoring `titleScore` ...
    #
    # Prefer matches in the title over matches in the URL.
    # Here, this means "don't let a poor urlScore pull down the titleScore".
    # For example, urlScore can be unreasonably poor if the URL is very long.
    urlScore = titleScore if urlScore < titleScore

    # Return the average.
    (urlScore + titleScore) / 2

    # ######################################################
    # Ending #3: An alternative (better?) ending ...
    #
    # return Math.max(urlScore, titleScore)
    #
    # Why?
    #   - Don't let a poor urlScore pull down a good titleScore, as in Ending #2.
    #   - But also don't let a poor titleScore pull down a good urlScore.
    #   - The query may be targeting one or the other, so let the best one win.

    # Pick one of these three endings.
    #
    # I (smblott) set off planning Ending #2.
    # My son suggested Ending #3.
    # I'm thinking now that he may be on to something.
    # ######################################################

  # Returns a score between [0, 1] which indicates how recent the given timestamp is. Items which are over
  # a month old are counted as 0. This range is quadratic, so an item from one day ago has a much stronger
  # score than an item from two days ago.
  recencyScore: (lastAccessedTime) ->
    @oneMonthAgo ||= 1000 * 60 * 60 * 24 * 30
    recency = Date.now() - lastAccessedTime
    recencyDifference = Math.max(0, @oneMonthAgo - recency) / @oneMonthAgo

    # recencyScore is between [0, 1]. It is 1 when recenyDifference is 0. This quadratic equation will
    # incresingly discount older history entries.
    recencyScore = recencyDifference * recencyDifference * recencyDifference

    # Calibrate recencyScore vis-a-vis word-relevancy scores.
    # This does not change the relative order of recency scores.
    # See also comment in the definition of `matchWeights`, above.
    recencyScore *= RankingUtils.matchWeights.recencyCalibrator

  # Takes the difference of two numbers and returns a number between [0, 1] (the percentage difference).
  normalizeDifference: (a, b) ->
    max = Math.max(a, b)
    (max - Math.abs(a - b)) / max

# We cache regexps because we use them frequently when comparing a query to history entries and bookmarks,
# and we don't want to create fresh objects for every comparison.
RegexpCache =
  init: ->
    @initialized = true
    @clear()
    # Taken from http://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
    @escapeRegExp ||= /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g

  clear: -> @cache = {}

  # Get rexexp for `string` from cache, creating it if necessary.
  # Regexp meta-characters in `string` are escaped.
  # Regexp is wrapped in `prefix`/`suffix`, which may contain meta-characters (these are not escaped).
  # With their default values, `prefix` and `suffix` have no effect.
  # Example:
  #   - string="go", prefix="\b", suffix=""
  #   - this returns regexp matching "google", but not "agog" (the "go" must occur at the start of a word)
  # TODO: `prefix` and `suffix` might be useful in richer word-relevancy scoring.
  # Get rexexp for string from cache, creating the regexp if necessary.
  # Regexp meta-characters in string are escaped.
  # Regexp is wrapped in prefix/suffix, which may contain meta-characters.
  get: (string, prefix="", suffix="") ->
    @init() unless @initialized
    regexpString = string.replace(@escapeRegExp, "\\$&")
    # Avoid cost of constructing new strings if prefix/suffix are empty (which is expected to be a common case).
    regexpString = prefix + regexpString if prefix
    regexpString = regexpString + suffix if suffix
    @cache[regexpString] ||= new RegExp(regexpString, "i")

# Provides cached access to Chrome's history. As the user browses to new pages, we add those pages to this
# history cache.
HistoryCache =
  size: 20000
  history: null # An array of History items returned from Chrome.

  reset: ->
    @history = null
    @callbacks = null

  use: (callback) ->
    return @fetchHistory(callback) unless @history?
    callback(@history)

  fetchHistory: (callback) ->
    return @callbacks.push(callback) if @callbacks
    @callbacks = [callback]
    # FIXME: (smblott)
    #        `startTime` being set to `0`, below, is a potential problem.
    #        If there are more than `@size` entries in the chrome history, then
    #        we don't really know what will be returned.  The API doesn't say.
    #        And there may well be more than `@size` entries, that's just 200
    #        days of browsing at 100 new history entries per day.
    #        Suggest setting `startTime` to something more reasonable.
    #        Perhaps "one month ago"?  Then it would match how recency scores are calculated.
    #        Even "six month ago" may at least be a bit safer.
    chrome.history.search { text: "", maxResults: @size, startTime: 0 }, (history) =>
      history.sort @compareHistoryByUrl
      @history = history
      chrome.history.onVisited.addListener(@onPageVisited.bind(this))
      callback(@history) for callback in @callbacks
      @callbacks = null

  compareHistoryByUrl: (a, b) ->
    return 0 if a.url == b.url
    return 1 if a.url > b.url
    -1

  # When a page we've seen before has been visited again, be sure to replace our History item so it has the
  # correct "lastVisitTime". That's crucial for ranking Vomnibar suggestions.
  onPageVisited: (newPage) ->
    i = HistoryCache.binarySearch(newPage, @history, @compareHistoryByUrl)
    pageWasFound = (@history[i].url == newPage.url)
    if pageWasFound
      @history[i] = newPage
    else
      @history.splice(i, 0, newPage)

# Returns the matching index or the closest matching index if the element is not found. That means you
# must check the element at the returned index to know whether the element was actually found.
# This method is used for quickly searching through our history cache.
HistoryCache.binarySearch = (targetElement, array, compareFunction) ->
  high = array.length - 1
  low = 0

  while (low <= high)
    middle = Math.floor((low + high) / 2)
    element = array[middle]
    compareResult = compareFunction(element, targetElement)
    if (compareResult > 0)
      high = middle - 1
    else if (compareResult < 0)
      low = middle + 1
    else
      return middle
  # We didn't find the element. Return the position where it should be in this array.
  return if compareFunction(element, targetElement) < 0 then middle + 1 else middle

root = exports ? window
root.Suggestion = Suggestion
root.BookmarkCompleter = BookmarkCompleter
root.MultiCompleter = MultiCompleter
root.HistoryCompleter = HistoryCompleter
root.DomainCompleter = DomainCompleter
root.TabCompleter = TabCompleter
root.HistoryCache = HistoryCache
root.RankingUtils = RankingUtils
root.RegexpCache = RegexpCache
