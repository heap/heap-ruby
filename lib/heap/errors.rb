# Superclass for all Heap-related errors.
class HeapAPI::Error < RuntimeError
end

# Raised when the Heap API server returns an error response.
class HeapAPI::ApiError < HeapAPI::Error
  # @param [Faraday::Response] response the error response returned by the Heap
  #   analytics server
  def initialize(response)
    @response = response

    super "Heap API server error: #{response.status} #{response.body}"
  end

  # @return [Faraday::Response] response the error response returned by the
  #   Heap analytics server
  attr_reader :response
end
