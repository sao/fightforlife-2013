class FightForLifeApp < Sinatra::Application

  get '/' do
    video_ids = [60304979, 60298107, 53625305, 29353379, 29347790, 29300070, 29255488, 29256129]
    @videos   = video_ids.collect { |id| Vimeo::Simple::Video.info(id).first }
    erb :index
  end

  get '/donate' do
    erb :donate
  end

  post '/donate' do
    api_key = ENV['STRIPE_SECRET_KEY']
    Stripe.api_key = api_key

    amount = (params[:amount].gsub(/\$/, '').to_f * 100).to_i  # convert amount to cents
    token  = params[:stripeToken]

    begin
      customer = Stripe::Customer.create(
        email: params[:donor_email],
        description: params[:donor_name],
        card: token
      )
      response = Stripe::Charge.create(
        currency:    "usd",
        description: "Donation via Fight for Life website",
        amount:      amount,
        customer:    customer.id
      )
    rescue Exception => e
      message  = e.message
      response = nil
    end

    if response
      if params[:donor_email] != ""
        if params[:donor_name] != ""
          email = "#{params[:donor_name]} <#{params[:donor_email]}>"
        else
          email = params[:donor_email]
        end

        if params[:donation_type] == "monthly"
          plan_name = "#{params[:donor_name]} - Monthly Donation Plan"

          Stripe::Plan.create(
            :amount => amount,
            :interval => 'month',
            :name => plan_name,
            :currency => 'usd',
            :id => customer.id
          )
          customer.update_subscription(:plan => customer.id)
        end

        if params[:comment] != ""
          body =
          <<-BODY
          Someone that has made a donation also added a comment to it. You can see this below:

          Donor's Name: #{params[:donor_name]}
          Donor's Email: #{params[:donor_email]}

          Comment:
          #{params[:comment]}
          BODY

          Pony.mail(:to => ENV['DONATION_EMAIL'], :subject => 'Donor Comments', :from => params[:donor_email], :body => body)
        end
      end

      message ||= if response.failure_message.nil?
        "Thank you for your donation! Every dollar makes a difference!"
      else
        "There was a problem submitting your donation. #{response.failure_message}"
      end
    end

    "{ \"message\" : \"#{message}\" }"
  end

  get '/about' do
    erb :about
  end

  get '/partners' do
    erb :partners
  end

  get '/community' do
    erb :community
  end

  get '/events' do
    erb :events
  end

  get '/media' do
    erb :media
  end

  get '/contact' do
    @errors = []
    erb :contact
  end

  post '/send' do
    body =
    <<-BODY
    Contact Inquiry

    Name: #{params[:name]}
    Email: #{params[:email]}
    Phone: #{params[:phone]}

    Message:
    #{params[:message]}
    BODY

    @errors   = []
    required = [:name, :email, :phone, :message]
    required.each do |field|
      if params[field].empty?
        @errors << field
      end
    end

    if !@errors.empty?
      @required_class = ' class="required"'
      erb :contact
    else
      Pony.mail(:to => ENV['CONTACT_EMAIL'], :subject => 'Website Inquiry', :from => params[:email], :body => body)
      erb :thank_you
    end
  end

  get '/stories' do
    @videos = Vimeo::Simple::User.videos("fightforlife")
    erb :stories
  end

  get '/get-involved' do
    erb :get_involved
  end

  not_found do
    status 404
    redirect('/')
  end
end
