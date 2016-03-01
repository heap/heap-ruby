require 'helper'

class ClientTest < MiniTest::Test
  def setup
    @heap = HeapAPI::Client.new
  end

  def test_default_app_id
    assert_equal nil, @heap.app_id
  end

  def test_default_stubbed
    assert_equal false, @heap.stubbed
  end

  def test_default_faraday_adapter
    assert_equal Faraday.default_adapter, @heap.faraday_adapter
  end

  def test_default_faraday_adapter_args
    assert_equal([], @heap.faraday_adapter_args)
  end

  def test_faraday_adapter_args_setter
    stubs = Faraday::Adapter::Test::Stubs.new
    @heap.faraday_adapter_args = [stubs]
    assert_equal([stubs], @heap.faraday_adapter_args)

    @heap.faraday_adapter = :test
    @heap.connection  # Materialize the Faraday connection.
    exception = assert_raises RuntimeError do
      @heap.faraday_adapter_args = [:derp]
    end
    assert_equal RuntimeError, exception.class
    assert_equal 'Faraday connection already initialized', exception.message
    assert_equal [stubs], @heap.faraday_adapter_args
  end

  def test_faraday_adapter_args_setter_with_invalid_value
    exception = assert_raises ArgumentError do
      @heap.faraday_adapter_args = false
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Arguments must be an Array', exception.message
  end

  def test_stubbed_setter
    @heap.app_id = 'test-app-id'
    @heap.faraday_adapter = :net_http

    @heap.stubbed = true
    assert_equal @heap, @heap.track('test_stubbed_setter', 'test-identity',
        'language' => 'ruby', 'project' => 'heap/heap-ruby')
    stubbed_connection = @heap.connection

    @heap.stubbed = false
    assert_raises HeapAPI::Error do
      @heap.track 'test_stubbed_setter', 'test-identity',
          'language' => 'ruby', 'project' => 'heap/heap-ruby'
    end
    live_connection = @heap.connection

    @heap.stubbed = true
    assert_equal stubbed_connection, @heap.connection

    @heap.stubbed = false
    assert_equal live_connection, @heap.connection
  end

  def test_default_user_agent
    assert_match(/^heap-ruby\/[0-9.]+ /, @heap.user_agent)
    assert_match(/ faraday\/[0-9.]+ /, @heap.user_agent)
    assert_match(/ ruby\/[0-9.]+ \(.+\)$/, @heap.user_agent)
  end

  def test_user_agent_setter
    @heap.user_agent = 'sparky/4.2'
    assert_equal 'sparky/4.2', @heap.user_agent
  end

  def test_constructor_options
    heap = Heap.new :app_id => 'test-app-id', :stubbed => true
    assert_equal 'test-app-id', heap.app_id
    assert_equal true, heap.stubbed
  end
end
