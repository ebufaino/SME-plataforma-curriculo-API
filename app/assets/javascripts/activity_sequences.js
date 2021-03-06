$(document).ready(function(){
  showCheckBoxesTooltip();
  changePreviewMessage();
  removeImageAfterUserConfirm();

  var body = document.getElementsByClassName('show admin_activity_sequences');
  if (body[0]) {
    var row_content = body[0].getElementsByClassName('row-books');
    var td = row_content[0].getElementsByTagName("td")[0];
    var content = td.innerHTML;

    var obj = JSON.parse(content);
    var html_content = quillGetHTML(obj);
    td.innerHTML = html_content;
  }
  $('#activity_sequence_main_curricular_component_id, #activity_sequence_year_id').change(fillLearningObjectives);
  $('#activity_sequence_segment_id').change(function(){
    var segment_id = $('#activity_sequence_segment_id').val();
    $.ajax({
      type: "GET",
      url: "/api/v1/stages",
      dataType: "json",
      data: {'segment_id': segment_id},
      success: function(result){
        $('#activity_sequence_stage_id option').remove();
        for (var i = 0; i < result.length; i++){
          $('#activity_sequence_stage_id').append(
            new Option(`${result[i]['name']}`, `${result[i]['id']}`)
          );
        }
        var stage_id = $('#activity_sequence_stage_id').val();
        $.ajax({
          type: "GET",
          url: "/api/v1/years",
          dataType: "json",
          data: {'segment_id': segment_id, 'stage_id': stage_id},
          success: function(result){
            $('#activity_sequence_year_id option').remove();
            for (var i = 0; i < result.length; i++){
              $('#activity_sequence_year_id').append(
                new Option(`${result[i]['name']}`, `${result[i]['id']}`)
              );
            }
          }
        });
      }
    });
  });
  $('#activity_sequence_stage_id').change(function(){
    var segment_id = $('#activity_sequence_segment_id').val();
    var stage_id = $(this).val();
    $.ajax({
      type: "GET",
      url: "/api/v1/years",
      dataType: "json",
      data: {'segment_id': segment_id, 'stage_id': stage_id},
      success: function(result){
        $('#activity_sequence_year_id option').remove();
        for (var i = 0; i < result.length; i++){
          $('#activity_sequence_year_id').append(
            new Option(`${result[i]['name']}`, `${result[i]['id']}`)
          );
        }
      }
    });
  });
});

function fillCheckBoxes(path, parent, ids, model) {
  url = '/admin/activity_sequences/' + path
  $.get(url, {}, function(res) {
    onGetResponse(res, parent, ids, model);
  })
}

function fillLearningObjectives() {
  var parent = $('#activity_sequence_learning_objectives_input ol');
  var main_curricular_component_id = $('#activity_sequence_main_curricular_component_id').val();
  var year_id = $('#activity_sequence_year_id').val();

  if (!main_curricular_component_id) {
    fillTextOnChecKBoxes(parent, 'Selecione um componente curricular');
    return
  }
  if (!year_id) {
    fillTextOnChecKBoxes(parent, 'Selecione um ano');
    return
  }

  var path = 'change_learning_objectives?main_curricular_component_id=' + main_curricular_component_id + '&year_id=' + year_id
  fillCheckBoxes(path,
                 parent,
                 'learning_objective_ids',
                'objetivo de aprendizagem')
}

function onGetResponse(res, parent, ids, model) {
    if (res.length === 0){
      fillTextOnChecKBoxes(parent, 'Nenhum ' + model + ' foi encontrado para o componente selecionado.');
    } else {
      create_check_box_list('activity_sequence', ids, res, parent);
    }
}

function showCheckBoxesTooltip(){
  label = $('.choices-group label');
  label.each(function(){
    self = $(this)
    new_title = self.find('input[type="checkbox"]')[0].title
    self.attr('title', new_title);
  });
}

function changePreviewMessage() {
  var image_inputs = $('#activity_sequence_image_input, #activity_image_input');
  image_inputs.find('input[type=file]').on('change', function(){
    var span = $('<span>').text('Imagem alterada, salve ou atualize para visualizar');
    var inline_hits = image_inputs.find('.inline-hints');;
    inline_hits.html(span);
  });
}

function removeImageAfterUserConfirm(){
  $('.remove-image-link').bind('confirm:complete', function(evt, data) {
    if(data){
      $(this).slideUp('slow', function(){
        $(this).remove();
      });
    }
  });
}

function setSelectOptions(){

}
