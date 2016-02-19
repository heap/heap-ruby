require 'helper'

class HeapTest < MiniTest::Test
  def test_heap_app_id
    assert_equal nil,  Heap.app_id
    begin
      Heap.app_id = 'global-app-id'
      assert_equal 'global-app-id', Heap.app_id
    ensure
      Heap.app_id = nil
    end
  end

  def test_heap_stubbed
    assert_equal false, Heap.stubbed
  end

  def test_heap_new
    client = Heap.new :app_id => 'local-app-id', :stubbed => true
    assert_equal 'local-app-id', client.app_id
    assert_equal true, client.stubbed
  end
end
