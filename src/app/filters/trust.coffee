app.filter 'trust', ($sce) ->
  (html) ->
    $sce.trustAsHtml html
