// window.myVivus =  new Vivus('doodles-01', {duration: 500, type: 'delayed', pathTimingFunction: Vivus.EASE, animTimingFunction: Vivus.EASE_OUT});

$(function(){

  window.mySwiper = new Swiper ('.swiper-container', {
    init: false,
    runCallbacksOnInit: true,
    speed: 600,
    spaceBetween: 600,
    loop: false,
    parallax: false,
    paginationClickable: true,
    pagination: {
      el: '.swiper-pagination',
    },
    simulateTouch: true,
    mousewheel: {
      invert: true,
    }
  });
  window.mySwiper.on('init', function () {
    window.myVivus =  new Vivus('doodles-01', {duration: 500, type: 'delayed', pathTimingFunction: Vivus.EASE, animTimingFunction: Vivus.EASE_OUT});
  });
  window.mySwiper.on('slideChange', function () {
    if (window.mySwiper.activeIndex === 1) {
      window.myVivus2 =  new Vivus('doodles-02', {duration: 500, type: 'delayed', pathTimingFunction: Vivus.EASE, animTimingFunction: Vivus.EASE_OUT});
    }
    if (window.mySwiper.activeIndex === 2) {
      window.myVivus3 =  new Vivus('doodles-03', {duration: 500, type: 'delayed', pathTimingFunction: Vivus.EASE, animTimingFunction: Vivus.EASE_OUT});
    }
  });

  $('.btn-settings').click(function(){
    $('.popover').toggleClass("show");
  });
  $('.popover .close').click(function(){
    $('.popover').toggleClass("show");
  });

  $('.btn-reminder').click(function(){
    $('#reminder').toggleClass("show");
    window.mySwiper.init();
    setTimeout(function(){
      window.myVivus.play();
    }, 1000)
  });

  $('#reminder .close').click(function(){
    $('#reminder').toggleClass("show");
  });

});
