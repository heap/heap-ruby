# Namespace for all the classes in this gem.
module HeapAPI
  # @return {String} the version of this gem
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip
end

require 'heap/client.rb'
require 'heap/errors.rb'
require 'heap/validations.rb'

# A global instance of {HeapAPI::Client}.
Heap = HeapAPI::Client.new
