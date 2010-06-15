require 'rubygems'
require 'fastercsv'

class ScoringConfiguration

	DEFAULT_FORMULA = "value"

	def initialize configuration_filename
		data = FasterCSV.read configuration_filename
		@scoring_rules = []

		names = data.shift.collect(&:downcase)

		# Kolom lijst:
		#	matrixvak
		#	score in matrixvak
		#	indicator
		#	score in indicator
		#	vraag
		#	groepsformule
		#	antwoordformule

		data.each_with_index do |csv_row, row_index|
			mapped_row = {}
			csv_row.each_with_index do |field, index|
				mapped_row[names[index]] = field ? cleanup_field_value(field) : nil
			end
			begin
				answer_formula = mapped_row["antwoordformule"]
				answer_formula ||= DEFAULT_FORMULA
				answer_formula = DEFAULT_FORMULA if answer_formula == ""

				group_formula = mapped_row["groepsformule"]
				group_formula ||= DEFAULT_FORMULA
				group_formula = DEFAULT_FORMULA if group_formula == ""

				@scoring_rules << {
					:matrix_tile => mapped_row["matrixvak"],
					:matrix_conversion => convert_score_text(mapped_row["score in matrixvak"]),

					:indicator => mapped_row["indicator"],
					:indicator_conversion => convert_score_text(mapped_row["score in indicator"]),

					:question => mapped_row["vraag"],

					:formula => Formula.new(answer_formula),
					:group_formula => Formula.new(group_formula),

					:row_values => mapped_row
				}
			rescue StandardError => e
				puts "Error occured parsing row #{row_index + 2} from the scoring_definition sheet: #{e}"
				raise
			end
		end

	end

	def parse_results data_hash, value_mapper
		#puts "parsing results for #{data_hash[:meta_data]["Voornaam"]}"
		result = ScoringResult.new		
		@scoring_rules.each_with_index do |q_data, row_index|
			begin
				result.plot_data q_data, data_hash, value_mapper
			rescue StandardError => e
				puts "Error occured on line #{row_index + 2}: #{e}"
				raise
			end
		end
		result
	end

	private

	def cleanup_field_value(text)
		text.strip.gsub("–", "-").gsub("…", "...")
	end

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

