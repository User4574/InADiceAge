#!/usr/bin/env ruby

require 'discordrb'

def make_roll(dX = 100)
  rand(100_000_000 * dX) % dX
end

def calc_sups(roll, vs)
  case roll
  when 0
    success = true
  when 99
    success = false
  else
    success = roll <= vs
  end

  (success ? roll : (99 - roll)) / 33
end

def calc_crit(roll)
  roll / 10 == roll % 10
end

def human_result(name, data, prefix = "")
  roll, vs, fr, flip, up, down = data

  case roll
  when 0
    crit = true
    success = true
  when 99
    crit = true
    success = false
  else
    crit = calc_crit(roll)
    success = roll <= vs
  end

  sups = calc_sups(roll, vs)

  sups += 1 if up
  crit = false if down

  prefix + "#{name} rolled `#{roll}` against `#{vs}`" +
    "#{fr.empty? ? "" : " for \"#{fr.join(' ')}\""}. " +

    "That is " +
    (sups > 1 ? "two " : "a ") +
    (sups > 0 ? "_superior_ " : "") +
    (crit ? "_**critical**_ " : "") +
    (success ? "success" : "failure") +
    (sups > 1 ? (success ? "es" : "s") : "")
end

last_roll = {}

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], client_id: ENV['DISCORD_ID'], prefix: '!'

bot.command(:vs, description: "Roll a d100 (0-99) against a target number, with optional comment.") do |event, vs, *fr|
  vs = vs.to_i
  roll = make_roll

  data = [roll, vs, fr, false, false, false]
  last_roll[event.author.id] = data

  res = human_result(event.author.display_name, data)
  puts res
  res
end

bot.command(:again, description: "Repeat your last vs roll.") do |event|
  data = last_roll[event.author.id]
  roll, vs, fr, flip, up, down = data

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  else
    roll = make_roll
    data = [roll, vs, fr, false, false, false]
    last_roll[event.author.id] = data

    res = human_result(event.author.display_name, data , "Repeat: ")
  end

  puts res
  res
end

bot.command(:flipflop, description: "Swap the digits on your last vs roll.") do |event|
  data = last_roll[event.author.id]
  roll, vs, fr, flip, up, down = data

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  elsif up
    res = "You have already upgraded this success, #{event.author.display_name}."
  elsif up
    res = "You have already downgraded this failure, #{event.author.display_name}."
  else
    roll = ((roll % 10) * 10) + (roll / 10)
    last_roll[event.author.id] = [roll, vs, fr, !flip, up, down]

    res = human_result(event.author.display_name, data, (flip ? "Unflip-flop: " : "Flip-flop: "))
  end

  puts res
  res
end

bot.command(:upgrade, description: "Increase the number of superiors on your last vs roll.") do |event|
  data = last_roll[event.author.id]
  roll, vs, fr, flip, up, down = data

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  elsif flip
    res = "You have already flip-flopped this roll, #{event.author.display_name}."
  elsif down
    res = "You have already downgraded this failure, #{event.author.display_name}."
  elsif calc_sups(roll, vs) > 1
    res = "This is already two superior successes, #{event.author.display_name}!"
  else
    last_roll[event.author.id] = [roll, vs, fr, flip, !up, down]

    res = human_result(event.author.display_name, data, (up ? "Unupgrade: " : "Upgrade: "))
  end

  puts res
  res
end

bot.command(:downgrade, description: " last vs roll.") do |event|
  data = last_roll[event.author.id]
  roll, vs, fr, flip, up, down = data

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  elsif flip
    res = "You have already flip-flopped this roll, #{event.author.display_name}."
  elsif up
    res = "You have already upgraded this success, #{event.author.display_name}."
  elsif !calc_crit(roll)
    res = "This isn't a critical failure, #{event.author.display_name}."
  else
    last_roll[event.author.id] = [roll, vs, fr, flip, up, !down]

    res = human_result(event.author.display_name, data, (down ? "Undowngrade: " : "Downgrade: "))
  end

  puts res
  res
end

bot.command(:remind, description: "Get a reminder of the result of your last vs roll.") do |event|
  data = last_roll[event.author.id]

  if roll.nil?
    res = "You need to roll something first, #{event.author.display_name}!"
  else
    res = human_result(event.author.display_name, data, "Reminder: ")
  end

  puts res
  res
end

bot.command(:init, description: "Roll a d6 (1-6) and add an init modifier, with two tie-break d6 (0-5) rolloffs.") do |event, mod|
  mod = mod.to_i
  roll = make_roll(6) + 1
  tot = roll + mod

  d1 = make_roll(6)
  d2 = make_roll(6)

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
