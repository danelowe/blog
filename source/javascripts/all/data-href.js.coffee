# Non-anchor elements that link to a page.
(($) ->
  $ ->
    $('[data-href]').click (e) ->
      if (e.ctrlKey || e.metaKey)
        window.open($(this).data('href'))
      else if Turbolinks?
        Turbolinks.visit($(this).data('href'))
      else
        window.location = $(this).data('href')
) (window.jQuery || window.ender || window.Zepto)
