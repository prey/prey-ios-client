$(function(){
  var types = {
    ANDROID_INIT: 100,
    ANDROID_ACCOUNT_CREATED: 101,
    ANDROID_IDENTIFIER_TO_KEY: 102,
    ANDROID_TOUR_COMPLETED: 103,
    ANDROID_PRIVILEGES_GIVEN: 104
  }
  //-PreyEvent(types.ANDROID_INIT);

  $('.m-scooch').scooch();
  var aok = 0;
  // $('#uncomplete').toggleClass('off on');
  // $('#complete').toggleClass('off on');
  $('input').click(function(){
    $(this).focus();
  });
  $('.signup-btn').click(function(){
    //PreyEvent(types.ANDROID_ACCOUNT_CREATED);
    $('#secure .opts .acc').addClass('ok');
    aok++;
    if (aok >= 2) {
      // $('#intro').addClass('aok');
      $('#uncomplete').toggleClass('off on');
      $('#complete').toggleClass('off on');
    }
  });
  $('.demo-pri').click(function(){
    //PreyEvent(types.ANDROID_PRIVILEGES_GIVEN);
    $('#secure .opts .pri').addClass('ok');
    aok++;
    if (aok >= 2) {
      $('#uncomplete').toggleClass('off on');
      $('#complete').toggleClass('off on');
      // $('#intro').addClass('aok');
      // $('.status-text').text('Protected').toggleClass('on off');
      // setTimeout(function(){
      //
      // }, 3000);
    }
  });
  // $('.onb-ok').click(function(){
  //   $('#intro .opts .pan').addClass('ok');
  //   aok++;
  //   if (aok >= 3) {
  //     $('#intro').addClass('aok');
  //   }
  // });

  $('.onb-ok').click(function(){
    //-PreyEvent(types.ANDROID_TOUR_COMPLETED);
  });

  $('.tour .close').click(function(e){
    e.preventDefault();
    $(this).parent().addClass('removeTourBtn');
  });

});
