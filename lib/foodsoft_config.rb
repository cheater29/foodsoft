class FoodsoftConfig
  mattr_accessor :scope, :config
  APP_CONFIG = YAML.load(File.read(File.join(Rails.root, "/config/app_config.yml")))

  class << self

    def init
      # Load initial config from development or production
      set_config Rails.env
      # Overwrite scope to have a better namescope than 'production'
      self.scope = config[:default_scope] or raise "No default_scope is set"
    end

    # Set config and database connection for specific foodcoop
    # Only needed in multi coop mode
    def select_foodcoop(foodcoop)
      set_config foodcoop
      setup_database
    end

    # Provides a nice accessor for config values
    # FoodsoftConfig[:name] # => 'FC Test'
    def [](key)
      config[key]
    end

    # Loop through each foodcoop and executes the given block after setup config and database
    def each_coop
      APP_CONFIG.keys.reject { |coop| coop =~ /^(default|development|test|production)$/ }.each do |coop|
        select_foodcoop coop
        yield coop
      end
    end

    private

    def set_config(foodcoop)
      raise "No config for this environment (#{foodcoop}) available!" if APP_CONFIG[foodcoop].nil?
      self.config = APP_CONFIG[foodcoop].symbolize_keys
      self.scope = foodcoop
    end

    def setup_database
      database_config = ActiveRecord::Base.configurations[Rails.env]
      database_config.merge!(config[:database]) if config[:database].present?
      ActiveRecord::Base.establish_connection(database_config)
    end

  end
end