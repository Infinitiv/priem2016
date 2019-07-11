$ ->
  $('#request_query').change -> 
    if $('#request_query').val() == 'dictionarydetails'
      $('.dictionary-number').removeClass('hidden')
    else
      $('.dictionary-number').addClass('hidden')
    if $('#request_query').val() == 'checkapplication'
      $('.application-number').removeClass('hidden')
    else
      $('.application-number').addClass('hidden')
  $('#applications').change ->
    if $('#request_query').val() == 'import' & $('#applications:checked').length == 1
      $('.all-applications').removeClass('hidden')
    else
      $('.all-applications').addClass('hidden')
  $('#distributed_admission_volume_admission_volume_id').change ->
    $.getJSON('/distributed_admission_volumes/'+$(this).val()+'/admission_volume_to_json').done (data) ->
      data = data[0]
      $('#distributed_admission_volume_number_budget_o').val(parseInt(data.number_budget_o))
      $('#distributed_admission_volume_number_budget_oz').val(parseInt(data.number_budget_oz))
      $('#distributed_admission_volume_number_budget_z').val(parseInt(data.number_budget_z))
      $('#distributed_admission_volume_number_target_o').val(parseInt(data.number_target_o))
      $('#distributed_admission_volume_number_target_oz').val(parseInt(data.number_target_oz))
      $('#distributed_admission_volume_number_target_z').val(parseInt(data.number_target_z))
      $('#distributed_admission_volume_number_quota_o').val(parseInt(data.number_quota_o))
      $('#distributed_admission_volume_number_quota_oz').val(parseInt(data.number_quota_oz))
      $('#distributed_admission_volume_number_quota_z').val(parseInt(data.number_quota_z))
