# Heap Server-Side API Client for Ruby

[![Build Status](https://travis-ci.org/heap/heap-ruby.svg?branch=master)](https://travis-ci.org/heap/heap-ruby)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/heap/heap-ruby/master/frames)
[![Gem Version](https://badge.fury.io/rb/heap.svg)](https://badge.fury.io/rb/heap)

This is a Ruby client for the [Heap](https://heapanalytics.com/)
[server-side API](https://heapanalytics.com/docs/server-side).


## Prerequisites

This gem is tested on Ruby 1.8.7 and above.


## Installation

If you're using [bundler](http://bundler.io/), add the following line to your
[Gemfile](http://bundler.io/v1.11/gemfile.html).

```ruby
gem 'heap', '~> 1.0'
```

Otherwise, install the [heap](https://rubygems.org/gems/heap) gem and activate
it in your code manually.

```bash
gem install heap
```

```ruby
require 'heap'
```


## Setup

Place the following code in a file that executes when your application
initializes.

```ruby
Heap.app_id = 'YOUR_APP_ID'
```

In a Ruby on Rails application, place the following snippet in an initializer,
such as `config/initializers/heap.rb`.

```ruby
if Rails.env.production?
  Heap.app_id = 'YOUR_APP_ID'
else
  Heap.app_id = 'YOUR_DEV_APP_ID'
end
```

In some testing environments, connecting to outside servers is undesirable. Set
the `stubbed` accessor to `true` to have all API calls succeed without
generating any network traffic.

```ruby
class StubbedHeapTest < MiniTest::Test
  def setup
    Heap.stubbed = true
  end

  def teardown
    Heap.stubbed = false
  end

  ...
end
```


## Usage

[Track](https://heapanalytics.com/docs/server-side#track) a server-side event.
The properties are optional.

```ruby
Heap.track 'user-handle', 'event-name', property: 'value'
```

[Add properties](https://heapanalytics.com/docs/server-side#identify) to a
user.

```ruby
Heap.add_user_properties 'user-handle', plan: 'premium1'
```

If the global API client instance stored in `Heap` is not a good fit for your
application's architecture, create your own client instances.

```ruby
heap_client = Heap.new app_id: 'YOUR_APP_ID'
heap_client.track 'user-handle', 'event-name', property: 'value'
```


## Legacy Gem Releases

Gem versions below 1.0 come from
[this repository](https://github.com/HectorMalot/heap), which is an entirely
different codebase. We are very grateful to
[@HectorMalot](https://github.com/HectorMalot) for donating the `heap` gem name
to us.

If you are using a pre-1.0 gem, please consider upgrading to an officially
supported release. In the meantime, you can pin the old version in your
`Gemfile`.

```ruby
gem 'heap', '~> 0.3'
```


## Copyright

Copyright (c) 2016 Heap Inc., released under the MIT license.
