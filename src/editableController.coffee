class EditableController extends Controller

  _getRange: ->
    sel = @app.window.getSelection()
    sel.getRangeAt(0) if sel.rangeCount > 0

  _setRangeEndAfter: (node, range=@_getRange()) ->
    sel = @app.window.getSelection()
    range.setEndAfter $(node)[0]
    range.collapse false
    sel.removeAllRanges()
    sel.addRange range


  catch_query: (e) ->
    return unless range = @_getRange()
    $(range.startContainer).closest '.atwho-inserted'
      .removeClass 'atwho-inserted'
      .addClass 'atwho-query'
    if ($query = $ ".atwho-query", @app.document).length > 0
      if e.type is "click" and $(range.startContainer).closest('.atwho-query').length is 0
        matched = null
      else
        matched = @callbacks("matcher").call(this, @at, $query.text(), @get_opt 'start_with_space')
    else
      _range = range.cloneRange()
      _range.setStart range.startContainer, 0
      content = _range.toString()
      matched = @callbacks("matcher").call(this, @at, content, @get_opt 'start_with_space')
      if typeof matched is 'string'
        range.setStart range.startContainer, content.lastIndexOf @at
        range.surroundContents ($query = $ "<span class='atwho-query'/>", @app.document)[0]
        @_setRangeEndAfter $query, range
    if typeof matched is 'string' and matched.length <= @get_opt('max_len', 20)
      query = text: matched, el: $query
      @trigger "matched", [@at, query.text]
    else
      @view.hide()
      query = null
      if $query.text().indexOf(@at) > -1
        $query.html $query.text()
        @_setRangeEndAfter $query.contents().first().unwrap()
    @query = query

  # Get offset of current at char(`flag`)
  #
  # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
  rect: ->
    rect = @query.el.offset()
    if @app.iframe and not @app.iframeStandalone
      iframe_offset = $(@app.iframe).offset()
      rect.left += iframe_offset.left
      rect.top += iframe_offset.top
    rect.bottom = rect.top + @query.el.height()
    rect

  # Insert value of `data-value` attribute of chosen item into inputor
  #
  # @param content [String] string to insert
  insert: (content, $li) ->
    suffix = if suffix = @get_opt 'suffix' then suffix else suffix or "\u00A0" 
    @query.el
      .removeClass 'atwho-query'
      .addClass 'atwho-inserted'
      .html content
    if range = @_getRange()
      range.setEndAfter @query.el[0]
      range.collapse false
      range.insertNode suffixNode = @app.document.createTextNode suffix
      @_setRangeEndAfter suffixNode, range
    @$inputor.focus() unless @$inputor.is ':focus'
    @$inputor.change()