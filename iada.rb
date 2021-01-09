#!/usr/bin/env ruby

require 'discordrb'

def human_result(name, roll, vs, fr, prefix = "")
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

  sig = diff >= 30

  prefix + "#{name} rolled `#{roll}` against `#{vs}`" +
    "#{fr.empty? ? "" : " for \"#{fr.join(' ')}\""}. " +

    "That is #{(!crit && sig && success) ? "an" : "a"} " +
    "_#{crit ? "**critical** " : ""}" +
    "#{sig ? (success ? "excellent " : "severe ") : ""}" +
    "#{success ? "success" : "failure"}_ " +

    "by `#{diff}` (#{diff / 10} Mo#{success ? "S" : "F"})."
end

last_roll = {}

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], client_id: ENV['DISCORD_ID'], prefix: '!'

bot.command(:vs, description: "Roll a d100 (0-99) against a target number, with optional comment.") do |event, vs, *fr|
  vs = vs.to_i
  roll = rand(100)

  last_roll[event.author.id] = [roll, vs, fr]

  res = human_result(event.author.display_name, roll, vs, fr)
  puts res
  res
end

bot.command(:again, description: "Repeat your last vs roll.") do |event|
  roll, vs, fr = last_roll[event.author.id]

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  else
    roll = rand(100)
    last_roll[event.author.id] = [roll, vs, fr]

    res = human_result(event.author.display_name, roll, vs, fr, "Repeat: ")
  end

  puts res
  res
end

bot.command(:moxie, description: "Perform a moxie digit swap on your last vs roll.") do |event|
  roll, vs, fr = last_roll[event.author.id]

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  else
    roll = ((roll % 10) * 10) + (roll / 10)
    last_roll[event.author.id] = [roll, vs, fr]

    res = human_result(event.author.display_name, roll, vs, fr, "Moxie swap: ")
  end

  puts res
  res
end

bot.command(:remind, description: "Get a reminder of the result of your last vs roll.") do |event|
  roll, vs, fr = last_roll[event.author.id]

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  else
    res = human_result(event.author.display_name, roll, vs, fr, "Reminder: ")
  end

  puts res
  res
end

bot.command(:init, description: "Roll a d10 (1-10) and add an init modifier, with two tie-break d10 (0-9) rolloffs.") do |event, mod|
  mod = mod.to_i
  roll = rand(10) + 1
  tot = roll + mod

  d1 = rand(10)
  d2 = rand(10)

  res = "#{event.author.display_name} rolled `#{roll}` and scored `#{tot}.#{d1}#{d2}` for initiative."
  puts res
  res
end

bot.run
