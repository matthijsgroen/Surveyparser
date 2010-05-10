class ScoringResult

	def initialize
		@scores = []
		@score_tree = nil
	end

	attr_reader :scores

	#	@scoring_map[question_id] = {
	#		:matrix_tile => matrix_tile,
	#		:score_tile => score_tile,
	#		:indicator => indicator,
	#		:indicator_score => indicator_score,
	#		:question => question,
	#		:answers => answers,
	#		:answer_scoring => answer_scores
	#	}
	def plot_data question_data, result_row
		return if question_data[:matrix_conversion].nil? or question_data[:indicator_conversion].nil? # no scoring known for this question

		handle_single_answer question_data, result_row if question_data[:question_type] == "1 antwoord"
		handle_dummy_answer question_data, result_row if question_data[:question_type] == "dummy"
		handle_formula_answer question_data, result_row if question_data[:question_type] == "verdeel punten"
		handle_formula_answer question_data, result_row, { :no_score => true } if question_data[:question_type] == "meta berekening"
	end

	#	Autonomie
		#	25%
		# ontwikkelmogelijkheden
		# q12_1
		# 100%
		# Ik krijg ruimte om mezelf  te ontwikkelen op het gebied van duurzaamheid.
		# (1) zeer mee oneens (2) mee oneens (3) neutraal (4) mee eens (5) zeer mee eens (6) geen mening
		# 1 antwoord
		# 0%
		# 10%
		# 30%
		# 65%
		# 100%
		# X
	def handle_single_answer question_data, result_data
		value = result_data[:question_data][question_data[:question_id]]

		return if value.nil? # question is not answered.
		raise "Picked value is not a valid number '#{value}'" unless (value.to_i.to_s == value)
		answer_with_score = question_data[:answer_scoring][value.to_i - 1]
		raise "Picked answer has no assigned score '#{question_data[:question]}' picked: #{value} for #{result_data[:meta_data][:full_name]}" if answer_with_score.nil?

		sustainability_score = convert_score_text answer_with_score
		return if sustainability_score.nil? # no opinion / don't know

		add_scores result_data[:meta_data], question_data, sustainability_score
	end

	def handle_dummy_answer question_data, result_data
		value = result_data[:question_data][question_data[:question_id]]
		return if value.nil? # question is not answered.

		add_scores result_data[:meta_data], question_data, value.to_i
	end

	def handle_formula_answer question_data, result_data, options = {}
		calculation_data = { }
		unless (options[:no_score] || false) == true
			value = result_data[:question_data][question_data[:question_id]]
			return if value.nil? # question is not answered.
			raise "Picked value is not a valid number '#{value}'" unless (value.to_i.to_s == value)
			calculation_data = { :score => value.to_i }
		end
		formula = question_data[:formula]

		calculation_data = { :score => value.to_i }
		result_data[:question_data].each do |key, data|
			if data.to_i.to_s == data
				calculation_data[key.to_sym] = data.to_i
			elsif data.to_f.to_s == data
				calculation_data[key.to_sym] = data.to_f
			else
				calculation_data[key.to_sym] = data
			end
		end

		sustainability_score = formula.call calculation_data
		raise "Error in formula" if sustainability_score.nil? 
		#return if sustainability_score.nil? # no opinion / don't know

		add_scores result_data[:meta_data], question_data, sustainability_score
	end

	def add_scores(meta_data, question_data, question_score)
		@scores << {
			:participant => meta_data,
			:matrix_tile => question_data[:matrix_tile],
			:indicator => question_data[:indicator],
			:question => question_data[:question],
			:question_id => question_data[:question_id],
			:question_type => question_data[:question_type],

			:matrix_conversion => question_data[:matrix_conversion],
			:indicator_conversion => question_data[:indicator_conversion],

			:question_score => question_score
		}
		@score_tree = nil
	end

	def convert_score_text text
		return nil if text.nil?
		return nil if text == "X"
		if result = text.match(/^(-?\d+)%$/i)
			return result[0].to_i / 100.0
		end
	end

	def present_results
		score_tree.each do |matrix, data|
			if data[:m_rule] == :na
				group_result = "(#{"%.2f" % data[:score]})"
			else
				group_result = "(#{"%.2f" % (data[:score] * 100.0)}% / 100%)"
			end
			puts "#{matrix} #{group_result}"

			score_tree[matrix][:indicators].each do |indicator, ind_data|
				if ind_data[:i_rule] == :na
					group_result = "(#{"%.2f" % ind_data[:score]})"
				else
					group_result = "(#{"%.2f" % (ind_data[:score] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (ind_data[:conversion] * 100.0)}%)"
				end
				puts " - #{indicator} #{group_result}"
				score_tree[matrix][:indicators][indicator][:questions].each do |question, q_data|

					if q_data[:conversion] == :na
						group_result = "(#{"%.2f" % q_data[:score]})"
					else
						group_result = "(#{"%.2f" % (q_data[:score] * q_data[:conversion] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (q_data[:conversion] * ind_data[:conversion] * 100.0)}% uit #{q_data[:amount]})"
					end

					puts "   - #{question.gsub("\n", " ")} #{group_result}"
				end
			end
		end
	end

	def merge other_result
		@scores += other_result.scores
		@score_tree = nil
	end

	def self.merge result_list
		result = self.new
		result_list.each { |single_result| result.merge single_result }
		result
	end

	def score_tree
		@score_tree = parse_score_tree unless @score_tree
		@score_tree
	end

	private

	def parse_score_tree
		question_scores = {}
		@scores.each do |participant_question_score|
			q_id = participant_question_score[:question_id]
			unless question_scores[q_id]
				question_scores[q_id] = {
					:matrix_tile => participant_question_score[:matrix_tile],
					:indicator => participant_question_score[:indicator],
					:question => participant_question_score[:question],
					:question_id => participant_question_score[:question_id],
					:question_type => participant_question_score[:question_type],
					:matrix_conversion => participant_question_score[:matrix_conversion],
					:indicator_conversion => participant_question_score[:indicator_conversion],

					:scores => @scores.collect do |score_row|
						score_row[:question_score] if score_row[:question_id] == q_id
					end.compact
				}
				question_scores[q_id][:amount] = question_scores[q_id][:scores].length 
				sum = 0
				question_scores[q_id][:scores].each { |score| sum += score  }				
				question_scores[q_id][:average] = sum / question_scores[q_id][:amount]
			end
		end
		puts question_scores.inspect
		tree = {}
		question_scores.each do |key, data|
			tree[data[:matrix_tile]] ||= { :indicators => {}, :score => 0.0, :m_rule => data[:matrix_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]] ||= { :score => 0.0, :questions => {}, :conversion => data[:matrix_conversion], :i_rule => data[:indicator_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]][:questions][data[:question]] = {
				:score => data[:average],
				:results => data[:scores],
				:conversion => data[:indicator_conversion],
				:question_type => data[:question_type],
				:amount => data[:amount]
			}
		end

		tree.each do |key, matrix_data|
			m_score = 0
			matrix_data[:indicators].each do |indicator, indicator_data|
				i_score = 0
				indicator_data[:questions].each do |q, question_data|
					converted_score = case question_data[:conversion]
						when :na then question_data[:score]
						when Float then question_data[:score] * question_data[:conversion]
					end
					i_score += converted_score unless question_data[:question_type] == "dummy"
				end
				tree[key][:indicators][indicator][:score] = i_score

				converted_score = case indicator_data[:conversion]
					when :na then i_score
					when Float then i_score * indicator_data[:conversion]
				end
				m_score += converted_score
			end
			tree[key][:score] = m_score
		end

		tree
	end

end