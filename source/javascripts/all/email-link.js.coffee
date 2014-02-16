#
# * emailLink - jQuery Plugin
# * Email address cloaking
# *
# * Copyright (c) 2009 - 2012 Bjørn Johansen. All rights reserved.
# *
# * Version: 1.4
# * Requires: jQuery v1.3+
# *
# * Dual licensed under the MIT and GPL licenses:
# *   http://www.opensource.org/licenses/mit-license.php
# *   http://www.gnu.org/licenses/gpl.html
#
(($) ->
  $.fn.emailLink = (options) ->
    settings =
      domainDelimeter: " / "
      dotDelimeter: ", "
      textSrc: "title"

    hostname = document.location.hostname.replace(/^www\./, "")
    @each ->
      $.extend settings, options  if options
      addr = undefined
      em = undefined
      $link = undefined
      try
        em = $(this).text().split(settings.domainDelimeter)
        addr = (if (em.length is 2) then em[0] + "@" + em[1] else em[0] + "@" + hostname)
        addr = addr.replace(new RegExp(settings.dotDelimeter, "g"), ".")
        $link = $(document.createElement("a"))
        $link.prop "href", "mailto:" + addr
        if $(this).prop(settings.textSrc)
          $link.text $(this).prop(settings.textSrc)
        else
          $link.text addr
        $link.addClass "e-mail"
        $(this).replaceWith $link
      return

  $ ->
    $('.e').emailLink();

) (window.jQuery || window.ender || window.Zepto)