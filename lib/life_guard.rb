require "life_guard/version"

module LifeGuard
  class Rack
    def initialize(app, opts={})
      @app = app
      @options = opts
      @header_key = @options[:header]
      @lambda = @options[:transformation]
      @failure_message = @options[:failure_message]
      @rails_env = @options[:rails_env]
      @activepoolset = {}
      @current_db_name = get_current_db_name
    end

    def call(env)
      begin
        switch_connection(env[@header_key]) if !env[@header_key].blank?
      rescue 
        return [404, {'Content-Type' => 'text/html'}, ["#{@failure_message}"]]
      else
        return @app.call(env)
      ensure
        change_connection(@current_db_name) if env[@header_key]
      end
    end
private
    def get_current_db_name
      ActiveRecord::Base.configurations.find_db_config(@rails_env).database
    end

    def switch_connection(header)
      new_database_name = @lambda.call(header)
      change_connection(new_database_name)
    end

    def change_connection(db_name)
      ActiveRecord::Base.clear_active_connections!
      # If you ever need to rewrite database names other than primary - e.g. you start using the dw for real
      # Then you'll need to modify this section to rewrite and connect to those dbs as well
      primary = ActiveRecord::Base.configurations.configs_for(env_name: @rails_env, include_replicas: true, name: 'primary')
      primary_replica = ActiveRecord::Base.configurations.configs_for(env_name: @rails_env, include_replicas: true, name: 'primary_replica')
      primary._database = db_name
      primary_replica._database = db_name
      ActiveRecord::Base.establish_connection(primary) # this is magic, it sets a main connection, and the writer, but not the reader
      ActiveRecord::Base.connection.active?
      ActiveRecord::Base.connected_to(role: :reading) do
        ActiveRecord::Base.establish_connection(primary_replica)
        ActiveRecord::Base.connection.active?
      end
    end
  end
end
