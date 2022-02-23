#!/usr/bin/env ruby

require 'discordrb'

def make_roll(dX = 100)
  rand(100_000_000 * dX) % dX
end

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
  supsig = diff >= 60

  prefix + "#{name} rolled `#{roll}` against `#{vs}`" +
    "#{fr.empty? ? "" : " for \"#{fr.join(' ')}\""}. " +

    "That is #{(!crit && sig && success) ? "an" : "a"} " +
    "_#{crit ? "**critical** " : ""}" +
    "#{sig && !supsig ? (success ? "excellent " : "severe ") : ""}" +
    "#{supsig ? (success ? "exceptional " : "horrific ") : ""}" +
    "#{success ? "success" : "failure"}_ " +

    "by `#{diff}` (#{diff / 10} Mo#{success ? "S" : "F"})."
end

last_roll = {}

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], client_id: ENV['DISCORD_ID'], prefix: '!'

bot.command(:vs, description: "Roll a d100 (0-99) against a target number, with optional comment.") do |event, vs, *fr|
  vs = vs.to_i
  roll = make_roll

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
    roll = make_roll
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
  roll = make_roll(10) + 1
  tot = roll + mod

  d1 = make_roll(10)
  d2 = make_roll(10)

  res = "#{event.author.display_name} rolled `#{roll}` and scored `#{tot}.#{d1}#{d2}` for initiative."
  puts res
  res
end

bot.command(:unitest, description: "Perform a uniformity test for peace of mind.") do |event|
  t = 10_000_000
  u = t / 100

  a = Array.new(100, 0)
  t.times { a[make_roll] += 1 }

  d2 = a.map { |o| (o - u) ** 2 }
  s2 = d2.sum / 100.0
  s = s2 ** 0.5

  res = "#{event.author.display_name} requested a uniformity test. #{t} d100s were rolled and counted. The standard deviation was #{"%.2f" % s}, which means 68% of the possible outcomes each appeared within #{s.ceil} of the expected #{u} times, 95% within #{(s*2).ceil}, and 99.7% within #{(s*3).ceil}."
  puts res
  res
end

bot.command(:reseed, description: "Reseed the PRNG if you're feeling particularly superstitious about the rolls.") do |event|
  srand

  res = "#{event.author.display_name} requested the PRNG be reseeded."
  puts res
  res
end

bot.run
