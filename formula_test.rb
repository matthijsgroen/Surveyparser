#!/usr/bin/ruby1.8

require 'lib/formula.rb'

formula = 'SELECT(AL_1, "Am,sterdam", "Arn,hem", "Breda", "Den Haag", "Diemen", "Eindhoven", "Eindhoven Campus", "Groningen", "Hengelo", "Leeuwarden", "Maastricht", "Rotterdam", "Utrecht", "Voorburg", "Zwolle")'
values = { :al_1 => 1 }

puts formula
formula_data = Formula.make formula
puts formula_data.inspect
puts "#{Formula.calculate(formula_data, values)} = #{Formula.calculation_to_s(formula_data, values, true)}"
