$(function(){

  // enable touch events only if not viewing a specific page
  if (!window.location.hash.match('#')) {


   var opts = {}; // { drag: true, transform: true };

    $('#main').hammer(opts)
      .on("swipeleft", function() {
          if (current != "ok")
            Wizard.toggle(+1);
      })
      .on("swiperight", function() {
          if (current != "ok")
          {
            var dir = current == 5 ? -2 : -1; // back two if on signup page
            Wizard.toggle(dir);
          }
      });
  
  }

  $('#signup').live('submit', function(e){

    var data = {
      username: this.name.value,
      email: this.email.value,
      password: this.password.value
    }

    console.log(data);
    //alert('Signing up!');

    // AndroidFunction.newuser();
    // Wizard.load('enable');
    window.location.href = "command://signup/"
                    
    e.preventDefault();
  })

  $('#login').live('submit', function(e){
                   
    var data = {
      email: this.email.value,
      password: this.password.value
    }

    console.log(data);
    //alert('Logging in!');

    //window.location = yourscheme:callfunction/parameter1/parameter2?parameter3=value
                   
    window.location.href = "command://signin/"+data.email+"/"+data.password;
    
    e.preventDefault();
  })

  $('a.panel').live('click', function(e){
    // AndroidFunction.goPanel();
    alert('Going to panel');
    e.preventDefault();
  })

  $('a.grant-rights').live('click', function(e){
    alert('Showing grants');
    e.preventDefault();
  });

})
