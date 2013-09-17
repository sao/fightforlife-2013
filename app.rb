class FightForLifeApp < Sinatra::Application

  set :root, File.dirname(__FILE__)

  register Sinatra::AssetPack

  assets {
    serve '/js',     from: 'app/js'        # Optional
    serve '/css',    from: 'app/css'       # Optional
    serve '/images', from: 'app/images'    # Optional

    js :app, '/js/app.js', [
      '/js/vendor/jquery-1.9.1.min.js',
      '/js/vendor/jquery.fancybox.min.js',
      '/js/vendor/helpers/jquery.fancybox-media.js',
      '/js/vendor/jquery.nivo.min.js',
      '/js/vendor/jquery.placeholder.min.js',
      '/js/main.js'
    ]

    css :application, '/css/application.css', [
      '/css/screen.css'
    ]

    js_compression  :jsmin      # Optional
    css_compression :sass       # Optional

    serve '/js', from: '/app/js'
  }

  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.sendgrid.net',
      :port => '587',
      :domain => 'heroku.com',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password => ENV['SENDGRID_PASSWORD'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }


  def current_page
    slug = request.path_info[1..-1]
    if slug =~ /-/
      slug.gsub!('-',' ').split(/(\W)/).map(&:capitalize).join
    else
      slug.split(/(\W)/).map(&:capitalize).join
    end
  end

end

require_relative 'routes/init'
