require 'httparty'
require 'twitter'
require 'nokogiri'
require 'json'

class FiveThirtyEightBot
  attr_reader :twitter_client

  def initialize
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = ENV["ACCESS_TOKEN"]
      config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
    end
  end

  def tweet_if_new_forecast
    twitter_client.update(current_forecast) unless last_tweet_contains_current_forecast?
  end

  private

  def last_tweet_contains_current_forecast?
    last_tweet_with_a_forecast.include?(hillary_polls_only) and last_tweet_with_a_forecast.include?(donald_polls_only) and last_tweet_with_a_forecast.include?(hillary_polls_plus) and last_tweet_with_a_forecast.include?(donald_polls_plus) and last_tweet_with_a_forecast.include?(hillary_polls_now) and last_tweet_with_a_forecast.include?(donald_polls_now)
  end

  def last_tweet_with_a_forecast
    tweets = twitter_client.user_timeline
    tweets.each do |tweet|
      return tweet.text unless tweet.text[0] == '@'
    end
  end

  def current_forecast
    <<END
Forecast Model Update
(Hillary vs. Donald)
#{polls_plus_string}
#{polls_only_string}
#{now_cast_string}
https://projects.fivethirtyeight.com/2016-election-forecast/
END
  end

  def hillary_polls_only
    forecast_for("polls", "D").to_s
  end

  def donald_polls_only
    forecast_for("polls", "R").to_s
  end

  def polls_only_string
    "Polls-only: #{hillary_polls_only}%-#{donald_polls_only}%"
  end

  def hillary_polls_plus
    forecast_for("plus", "D").to_s
  end

  def donald_polls_plus
    forecast_for("plus", "R").to_s
  end

  def polls_plus_string
    "Polls-plus: #{hillary_polls_plus}%-#{donald_polls_plus}%"
  end

  def hillary_polls_now
    forecast_for("now", "D").to_s
  end

  def donald_polls_now
    forecast_for("now", "R").to_s
  end

  def now_cast_string
    "Now-cast: #{hillary_polls_now}%-#{donald_polls_now}%"
  end

  def forecast_for(model, party)
    data_hash[party]["models"][model]["winprob"].round(1)
  end

  def page_source
    @ps ||= HTTParty.get('https://projects.fivethirtyeight.com/2016-election-forecast/')
  end

  def data_hash
    extracted_json = page_source.body.match(/race\.stateData = (.+)\;/).captures.first
    parsed_json = JSON.parse(extracted_json)
    @dh ||= parsed_json["forecasts"]["latest"]
  end
end
