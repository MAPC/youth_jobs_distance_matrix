require 'test_helper'

class DistanceMatrixClientTest < Minitest::Test

  def setup
    origins = [[42.3485086, -71.1493106]]
    destinations = [[42.3315103,-71.0920196],
                    [42.3549005,-71.0563795],
                    [42.3549005,-71.0563795]]
    @client = DistanceMatrixClient.new(
      origins: origins, destinations: destinations,
      mode: 'transit',  key: 'key' )
    @walk_client = DistanceMatrixClient.new(
      origins: origins, destinations: [destinations.first],
      mode: 'walking', key: 'key'
    )
  end

  def test_params
    expected_options = {
      origins: "42.3485086,-71.1493106",
      destinations: "42.3315103,-71.0920196|42.3549005,-71.0563795|42.3549005,-71.0563795",
      mode: :transit,
      key: "key",
      arrival_time: 1456407900 }
    assert_equal expected_options, @client.options
  end

  def test_params_other
    expected_options = { origins: '42.3485086,-71.1493106',
      destinations: '42.3315103,-71.0920196', mode: :walking, key: 'key' }
    assert_equal expected_options, @walk_client.options
  end

  def test_raise_if_product_too_big
    assert_raises(ProductTooLargeError) do
      DistanceMatrixClient.new(
        origins:      10.times.map{ [0,0] },
        destinations: 11.times.map{ [0,0] },
        mode: 'lol', key: 'irrelevant'
      )
    end
  end

  def test_results
    stub_request(:get, "https://maps.googleapis.com/maps/api/distancematrix/json?arrival_time=1456407900&destinations=42.3315103,-71.0920196%7C42.3549005,-71.0563795%7C42.3549005,-71.0563795&key=key&mode=transit&origins=42.3485086,-71.1493106").
      to_return(status: 200, body: File.read('test/fixtures/ok.json'))
    results = @client.results
    assert results
    assert_equal 'OK', results['status']
  end

  def test_durations
    stub_request(:get, "https://maps.googleapis.com/maps/api/distancematrix/json?arrival_time=1456407900&destinations=42.3315103,-71.0920196%7C42.3549005,-71.0563795%7C42.3549005,-71.0563795&key=key&mode=transit&origins=42.3485086,-71.1493106").
      to_return(status: 200, body: File.read('test/fixtures/ok.json'))
    assert_respond_to @client, :durations
    assert_equal [2228, 1735], @client.durations
  end

  def test_durations_with_no_elements
    stub_request(:get, "https://maps.googleapis.com/maps/api/distancematrix/json?arrival_time=1456407900&destinations=42.3315103,-71.0920196%7C42.3549005,-71.0563795%7C42.3549005,-71.0563795&key=key&mode=transit&origins=42.3485086,-71.1493106").
      to_return(status: 200, body: File.read('test/fixtures/ok_no_results.json'))
    assert_respond_to @client, :durations
    assert_equal [nil, nil], @client.durations
  end

  def test_durations_with_some_elements
    stub_request(:get, "https://maps.googleapis.com/maps/api/distancematrix/json?arrival_time=1456407900&destinations=42.3315103,-71.0920196%7C42.3549005,-71.0563795%7C42.3549005,-71.0563795&key=key&mode=transit&origins=42.3485086,-71.1493106").
      to_return(status: 200, body: File.read('test/fixtures/ok_some_results.json'))
    assert_respond_to @client, :durations
    assert_equal [nil, 1735], @client.durations
  end

  def test_raises_on_top_level_errors
    DistanceMatrixClient::ERRORS.each do |error|
      @client.mode = error
      stub_request(:get, request_url(@client.mode)).
        to_return(status: 200, body: '{"status": "' + error + '"}')
      assert_raises(GoogleApiError) { @client.results }
    end
  end

  def request_url(mode)
    "https://maps.googleapis.com/maps/api/distancematrix/json?destinations=42.3315103,-71.0920196%7C42.3549005,-71.0563795%7C42.3549005,-71.0563795&key=key&mode=#{mode}&origins=42.3485086,-71.1493106"
  end
end
