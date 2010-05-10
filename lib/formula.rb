# Formula parser and calculator
# author: Matthijs Groen
#
# This class has two main functions:
# 1. to parse formula into ready-to-use-arrays
# 2. use those arrays to perform calculations
#
#
# =Parsing formula
# my_formula = Formula.new("100% – (MAX(score – 5, 0) * 10%)") => Formula
# my_formula_data = Formula.make("100% – (MAX(score – 5, 0) * 10%)") => Array
#
# The array format used for formula data is [:operator, [parameter, parameter]]
# the parameters can also be arrays: e.g. sub-calculations
#
# The text formula can be build with the following elements:
# operators:
#   -: subtract. subtracts the right side from the left side argument
#   *, x: multiply. multiplies the left side with the right side argument
#   /: divide. divides the left side with the ride side argument
#   +: add. adds the right side to the left side argument
#
# functions:
#   functions have the format of name(parameters)
#   the parameters of the function will be pre calculated before the code of the function is executed.
#   supported functions:
#		- max: selects the biggest value from the provided values
#		- min: selects the smallest value from the provided values
#		- sum: creates a sum of all the provided values
#
# parenthesis:
#   parentesis can be used to group calculation parts
#
# variables:
#   terms that start with a alfabetic character and contain only alfanumeric characters and underscores
#   can be used as variables. A hash with variables should be supplied when the calculation is performed
#
# numeric values:
#   numeric values like integers, floats and percentages are also allowed. Percentages will be converted to floats.
#		33% and 66% will be converted to resp. 100% / 3 and 200% / 3
#
# =Performing calculations
# my_formula.call(:score => 7.0) => 0.8 (using the above formula example)
# Formula.calculate(my_formula_data, :score => 3.0) => 1.0 (using the above formula example)
#
class Formula

	# Known operators
	OPERATORS = "-*/+x"

	# parse the given code formula in an array using the format
	# calculation = [operation, [parameter, parameter]]
	# a parameter can ofcourse be in turn another calculation
	def initialize(code)
		@calculation = Formula.make code
		#puts "#{@calculation.inspect}"
	end

	def self.make(code)
		# Fixup code from popular spreadsheet toos to normal ASCII variants
		code = code.gsub("–", "-")

		#puts "parsing: #{code}"
		parse_operation(code.upcase)		
	end

	# executes the formula with a hash of given calculation terms
	def call(input)
		Formula.calculate(@calculation, input)
	end

	def self.calculate(calculation, input)
		operation, parameters = *calculation

		parameters = parameters.collect do |parameter|
			parameter.is_a?(Array) ? calculate(parameter, input) : parameter
		end

		#puts "executing #{operation ? operation : "no-op"} on #{parameters.inspect}"

		case operation
			when :add then parameters[0] + parameters[1]
			when :subtract then parameters[0] - parameters[1]
			when :times then parameters[0] * parameters[1]
			when :divide then parameters[0] / parameters[1]
			# functions:
			when :max then parameters.max
			when :min then parameters.min
			when :sum then begin
				result = 0.0
				parameters.each { |value| result += value || 0.0 }
				result
			end
			# variables
			when :term then input[parameters[0]]
			# no-op
			when nil, :percentage then parameters[0].to_f
		end
	end

	private

	def self.parse_operation(code)
		#puts "parsing: #{code}"

		# check if the code is totally surrounded by parenthesis that can be removed. remove them if possible
		code = ungroup code

		left, right, operator = "", "", nil
		char_index,	group_level = 0, 0
		while char_index < code.length
			char = code[char_index, 1]
			if !operator and OPERATORS.include? char and group_level == 0
				operator = case char
					when "-" then :subtract
					when "+" then :add
					when "*", "x" then :times
					when "/" then :divide
				end
			else
				group_level += (char == "(") ? 1 : -1 if "()".include? char
				operator ? right += char : left += char
			end
			char_index += 1
		end
		return parse_definition(left.strip) unless operator

		#puts "parse-result: #{operator}, #{left}, #{right}"
		return operator, [parse_operation(left.strip), parse_operation(right.strip)]
	end

	def self.parse_definition(code)
		# parse percentages 100%, 10%
		if result = code.match(/\A(\d+)%\z/)
			return :percentage, [1.0 / 3.0] if result[1].to_i == 33
			return :percentage, [2.0 / 3.0] if result[1].to_i == 66
			return :percentage, [result[1].to_i / 100.0]

		# parse function calls in the format FUNCTION(parameters)
		elsif result = code.match(/\A([A-Z_]+)\((.+)\)\z/)
			return result[1].downcase.to_sym, result[2].split(",").collect { |parameter| parse_operation(parameter) }

		# parse numeric value
		elsif code.to_i.to_s == code
			return nil, [code.to_i]

		# parse numeric value
		elsif code.to_f.to_s == code
			return nil, [code.to_f]

		# parse variable term
		elsif result = code.match(/\A([A-Z][A-Z0-9_]*)\z/)
			return :term, [result[1].downcase.to_sym]
		else
			raise "can't parse code: \"#{code}\""
		end
	end

	# check if the code is totally surrounded by parenthesis that can be removed. remove them if possible
	# examples:
	# ungroup("(my code ()") => "(my code ()"
	# ungroup("(my code ())") => "my code ()"
	# ungroup("(my code) ()") => "(my code) ()"
	# ungroup("m(my code)") => "m(my code)"
	def self.ungroup(code)
		# exit if the code does not start with an opening parentesis
		return code unless code[0, 1] == "("
		# since we know the first character is an opening parenthesis,
		# start parsing at the second character, and assume grouping level 1
		group_level, char_index = 1, 1
		while char_index < code.length
			char = code[char_index, 1]
			group_level += 1 if char == "("
			group_level -= 1 if char == ")"

			# only strip the first and last parenthesis if we exit the grouping AND we reached the last character
			return  code[1 .. -2]if group_level == 0 and char_index == code.length - 1
			char_index += 1
		end
		code
	end

end