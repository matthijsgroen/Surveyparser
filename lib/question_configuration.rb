require 'rubygems'
require 'fastercsv'

class QuestionStatistics

	attr_accessor :code, :max_score, :question, :type, :answer_scores,
								:answers

	def initialize values
		self.code = values[:code]
		self.max_score = values[:max_score]
		self.question = values[:question]
		self.type = values[:type]
		self.answer_scores = values[:answer_scores]
		self.answers = []
	end

	def add_answer value, index
		self.answers << { :value => value, :index => index, :scored_value => scored_value(value)}
	end

	def scored_value value
		#TODO Map value on score list if question supports it.
		value
	end

end

class QuestionConfiguration

	def self.read_config filename
	  result = self.new
		result.filename = filename
		result.parse_file
		result
	end

	def initialize
		@structure = { }
		@questions = { }
	end

	attr_accessor :filename

	def parse_file
		data = FasterCSV.read(@filename)
		start_row = 1

		# Kolom lijst:
		# "matrixvak",
		# "score in matrixvak",
		# "indicator",
		# "codering",
		# "score in indicator",
		# "vraag",
		# "antwoordmogelijkheid",
		# Score 1 - 16
		start_row.times do data.shift end
		data.each do |row|
			matrix_tile, score_tile, indicator, question_id, indicator_score, question,
				answers = row[0..6]
			answer_scores = row[7..23]

			# build the question structure
			@structure[matrix_tile] ||= {}
			@structure[matrix_tile][indicator] ||= {}
			@structure[matrix_tile][indicator][:total_score] = score_tile unless score_tile.nil? or score_tile == ""
			@structure[matrix_tile][indicator][:questions] ||= []
			@structure[matrix_tile][indicator][:questions] << \
			{
			  :code => question_id, :max_score => indicator_score, :question => question,
				:answer_scores => answer_scores.compact
			}
			# Update the quick lookup table
			@questions[question_id] ||= []
			@questions[question_id] << { :matrix => matrix_tile, :indicator => indicator,
				:q_index => @structure[matrix_tile][indicator][:questions].length - 1
			}
			
		end
	end

	def data_overview
		@structure.each do |matrix_part, indicators|
			puts "#{matrix_part}:"
			indicators.each do |indicator, info|
				puts "- #{indicator} #{info[:total_score]}"
#				info[:questions].each do |q|
#					puts "  #{q[:code]} - #{q[:max_score]} (#{q[:answer_scores] * ", "})"
#				end
			end
		end
	end

end