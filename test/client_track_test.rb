require 'helper'

class ClientTrackTest < MiniTest::Test
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new do |stub|
    end
    @heap = HeapAPI::Client.new
    @heap.app_id = 'test-app-id'
    @heap.faraday_adapter = :test
    @heap.faraday_adapter_args = [@stubs]
  end

  def teardown
    @stubs.verify_stubbed_calls
  end

  def test_track_without_app_id
    @heap.app_id = nil
    exception = assert_raises RuntimeError do
      @heap.track 'test_track_without_app_id', 'test-identity'
    end
    assert_equal RuntimeError, exception.class
    assert_equal 'Heap app_id not set', exception.message
  end

  def test_track_without_event_name
    exception = assert_raises ArgumentError do
      @heap.track '', 'test-identity'
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Missing or empty event name', exception.message
  end

  def test_track_with_long_event_name
    exception = assert_raises ArgumentError do
      @heap.track 'A' * 1025, 'test-identity'
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Event name too long', exception.message
  end

  def test_track_with_long_string_identity
    long_identity = 'A' * 256

    exception = assert_raises ArgumentError do
      @heap.track 'some-event', long_identity
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Identity field too long; " +
        '256 is above the 255-character limit', exception.message
  end

  def test_track_with_long_symbol_identity
    long_identity = ('A' * 256).to_sym

    exception = assert_raises ArgumentError do
      @heap.track 'some-event', long_identity
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Identity field too long; " +
        '256 is above the 255-character limit', exception.message
  end

  def test_track_with_array_identity
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_array_property_value', []
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Unsupported type for identity value []', exception.message
  end

  def test_track_with_invalid_property_object
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_long_property_name', 'test-identity', false
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Properties object does not implement #each',
        exception.message
  end

  def test_track_with_long_property_name
    long_name = 'A' * 1025
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_long_property_name', 'test-identity',
          long_name => 'value'
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property name #{long_name} too long; " +
        "1025 is above the 1024-character limit", exception.message
  end

  def test_track_with_long_string_property_value
    long_value = 'A' * 1025
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_long_string_property_value',
          'test-identity', 'long_value_name' => long_value
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property long_value_name value \"#{long_value}\" too " +
        'long; 1025 is above the 1024-character limit', exception.message
  end

  def test_track_with_long_symbol_property_value
    long_value = ('A' * 1025).to_sym
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_long_symbol_property_value',
          'test-identity', 'long_value_name' => long_value
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Property long_value_name value :#{long_value} too long; " +
        '1025 is above the 1024-character limit', exception.message
  end

  def test_track_with_array_property_value
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_array_property_value', 'test-identity',
          'array_value_name' => []
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Unsupported type for property array_value_name value []',
        exception.message
  end

  def test_track_with_non_date_timestamp
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_array_property_value', 'test-identity', {}, :timestamp => 'foobar'
    end
    assert_equal ArgumentError, exception.class
    assert_equal "Unsupported timestamp format #{"foobar".inspect}. Must be iso8601 or unix epoch milliseconds.",
        exception.message
  end

  def test_track_with_array_timestamp
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_array_property_value', 'test-identity', {}, :timestamp => []
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Unsupported timestamp format []. Must be iso8601 or unix epoch milliseconds.',
        exception.message
  end

  def test_track_with_array_idempotency_key
    exception = assert_raises ArgumentError do
      @heap.track 'test_track_with_array_property_value', 'test-identity', {}, :idempotency_key => []
    end
    assert_equal ArgumentError, exception.class
    assert_equal 'Unsupported idempotency key format for []. Must be string or integer',
        exception.message
  end

  def test_track
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-identity',
        'event' => 'test_track',
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track', 'test-identity')
  end

  def test_track_with_integer_identity
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => '123456789',
        'event' => 'test_track',
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track', 123456789)
  end

  def test_track_with_properties
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-identity',
        'event' => 'test_track_with_properties',
        'properties' => { 'foo' => 'bar', 'heap' => 'hurray' }
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track_with_properties',
        'test-identity','foo' => 'bar', :heap => :hurray)
  end

  def test_track_with_timestamp
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-identity',
        'event' => 'test_track_with_timestamp',
        'properties' => {},
        'timestamp' => '1524038400000'
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track_with_timestamp',
      'test-identity', {}, :timestamp => Time.parse("2018-04-18 08:00:00 UTC"))
  end

  def test_track_with_iso8601_timestamp
    timestamp = "2018-04-18T22:42:38+03:00"
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-identity',
        'event' => 'test_track_with_iso8601_timestamp',
        'properties' => {},
        'timestamp' => timestamp
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track_with_iso8601_timestamp',
      'test-identity', {}, :timestamp => timestamp)
  end

  def test_track_with_idempotency_key
    @stubs.post '/api/track' do |env|
      golden_body = {
        'app_id' => 'test-app-id',
        'identity' => 'test-identity',
        'event' => 'test_track_with_idempotency_key',
        'properties' => {},
        'idempotency_key' => 'foobar35214532512'
      }
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal @heap.user_agent, env[:request_headers]['User-Agent']
      assert_equal golden_body, JSON.parse(env[:body])

      [200, { 'Content-Type' => 'text/plain; encoding=utf8' }, '']
    end

    assert_equal @heap, @heap.track('test_track_with_idempotency_key',
      'test-identity', {}, :idempotency_key => 'foobar35214532512')
  end

  def test_track_error
    @stubs.post '/api/track' do |env|
      [400, { 'Content-Type' => 'text/plain; encoding=utf8' }, 'Bad request']
    end

    exception = assert_raises HeapAPI::Error do
      @heap.track('test-identity', 'test_track')
    end
    assert_equal HeapAPI::ApiError, exception.class
    assert_equal 'Heap API server error: 400 Bad request', exception.message
    assert_kind_of Faraday::Response, exception.response
    assert_equal 400, exception.response.status
  end

  def test_track_integration
    @heap.app_id = '3000610572'
    @heap.faraday_adapter = :net_http
    @heap.faraday_adapter_args = []

    assert_equal @heap, @heap.track('test_track_integration', 'test-identity',
        'language' => 'ruby', 'project' => 'heap/heap-ruby')
  end

  def test_track_error_integration
    @heap.faraday_adapter = :net_http
    @heap.faraday_adapter_args = []

    assert_raises HeapAPI::Error do
      @heap.track('test_track_integration', 'test-identity',
          'language' => 'ruby', 'project' => 'heap/heap-ruby')
    end
  end


  def test_track_with_stubbed_connection
    @heap.stubbed = true

    assert_equal @heap, @heap.add_user_properties('test-identity',
        'foo' => 'bar', :heap => :hurray)
  end
end
