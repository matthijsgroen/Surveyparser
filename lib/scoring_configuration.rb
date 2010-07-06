require 'rubygems'
require 'fastercsv'

class ScoringConfiguration

	DEFAULT_FORMULA = "value"

	COL_M = "matrixvak"
	COL_MS = "score in matrixvak"
	COL_I = "indicator"
	COL_IS = "score in indicator"
	COL_Q = "vraag"
	COL_FG = "groepsformule"
	COL_FQ = "antwoordformule"
	COL_CODE = "codering"
	COL_MIN = "score groepsformule [min]"
	COL_MAX = "score groepsformule [max]"

	COLUMN_LIST = [COL_M, COL_MS, COL_I, COL_IS, COL_Q, COL_FG, COL_FQ, COL_CODE, COL_MIN, COL_MAX]

	attr_reader :scoring_rules

	def initialize configuration_filename
		data = FasterCSV.read configuration_filename
		@scoring_rules = []

		names = data.shift.collect(&:downcase).collect(&:strip)
		COLUMN_LIST.each { |name|	raise "Column '#{name}' not found" unless names.include? name }

		# Kolom lijst:
		#	matrixvak
		#	score in matrixvak
		#	indicator
		#	score in indicator
		#	vraag
		#	groepsformule
		#	antwoordformule

		data.each_with_index do |csv_row, row_index|
			#return if row_index > 15
			mapped_row = {}
			values_row = {}
			csv_row.each_with_index do |field, index|
				value = field ? cleanup_field_value(field) : nil
				mapped_row[names[index]] = value

				value = if value.to_i.to_s == value
					value.to_i
				elsif value.to_f.to_s == value
					value.to_f
				elsif "%.2f" % value.to_f == value
					value.to_f
				else
					value
				end
				values_row[spreadsheet_columnname(index).to_sym] = value
			end
			
			begin
				answer_formula = mapped_row[COL_FQ]
				answer_formula ||= DEFAULT_FORMULA
				answer_formula = DEFAULT_FORMULA if answer_formula == ""

				group_formula = mapped_row[COL_FG]
				group_formula ||= DEFAULT_FORMULA
				group_formula = DEFAULT_FORMULA if group_formula == ""

				@scoring_rules << {
					:matrix_tile => mapped_row[COL_M],
					:matrix_conversion => convert_score_text(mapped_row[COL_MS]),

					:indicator => mapped_row[COL_I],
					:indicator_conversion => convert_score_text(mapped_row[COL_IS]),

					:question => mapped_row[COL_Q],
					:question_id => row_index,
					:question_label_id => mapped_row[COL_CODE],
					:question_scoring => { :min => mapped_row[COL_MIN],
																 :max => mapped_row[COL_MAX] },

					:formula => Formula.new(answer_formula),
					:group_formula => Formula.new(group_formula),

					:row_values => values_row.dup
				}
			rescue StandardError => e
				puts "Error occured parsing row #{row_index + 2} from the scoring_definition sheet: #{e}"
				raise
			end
		end
	end

	def parse_results data_hash, value_mapper
		#puts "parsing results for #{data_hash[:meta_data]["Voornaam"]}"
		result = ScoringResult.new data_hash, value_mapper		
		@scoring_rules.each_with_index do |q_data, row_index|
			begin
				result.plot_data q_data
			rescue StandardError => e
				puts "Error occured on line #{row_index + 2}: #{e}"
				raise
			end
		end
		result
	end

	private

	def cleanup_field_value text
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
		return nil
	end

	def spreadsheet_columnname index
		count_index = index
		result = ""
		abc = ('a'..'z').to_a

		if count_index >= abc.length
			result += spreadsheet_columnname(((count_index - abc.length) / abc.length.to_f).floor)
			count_index = count_index % abc.length
		end
		result += abc[count_index]
		return result
	end

end

