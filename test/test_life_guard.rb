require 'minitest_helper'

class TestLifeGuard < Minitest::Test
  class Dummy
    def call(env)
      @result = ActiveRecord::Base.connection.execute("select * from foo")
      ActiveRecord::Base.connected_to(role: :reading) do
        @reader_result = ActiveRecord::Base.connection.execute("select * from foo")
      end
    end
    def result
      @result
    end
    def reader_result
      @reader_result
    end
  end

  def setup
    @dummy_app = Dummy.new
    ActiveRecord::Base.configurations = { 'test' => {
                                            'primary' => { 'adapter' => 'sqlite3', 'database' => 'test/db/test.db' },
                                            'primary_replica' => { 'adapter' => 'sqlite3', 'database' => 'test/db/test.db', 'replica' => true }
                                        } }
    ActiveRecord::Base.establish_connection(:test)
    db_config = ActiveRecord::Base.configurations.configs_for(env_name: 'test', include_replicas: true, name: 'primary_replica')
    ActiveRecord::Base.connected_to(role: :reading) do
      ActiveRecord::Base.establish_connection(db_config)
    end
    proc = Proc.new do |header| 
      new_database = "test/db/test_#{header}.db"
      new_database
    end
    @lifeguard = LifeGuard::Rack.new(@dummy_app, { :header => "HTTP_FOO", :transformation => proc, :rails_env => 'test'})
  end

  def teardown
  end

  def test_that_it_has_a_version_number
    refute_nil ::LifeGuard::VERSION
  end

  def test_it_does_nothing_with_no_headers
    @lifeguard.call({})
    assert_equal "main", @dummy_app.result.first["bar"]
    assert_equal "main", @dummy_app.reader_result.first["bar"]
  end

  def test_it_does_nothing_with_empty_headers
    @lifeguard.call({"HTTP_FOO" => ""})
    assert_equal "main", @dummy_app.result.first["bar"]
    assert_equal "main", @dummy_app.reader_result.first["bar"]
  end

  def test_it_switches_connection
    @lifeguard.call({'HTTP_FOO' => "alt"})
    assert_equal "alt", @dummy_app.result.first["bar"]
    assert_equal "alt", @dummy_app.reader_result.first["bar"]
  end

  def test_it_resets_connection_after
    @lifeguard.call({'HTTP_FOO' => "alt"})
    assert_equal "alt", @dummy_app.result.first["bar"]
    assert_equal "alt", @dummy_app.reader_result.first["bar"]
    assert_equal "main", ActiveRecord::Base.connection.execute("select * from foo").first["bar"]
    ActiveRecord::Base.connected_to(role: :reading) do
      assert_equal "main", ActiveRecord::Base.connection.execute("select * from foo").first["bar"]
    end
  end
end
