#!/usr/bin/env ruby

require 'discordrb'

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], client_id: ENV['DISCORD_ID'], prefix: '!'

bot.command :vs do |event, vs, *fr|
  vs = vs.to_i

  roll = rand(100)

  case roll
  when 0
    crit = true
    success = true
    diff = [vs - roll, 0].max
  when 99
    crit = true
    success = false
    diff = (vs - roll).abs
  else
    crit = roll.to_s[0] == roll.to_s[1]
    success = roll <= vs
    diff = (vs - roll).abs
  end

  sig = diff > 30

  res = "#{event.author.display_name} rolled `#{roll}` against `#{vs}`" +
        "#{fr.empty? ? "" : " for \"#{fr.join(' ')}\""}. " +
        "That is a _#{sig ? "significant " : ""}#{crit ? "**critical** " : ""}#{success ? "success" : "failure"}_ " +
        "by `#{diff}` (#{diff / 10} Mo#{success ? "S" : "F"})."

  puts res
  res
end

bot.run
