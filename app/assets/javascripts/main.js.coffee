ready = ->
  $('#request_query').change -> 
    if $('#request_query').val() == 'dictionarydetails'
      $('.dictionary-number').removeClass('hidden')
    else
      $('.dictionary-number').addClass('hidden')
    if $('#request_query').val() == 'checkapplication'
      $('.application-number').removeClass('hidden')
    else
      $('.application-number').addClass('hidden')
      
$(document).ready(ready)
$(document).on('page:load', ready)