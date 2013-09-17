$(document).ready(function() {

  //fancybox js
  $('.fancybox-media').fancybox({
    openEffect  : 'fade',
    closeEffect : 'fade',
    helpers : {
      media : true
    }
  });

  //nivoslider js
  $('#slider').nivoSlider({
    effect: 'boxRain',
    directionNav: false
  });

  // donation form
  $('#donate_form').find('input').placeholder();

  $('.make_a_donation a').fancybox({
    fitToView   : false,
    width       : 590,
    height      : 650,
    maxWidth    : 590,
    maxHeight   : 700,
    autoSize    : false,
    closeClick  : false,
    openEffect  : 'none',
    closeEffect : 'none'
  });

  api_key = (window.location.href.match(/\.org/)) ? 'pk_upGNrD7swVWL4W8K7YmOm7r3StSxI' : 'pk_YGKPBqygLNgjsj7WNnIhZ2Imgq7Gn';
  Stripe.setPublishableKey(api_key);                 // live                              // test

  function addInputNames() {
    // Not ideal, but jQuery's validate plugin requires fields to have names
    // so we add them at the last possible minute, in case any javascript
    // exceptions have caused other parts of the script to fail.
    $(".card-number").attr("name", "card-number");
    $(".card-cvc").attr("name", "card-cvc");
    $(".card-expiry-month").attr("name", "card-expiry-month");
    $(".card-expiry-year").attr("name", "card-expiry-year");
  }

  function removeInputNames() {
    $(".card-number").removeAttr("name");
    $(".card-cvc").removeAttr("name");
    $(".card-expiry-month").removeAttr("name");
    $(".card-expiry-year").removeAttr("name");
  }

  function submit(form) {
    // remove the input field names for security
    // we do this *before* anything else which might throw an exception
    removeInputNames(); // THIS IS IMPORTANT!

    // given a valid form, submit the payment details to stripe
    $(form['submit-button']).attr("disabled", "disabled")

    Stripe.createToken({
      number: $('.card-number').val(),
      cvc: $('.card-cvc').val(),
      exp_month: $('.card-expiry-month').val(),
      exp_year: $('.card-expiry-year').val()
    }, function(status, response) {
      if (response.error) {
        // re-enable the submit button
        $(form['submit-button']).removeAttr("disabled");

        // show the error
        $("p.message").addClass('error').html(response.error.message);

        // we add these names back in so we can revalidate properly
        addInputNames();
      } else {
        // token contains id, last4, and card type
        var token = response['id'];

        // insert the stripe token
        var input = $("<input name='stripeToken' value='" + token + "' style='display:none;' />");
        form.appendChild(input[0]);

        // and submit
        // Ajax submission

        $('#submitting').show();
        $('.submit-button').attr('disabled', 'disabled');

        $.post('/donate', {
          'stripeToken'   : token,
          'donor_name'    : $('.donor-name').val(),
          'donor_email'   : $('.donor-email').val(),
          'amount'        : $('.donation-amount').val(),
          'donation_type' : $('input:radio[name=donation_type]:checked').val(),
          'comment'       : $('#comment').val()
        }, function(response) {
          $('label.error').hide();
          $('p.message').html(response.message);

          if(response.message.indexOf('Thank you') == -1) {
            $('p.message').addClass('error');
          } else {
            $('#donate_form form').find('input[type=text]').not('.donation-amount').val('');
            $('p.message').removeClass('error');
          }

          $('.submit-button').removeAttr('disabled');
          $('#submitting').hide();
        }, 'json');
      }
    });

    return false;
  }

  // add custom rules for credit card validating
  jQuery.validator.addMethod("cardNumber", Stripe.validateCardNumber, "Please enter a valid card number");
  jQuery.validator.addMethod("cardCVC", Stripe.validateCVC, "Please enter a valid CVC");
  jQuery.validator.addMethod("cardExpiry", function() {
    return Stripe.validateExpiry($('.card-expiry-month').val(),
                                 $('.card-expiry-year').val());
  }, "Please enter a valid expiration");

  // We use the jQuery validate plugin to validate required params on submit
  $("#payment_form").validate({
    submitHandler: submit,
    rules: {
      "donor_name" : {
        required: true
      },
      "donor_email" : {
        required: true
      },
      "card-cvc" : {
        cardCVC: true,
        required: true
      },
      "card-number" : {
        cardNumber: true,
        required: true
      },
      "card-expiry-year" : "cardExpiry",
      "amount" : {
        required: true
      },
    }
  });

  // adding the input field names is the last step, in case an earlier step errors
  addInputNames();
});
