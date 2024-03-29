Vimium - The Hacker's Browser
=============================

Vimium+
-------

Vimium+ is an extended version of [Vimium](https://github.com/philc/vimium)
incorporating a number of improvements.

The [master](https://github.com/smblott-github/vimium/tree/master) branch is pretty much a copy of Vimium itself.  All of the new
stuff is in the [Vimium+
branch](https://github.com/smblott-github/vimium/tree/vimium+).

Features:

- Options are shared between installations.  So, if you use Vimium+ on a laptop
  and on a desktop, option changes made on one are propagated automatically to
  the other.

- Selective disabling of Vimium key bindings.  Vanilla Vimium is either enabled or
  disabled on a page.  With Vimium+, if a site is listed as disabled but the listing is
  followed by a sequence of keys, then only those keys are disabled.  For
  example, to use Google's `j` and `k` bindings on GMail, use
  `https://mail.google.com/* jk` -- now, just those two keys are disabled, all
  other Vimium keys are handled by Vimium, as usual.

- Smartcase.  Vomnibar searches are case insensitive, except if the search term
  includes a capital letter, in which case they are case sensitive. Tip: give
  your bookmarks names which include shortcuts, all in capital letters.  For
  example, include the text `GML` in your GMail bookmark, and go directly to it
  by typing capital letters.

- Better scoring of bookmark and history searches.  In particular, a match at
  the start of a word scores higher, and a match of a whole word scores higher
  still.

- Even better scoring of bookmark searches.  In particular, recency is included
  in the relevancy calculation.  So bookmarks you use frequently should appear
  nearer the top of the list.

- Search bookmarks by folder.  If a bookmark search includes the character `/`,
  then search terms are matched against the whole bookmark path, not just the
  final bookmark name.  For example, `/mob` will match bookmarks in the
  `/Mobile Bookmarks` folder.

- The `ENTER` key on an empty vomnibar just cancels (as opposed to opening a new tab).

What follows is the original Vimium README...

Vimium
------

Vimium is a Chrome extension that provides keyboard-based navigation and control in the spirit of the Vim
editor.

__Installation instructions:__

You can install the stable version of Vimium from the
[Chrome Extensions Gallery](https://chrome.google.com/extensions/detail/dbepggeogbaibhgnhhndojpepiihcmeb).

Please see
[CONTRIBUTING.md](https://github.com/philc/vimium/blob/master/CONTRIBUTING.md#installing-from-source)
for instructions on how you can install Vimium from source.

The Options page can be reached via a link on the help dialog (hit `?`) or via the button next to Vimium on
the Chrome Extensions page (`chrome://extensions`).

Keyboard Bindings
-----------------

Modifier keys are specified as `<c-x>`, `<m-x>`, and `<a-x>` for ctrl+x, meta+x, and alt+x
respectively. See the next section for instructions on modifying these bindings.

Navigating the current page:

    ?       show the help dialog for a list of all available keys
    h       scroll left
    j       scroll down
    k       scroll up
    l       scroll right
    gg      scroll to top of the page
    G       scroll to bottom of the page
    d       scroll down half a page
    u       scroll up half a page
    f       open a link in the current tab
    F       open a link in a new tab
    r       reload
    gs      view source
    i       enter insert mode -- all commands will be ignored until you hit esc to exit
    yy      copy the current url to the clipboard
    yf      copy a link url to the clipboard
    gf      cycle forward to the next frame

Navigating to new pages:

    o       Open URL, bookmark, or history entry
    O       Open URL, bookmark, history entry in a new tab
    b       Open bookmark
    B       Open bookmark in a new tab

Using find:

    /       enter find mode -- type your search query and hit enter to search or esc to cancel
            See here for advanced usage (regular expressions): https://github.com/philc/vimium/wiki/Find-Mode
    n       cycle forward to the next find match
    N       cycle backward to the previous find match

Navigating your history:

    H       go back in history
    L       go forward in history

Manipulating tabs:

    J, gT      go one tab left
    K, gt      go one tab right
    g0         go to the first tab
    g$         go to the last tab
    t          create tab
    yt         duplicate current tab
    x          close current tab
    X          restore closed tab (i.e. unwind the 'x' command)
    T          search through your open tabs

Additional advanced browsing commands:

    ]]      Follow the link labeled 'next' or '>'. Helpful for browsing paginated sites.
    [[      Follow the link labeled 'previous' or '<'. Helpful for browsing paginated sites.
    <a-f>   open multiple links in a new tab
    gi      focus the first (or n-th) text input box on the page
    gu      go up one level in the URL hierarchy
    <c-a>   increment the last number found in the url
    <c-x>   decrement the last number found in the url
    gU      go up to root of the URL hierarchy
    zH      scroll all the way left
    zL      scroll all the way right

Vimium supports command repetition so, for example, hitting '5t' will open 5 tabs in rapid succession. `<ESC>` (or
`<c-[>`) will clear any partial commands in the queue and will also exit insert and find modes.


Custom Key Mappings
-------------------

You may remap or unmap any of the default key bindings in the "Key mappings" section under "Advanced Options"
on the options page.

Enter one of the following key mapping commands per line:

- `map key command`: Maps a key to a Vimium command. Overrides Chrome's default behavior (if any).
- `unmap key`: Unmaps a key and restores Chrome's default behavior (if any).
- `unmapAll`: Unmaps all bindings. This is useful if you want to completely wipe Vimium's defaults and start
  from scratch with your own setup.

Examples:

- `map <c-d> scrollPageDown` maps ctrl+d to scrolling the page down. Chrome's default behavior of bringing up
  a bookmark dialog is suppressed.
- `map r reload` maps the r key to reloading the page.
- `unmap <c-d>` removes any mapping for ctrl+d and restores Chrome's default behavior.
- `unmap r` removes any mapping for the r key.

Available Vimium commands can be found via the "Show Available Commands" link near the key mapping box. The
command name appears to the right of the description in parenthesis.

You can add comments to your key mappings by starting a line with `"` or `#`.

The following special keys are available for mapping:

- `<c-*>`, `<a-*>`, `<m-*>` for ctrl, alt, and meta (command on Mac) respectively with any key. Replace `*`
  with the key of choice.
- `<left>`, `<right>`, `<up>`, `<down>` for the arrow keys
- `<f1>` through `<f12>` for the function keys

Shifts are automatically detected so, for example, `<c-&>` corresponds to ctrl+shift+7 on an English keyboard.

Contributing
------------
Please see [CONTRIBUTING.md](https://github.com/philc/vimium/blob/master/CONTRIBUTING.md) for details.

Release Notes
-------------
1.44 (11/06/2013)

- Add support for recent versions of Chromium.
- Bugfixes.

1.43 (05/18/2013)

- Relevancy improvements to the Vomnibar's domain & history search.
- Added gU, which goes to the root of the current URL.
- Added yt, which duplicates the current tab.
- Added W, which moves the current tab to a new window.
- Added marks for saving and jumping to sections of a page. mX to set a mark and `X to return to it.
- Added "LinkHints.activateModeToOpenIncognito", currently an advanced, unbound command.
- Disallowed repeat tab closings, since this causes trouble for many people.
- Update our Chrome APIs so Vimium works on Chrome 28+.
- Bugfixes.

1.42 (11/03/2012)

- Bugfixes.

1.41 (10/27/2012)

- Bugfixes.

1.40 (10/27/2012)

- Bugfixes.
- Added options for search engines and regex find.
- Pressing unmapped keys in hints mode now deactivates the mode.

1.39 (09/09/2012)

- Bugfixes.

1.38 (09/08/2012)

- `O` now opens Vomnibar results in a new tab. `B` does the same for bookmarks only.
- Add a browser icon to quickly add sites to Vimium's exclude list.
- Restyle options page.
- `gi` now launches a new mode that allows the user to tab through the input elements on the page.
- Bugfixes.

1.37 (07/07/2012)

- Select the first result by default in Vomnibar tab and bookmark modes.

1.36 (07/07/2012)

- 'b' brings up a bookmark-only Vomnibar.
- Better support for some bookmarklets.

1.35 (07/05/2012)

- Bugfixes.

1.34 (07/03/2012)

- A bugfix for bookmarklets in Vomnibar.

1.33 (07/02/2012)

- A Vomnibar, which allows you to open sites from history, bookmarks, and tabs using Vimium's UI. Type "o" to try it.

1.32 (03/05/2012)

- More tweaks to the next / previous link-detection algorithm.
- Minor bug fixes.

1.31 (02/28/2012)

- Improve style of link hints, and use fewer characters for hints.
- Add an option to hide the heads up display (HUD). Notably, the HUD obscures Facebook Chat's textbox.
- Detection and following of next / previous links has been improved.
- Addition of g0 and g$ commands, for switching tabs.
- Addition of p/P commands for URL pasting.
- A new find mode which optionally supports case sensitivity and regular expressions.
- Bug fixes.

1.30 (12/04/2011)

- Support for image maps in link hints.
- Counts now work with forward & backward navigation.
- Tab & shift-tab to navigate bookmarks dialog.
- An alternate link hints mode: type the title of a link to select it. You can enable it in Vimium's Advanced Preferences.
- Bug fixes.

1.29 (07/30/2011)

- `yf` to copy a link hint url to the clipboard.
- Scatter link hints to prevent clustering on dense sites.
- Don't show insert mode notification unless you specifically hit `i`.
- Remove zooming functionality now that Chrome does it all natively.

1.28 (06/29/2011)

- Support for opening bookmarks (`b` and `B`).
- Support for contenteditable text boxes.
- Speed improvements and bugfixes.

1.27 (03/24/2011)

- Improvements and bugfixes.

1.26 (02/17/2011)

- `<c-d>`, `<c-f>` and related are no longer bound by default. You can rebind them on the options page.
- Faster link hinting.

1.22, 1.23, 1.24, 1.25 (02/10/2011)

-  Some sites are now excluded by default.
-  View source (`gs`) now opens in a new tab.
-  Support for browsing paginated sites using `]]` and `[[` to go forward and backward respectively.
-  Many of the less-used commands are now marked as "advanced" and hidden in the help dialog by default, so
   that the core command set is more focused and approachable.
-  Improvements to link hinting.
-  Bugfixes.

1.21 (10/24/2010)

-  Critical bugfix for an excluded URLs regression due to frame support.

1.20 (10/24/2010)

-  In link hints mode, holding down the shift key will now toggle between opening in the current tab and
   opening in a new tab.
-  Two new commands (`zH` and `zL`) to scroll to the left and right edges of the page.
-  A new command (`gi`) to focus the first (or n-th) text input box on the page.
-  A new command (`<a-f>`) to open up multiple links at a time in new tabs.
-  Frame support.
-  More robust support for non-US keyboard layouts.
-  Numerous bug fixes.

1.19 (06/29/2010)

-  A critical bug fix for development channel Chromium.
-  Vimium icons for the Chrome extensions panel and other places.

1.18 (06/22/2010)

-  Vimium now runs on pages with file:/// and ftp:///
-  The Options page is now linked from the Help dialog.
-  Arrow keys and function keys can now be mapped using &lt;left&gt;, &lt;right&gt;, &lt;up&gt;, &lt;down&gt;,
   &lt;f1&gt;, &lt;f2&gt;, etc. in the mappings interface.
-  There is a new command `goUp` (mapped to `gu` by default) that will go up one level in the URL hierarchy.
   For example: from http://vimium.github.com/foo/bar to http://vimium.github.com/foo. At the moment, `goUp`
does not support command repetition.
-  Bug fixes and optimizations.

1.17 (04/18/2010)

-  'u' now restores tabs that were closed by the mouse or with native shortcuts. Tabs are also restored in
   their prior position.
-  New 'unmapAll' command in the key mappings interface to remove all default mappings.
-  Link hints are now faster and more reliable.
-  Bug fixes.

1.16 (03/09/2010)

-  Add support for configurable key mappings under Advanced Options.
-  A help dialog which shows all currently bound keyboard shortcuts. Type "?" to see it.
-  Bug fixes related to key stroke handling.

1.15 (01/31/2010)

-  Make the CSS used by the link hints configurable. It's under Advanced Options.
-  Add a notification linking to the changelog when Vimium is updated in the background.
-  Link-hinting performance improvements and bugfixes.
-  Ctrl+D and Ctrl+U now scroll by 1/2 page instead of a fixed amount, to mirror Vim's behavior.

1.14 (01/21/2010)

-  Fixed a bug introduced in 1.13 that prevented excluded URLs from being saved.

1.13 (01/21/2010)

- `<c-f>` and `<c-b>` are now mapped to scroll a full page up or down respectively.
-  Bugfixes related to entering insert mode when the page first loads, and when focusing Flash embeds.
-  Added command listing to the Options page for easy reference.
-  J & K have reversed for tab switching: J goes left and K goes right.
-  `<c-[>` is now equivalent to ESC, to match the behavior of VIM.
-  `<c-e>` and `<c-y>` are now mapped to scroll down and up respectively.
-  The characters used for link hints are now configurable under Advanced Options.

1.11, 1.12 (01/08/2010)

-  Commands 'gt' & 'gT' to move to the next & previous tab.
-  Command 'yy' to yank (copy) the current tab's url to the clipboard.
-  Better Linux support.
-  Fix for Shift+F link hints.
-  ESC now clears the keyQueue. So, for example, hitting 'g', 'ESC', 'g' will no longer scroll the page.

1.1 (01/03/2010)

-  A nicer looking settings page.
-  An exclusion list that allows you to define URL patterns for which Vimium will be disabled (e.g.
   http\*://mail.google.com/\*).
-  Vimium-interpreted keystrokes are no longer sent to the page.
-  Better Windows support.
-  Various miscellaneous bug fixes and UI improvements.

License
-------
Copyright (c) 2010 Phil Crosby, Ilya Sukhar. See MIT-LICENSE.txt for details.
