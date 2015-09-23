require "life_guard/version"

module LifeGuard
  class Rack
    def initialize(app, opts={})
      @app = app
      @options = opts
      @header_key = @options[:header]
      @lambda = @options[:transformation]
      @failure_message = @options[:failure_message]
      @activepoolset = {}
      @config = ActiveRecord::Base.configurations.deep_dup
    end

    def call(env)
      begin
        if env[@header_key]
          switch_connection(env[@header_key])
        end
        return @app.call(env)
      rescue 
        [404, {'Content-Type' => 'text/html'}, ["#{@failure_message}"]]
      ensure 
        reset_connection if env[@header_key]
      end
    end
private
    def switch_connection(header)
      modified_config = @lambda.call(@config.deep_dup, header)
      ActiveRecord::Base.clear_active_connections!
      ActiveRecord::Base.configurations = modified_config
      ActiveRecord::Base.establish_connection
    end

    def reset_connection
      ActiveRecord::Base.configurations = @config
    end
  end
end