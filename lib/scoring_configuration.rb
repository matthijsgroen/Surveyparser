require 'rubygems'
require 'fastercsv'

class ScoringConfiguration

	def initialize configuration_filename
		data = FasterCSV.read configuration_filename
		start_row = 1

		@scoring_map = {}

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

			# TODO detect question type and convert percentage columns			

			@scoring_map[question_id] = {
				:matrix_tile => matrix_tile,
				:score_tile => score_tile,
				:indicator => indicator,
				:indicator_score => indicator_score,
				:question => question,
				:answers => answers,
				:answer_scoring => answer_scores			
			}
		end

	end

end

