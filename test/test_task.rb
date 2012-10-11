require 'test/unit'
require 'tmpdir'

require 'sprockets'
require 'sprockets/rails/task'

class TestTask < Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

  def setup
    @rake = Rake::Application.new
    Rake.application = @rake

    @assets = Sprockets::Environment.new
    @assets.append_path FIXTURES_PATH

    @dir = File.join(Dir::tmpdir, 'rails/task')

    @manifest = Sprockets::Manifest.new(@assets, @dir)

    # Stub Rails environment task
    @rake.define_task Rake::Task, :environment do
    end

    Sprockets::Rails::Task.new do |t|
      t.environment = @assets
      t.manifest    = @manifest
      t.assets      = ['foo.js']
      t.log_level   = :fatal
    end
  end

  def teardown
    Rake.application = nil

    FileUtils.rm_rf(@dir)
    assert Dir["#{@dir}/*"].empty?
  end

  def test_precompile
    digest_path = @assets['foo.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:precompile'].invoke

    assert Dir["#{@dir}/manifest-*.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  def test_clobber
    digest_path = @assets['foo.js'].digest_path

    @rake['assets:precompile'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:clobber'].invoke
    assert !File.exist?("#{@dir}/#{digest_path}")
  end

  def test_clean
    digest_path = @assets['foo.js'].digest_path

    @rake['assets:precompile'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")

    @rake['assets:clean'].invoke
    assert File.exist?("#{@dir}/#{digest_path}")
  end
end
