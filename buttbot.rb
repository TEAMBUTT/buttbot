require 'mumble-ruby'
require 'slack-notifier'

class ButtBot
  def mumble_url
    ENV['MUMBLE_URL'] || 'localhost'
  end

  def mumble_username
    ENV['MUMBLE_USERNAME'] || 'ButtBot'
  end

  def mumble_channel
    ENV['MUMBLE_CHANNEL'] || '[BUTT]'
  end

  def mumble
    @mumble ||=
      Mumble::Client.new(mumble_url) do |conf|
        conf.username = mumble_username
      end
  end

  def slack_username
    ENV['SLACK_USERNAME'] || 'ButtBot'
  end

  def notifier_url
    ENV['WEBHOOK_URL']
  end

  def notifier
    @notifier ||= Slack::Notifier.new notifier_url, username: slack_username
  end

  def notify message
    notifier.ping message, icon_emoji: ":gremlin:"
  end

  def butt_channel_id
    mumble.channels.values.detect{|c| c.name == mumble_channel }.channel_id
  end

  def butt_users
    butt_channel_id = self.butt_channel_id
    mumble.users.values.select{|u| u.channel_id == butt_channel_id }
  end

  def run
    mumble.on_connected do
      mumble.me.mute
      mumble.me.deafen

      mumble.join_channel(mumble_channel)
    end

    mumble.connect

    last_users = []
    loop do
      sleep 2
      next unless mumble.connected?

      now_users = butt_users.map(&:name)
      now_users -= [mumble_username]

      joined_users = now_users - last_users
      left_users = last_users - now_users

      joined_users.each do |username|
        notify "#{username} is back in the fight"
      end
      left_users.each do |username|
        notify "#{username} was eliminated"
      end

      last_users = now_users
    end
  end
end

ButtBot.new.run
