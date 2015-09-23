require 'minitest_helper'
require 'pry'

class TestLifeGuard < Minitest::Test
  class Dummy
    def call(env)
      @result = ActiveRecord::Base.connection.execute("select * from foo")
    end
    def result
      @result
    end
  end



  def setup
    @dummy_app = Dummy.new
    ActiveRecord::Base.configurations = { 'test' => {'adapter' => 'sqlite3', 'database' => 'test/db/test.db'} }
    ActiveRecord::Base.establish_connection(:test)
    proc = Proc.new do |config, header| 
      config['test']['database'] = config['test']['database'].gsub(/test\./, "test_#{header}.")
      config
    end
    @lifeguard = LifeGuard::Rack.new(@dummy_app, { :header => "HTTP_FOO", :transformation => proc})
  end

  def teardown
  end

  def test_that_it_has_a_version_number
    refute_nil ::LifeGuard::VERSION
  end

  def test_it_does_nothing_with_no_headers
    @lifeguard.call({})
    assert_equal "bar", @dummy_app.result.first["bar"]
  end

  def test_it_does_nothing_with_empty_headers
    @lifeguard.call({"HTTP_FOO" => ""})
    assert_equal "bar", @dummy_app.result.first["bar"]
  end

  def test_it_switches_connection
    @lifeguard.call({'HTTP_FOO' => "alt"})
    assert_equal "foobar", @dummy_app.result.first["bar"]
  end

  def test_it_resets_connection_after
    @lifeguard.call({'HTTP_FOO' => "alt"})
    assert_equal "foobar", @dummy_app.result.first["bar"]
    ActiveRecord::Base.establish_connection(:test)
    assert_equal "bar", ActiveRecord::Base.connection.execute("select * from foo").first["bar"]
  end

  def test_it_returns_404_if_no_connection
    proc = Proc.new do |config, header| 
      config['test']['database'] = config['test']['database'].gsub(/test\./, "/foo/bar/bar/foobar_#{header}.")
      config
    end
    @lifeguard = LifeGuard::Rack.new(@dummy_app, { :header => "HTTP_FOO", 
      :failure_message => "foo", :transformation => proc})
    result = @lifeguard.call({'HTTP_FOO' => "alt"})
    assert_equal nil, @dummy_app.result
    assert_equal result, [404, {'Content-Type' => 'text/html'}, ["foo"]]
  end
end
