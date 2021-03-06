require 'test_helper'

class RunTaskTest < Minitest::Test

  def setup
    @key = ApiKey.create!
    @travel_time = TravelTime.create!
    @job = RunTask.new
  end

  def teardown
    @key.destroy!
    @travel_time.destroy!
  end

  def test_boot_claims_a_key
    assert_empty ApiKey.claimed
    before = ApiKey.claimed.count
    @job.boot!
    after = ApiKey.claimed.count
    assert_equal 1, (after - before)
  end

  def test_boot_raises_if_no_free_keys
    ApiKey.find_each {|k| k.update_attribute(:claimed, true)}
    assert_raises(NoAvailableKeyError) { @job.boot! }
  end

  def test_teardown_releases_key
    @job.boot!
    before = ApiKey.claimed.count
    @job.teardown!
    after = ApiKey.claimed.count
    assert_equal(-1, (after - before))
  end

  def test_perform_adds_a_time
    skip
    refute TravelTime.first.time
    @job.perform!
    assert TravelTime.first.time
  end

  def test_perform_assigns_times
    # Once we have the mock requests
    # assert_equal 1704107, TravelTime.first.time
    skip
  end

  def test_perform_claims_all_waitlisters
    assert_equal Waitlist.all.count, Waitlist.claimed.count
  end

  def test_releases_key_when_interrupted
    skip 'Signal processing'
  end

  def test_perform_releases_key_at_end
    before = ApiKey.claimed.count
    @job.perform!
    after = ApiKey.claimed.count
    assert_equal after, before
  end
end
