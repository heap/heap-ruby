require 'faraday'
require 'faraday_middleware'

# This is the class of the Heap object.
class HeapAPI::Client
  # @return [String] the Heap application ID from
  #   https://heapanalytics.com/app/install
  attr_accessor :app_id

  # @return [Boolean] if true, all the requests to the Heap API are stubbed to
  #   return successfully; this overrides the Faraday-related options
  attr_reader :stubbed

  # @return [Symbol] the Faraday adapter used by the Heap API server connection
  # @see http://www.rubydoc.info/gems/faraday/
  attr_reader :faraday_adapter

  # @return [Array] arguments to the Faraday adapter used by the Heap API
  #   server connection
  attr_reader :faraday_adapter_args

  # @return [String] the User-Agent header value
  attr_accessor :user_agent

  # Creates a new client for the Heap server-side API.
  #
  # For simplicity, consider using the global client instance referenced by the
  # Heap constant instead of creating and managing new instances.
  #
  # @param [Hash<Symbol, Object>] options initial values for attributes
  # @option options [String] app_id the Heap application ID from
  #   https://heapanalytics.com/app/install
  # @option options [Hash<Symbol, Object>] js_options default heap.js advanced
  #   options
  # @option options [Boolean] stubbed if true, all the requests to the Heap API
  #   are stubbed to return successfully; this overrides the Faraday-related
  #   options
  # @option options [Symbol] faraday_adapter the Faraday adapter used by the
  #   Heap API server connection
  # @option options [Array] faraday_adapter_args arguments to the Faraday
  #   adapter used by the Heap API server connection
  def initialize(options = {})
    @app_id = nil
    @live_connection = nil
    @stubbed_connection = false
    @stubbed = false
    @faraday_adapter = Faraday.default_adapter
    @faraday_adapter_args = []
    @user_agent = "heap-ruby/#{HeapAPI::VERSION} " +
        "faraday/#{Faraday::VERSION} ruby/#{RUBY_VERSION} (#{RUBY_PLATFORM})"

    options.each do |key, value|
      self.send :"#{key}=", value
    end
  end

  def stubbed=(new_value)
    @connection = nil
    @stubbed = new_value
  end

  def faraday_adapter=(new_adapter)
    raise RuntimeError, 'Faraday connection already initialized' if @connection
    @faraday_adapter = new_adapter
  end

  def faraday_adapter_args=(new_args)
    raise RuntimeError, 'Faraday connection already initialized' if @connection
    unless new_args.instance_of? Array
      raise ArgumentError, "Arguments must be an Array"
    end
    @faraday_adapter_args = new_args
  end

  # Assigns custom properties to an existing user.
  #
  # @param [String] identity an e-mail, handle, or Heap-generated user ID
  # @param [Hash<String, String|Number>] properties key-value properties
  #   associated with the event; each key must have fewer than 1024 characters;
  #   each value must be a Number or String with fewer than 1024 characters
  # @return [HeapAPI::Client] self
  # @see https://heapanalytics.com/docs/server-side#add-user-properties
  def add_user_properties(identity, properties)
    ensure_valid_app_id!
    ensure_valid_identity! identity
    ensure_valid_properties! properties

    body = {
      :app_id => @app_id,
      :identity => identity.to_s,
      :properties => properties,
    }
    response = connection.post '/api/add_user_properties', body,
        'User-Agent' => user_agent
    raise HeapAPI::ApiError.new(response) unless response.success?
    self
  end

  # Sends a custom event to the Heap API servers.
  #
  # @param [String] event the name of the server-side event; limited to 1024
  #   characters
  # @param [String] identity an e-mail, handle, or Heap-generated user ID
  # @param [Hash<String, String|Number>] properties key-value properties
  #   associated with the event; each key must have fewer than 1024 characters;
  #   each value must be a Number or String with fewer than 1024 characters
  # @return [HeapAPI::Client] self
  # @see https://heapanalytics.com/docs/server-side#track
  def track(event, identity, properties = nil)
    ensure_valid_app_id!

    event_name = event.to_s
    ensure_valid_event_name! event_name
    ensure_valid_identity! identity

    body = {
      :app_id => @app_id,
      :identity => identity.to_s,
      :event => event,
    }
    unless properties.nil?
      body[:properties] = properties
      ensure_valid_properties! properties
    end

    response = connection.post '/api/track', body,
        'User-Agent' => user_agent
    raise HeapAPI::ApiError.new(response) unless response.success?
    self
  end

  # The underlying Faraday connection used to make HTTP requests.
  #
  # @return [Faraday::Connection] a Faraday connection object
  def connection
    @connection ||= @stubbed ? stubbed_connection : live_connection
  end

  # The Faraday connection used to make HTTP requests to the Heap API server.
  #
  # This is used when {#stubbed?} is false.
  #
  # @return [Faraday::Connection] a Faraday connection object
  def live_connection
    @live_connection ||= live_connection!
  end
  private :live_connection

  # The Faraday connection that stubs API calls to the Heap servers.
  #
  # This is used when {#stubbed?} is true.
  #
  # @return [Faraday::Connection] a Faraday connection object
  def stubbed_connection
    @stubbed_connection ||= stubbed_connection!
  end
  private :stubbed_connection

  # Creates a new Faraday connection to the Heap API server.
  #
  # @return [Faraday::Connection] a Faraday connection object
  def live_connection!
    Faraday.new 'https://heapanalytics.com' do |c|
      c.request :json
      c.adapter @faraday_adapter, *@faraday_adapter_args
    end
  end
  private :live_connection!

  # Creates a new Faraday connection that stubs API calls to the Heap servers.
  #
  # @return [Faraday::Connection] a Faraday connection object
  def stubbed_connection!
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('/api/add_user_properties') { |env| [204, {}, ''] }
      stub.post('/api/track') { |env| [204, {}, ''] }
    end

    Faraday.new 'https://heapanalytics.com' do |c|
      c.request :json
      c.adapter :test, stubs
    end
  end
  private :stubbed_connection!

  # Creates a new client instance.
  #
  # This is defined here so `Heap.new` can be used as a shorthand for
  # `HeapAPI::Client.new`.
  #
  # @see {HeapAPI::Client#initialize}
  def new(*args)
    HeapAPI::Client.new(*args)
  end
end
