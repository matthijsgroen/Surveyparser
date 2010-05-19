require 'rubygems'
require 'fastercsv'

class ScoringConfiguration

	def initialize configuration_filename
		data = FasterCSV.read configuration_filename
		start_row = 1

		@scoring_rules = []

		# Kolom lijst:
		# "matrixvak"
		# "score in matrixvak"
		#	"indicator"
		#	"codering"
		#	"score in indicator (%)"
		#	"vraag"
		#	"antwoordmogelijkheid"
		#	"soort"
		#	"formule"
		#	"e-waarde"

		# Score 1 - 16
		start_row.times do data.shift end
		data.each do |row|
			row = row.collect do |item|
				if item
					item.strip.gsub("–", "-").gsub("…", "...")
				else
					nil
				end
			end
			matrix_tile, score_tile, indicator, question_id, indicator_score, question,
				answers, question_type, curve_formula, curve_base = row[0..9]
			answer_scores = row[10..25]

			# TODO detect question type and convert percentage columns			

			scoring_rule = {
				:matrix_tile => matrix_tile,
				:score_tile => score_tile,
				:indicator => indicator,
				:indicator_score => indicator_score,
				:question => question,
				:question_id => question_id,
				:answers => answers,
				:question_type => question_type,
				:answer_scoring => answer_scores,

				:matrix_conversion => convert_score_text(score_tile),
				:indicator_conversion => convert_score_text(indicator_score)

			}

			scoring_rule[:formula] = Formula.new answer_scores[0] if ["verdeel punten", "meta berekening"].include? question_type

			@scoring_rules << scoring_rule
		end

	end

	def parse_results data_hash
		#puts "parsing results for #{data_hash[:meta_data]["Voornaam"]}"
		result = ScoringResult.new		
		@scoring_rules.each do |q_data|
			result.plot_data q_data, data_hash
		end
		#result.present_results
		result
	end

	private

	def convert_score_text text
		return nil if text.nil?
		if result = text.match(/^(-?\d+)%$/i)
			return 1.0 / 3.0 if result[0].to_i == 33
			return 2.0 / 3.0 if result[0].to_i == 66
			return result[0].to_i / 100.0
		end
		return :na if text.upcase == "N.V.T."
	end

end

