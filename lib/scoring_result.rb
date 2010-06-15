class ScoringResult

	def initialize
		@scores = []
		@score_tree = nil
	end

	attr_reader :scores

	#	@scoring_map[question_id] = {
	#		:matrix_tile => mapped_row["matrixvak"],
	#		:matrix_conversion => convert_score_text(mapped_row["score in matrixvak"]),
	#
	#		:indicator => mapped_row["indicator"],
	#		:indicator_conversion => convert_score_text(mapped_row["score in indicator"]),
	#
	#		:question => mapped_row["vraag"],
	#
	#		:formula => Formula.new(answer_formula),
	#		:group_formula => Formula.new(group_formula),
	#
	#		:row_values => mapped_row
	#	}
	def plot_data question_data, result_row, value_mapper
		raise "No conversion rate given for \"score in matrixvak\"" if question_data[:matrix_conversion].nil?
		raise "No conversion rate given for \"score in indicator\"" if question_data[:indicator_conversion].nil? # no scoring known for this question

		handle_formula_answer question_data, result_row, value_mapper


#		case question_data[:question_type]
#			when "cloud" then handle_cloud_answer question_data, result_row
#			when "1 antwoord" then handle_single_answer question_data, result_row
#			when "dummy" then handle_dummy_answer question_data, result_row
#			when "verdeel punten" then handle_formula_answer question_data, result_row
#			when "meta berekening" then handle_formula_answer question_data, result_row, :no_score => true
#			else puts "Geen support voor vragentype: #{question_data[:question_type]}"
#		end
	end

#	#	Autonomie
#		#	25%
#		# ontwikkelmogelijkheden
#		# q12_1
#		# 100%
#		# Ik krijg ruimte om mezelf  te ontwikkelen op het gebied van duurzaamheid.
#		# (1) zeer mee oneens (2) mee oneens (3) neutraal (4) mee eens (5) zeer mee eens (6) geen mening
#		# 1 antwoord
#		# 0%
#		# 10%
#		# 30%
#		# 65%
#		# 100%
#		# X
#	def handle_single_answer question_data, result_data
#		value = result_data[:question_data][question_data[:question_id]]
#		#puts "#{question_data[:question]} = #{value}"
#
#		return if value.nil? # question is not answered.
#		raise "Picked value is not a valid number '#{value}'" unless (value.to_i.to_s == value)
#		answer_with_score = question_data[:answer_scoring][value.to_i - 1]
#		raise "Picked answer has no assigned score '#{question_data[:question]}' picked: #{value} for #{result_data[:meta_data][:full_name]}" if answer_with_score.nil?
#		sustainability_score, score_type = convert_score_text answer_with_score
#		return if sustainability_score.nil? # no opinion / don't know
#
#		add_scores result_data[:meta_data], question_data, sustainability_score, score_type, nil
#	end
#
#	def handle_dummy_answer question_data, result_data
#		value = result_data[:question_data][question_data[:question_id]]
#		return if value.nil? # question is not answered.
#
#		add_scores result_data[:meta_data], question_data, value.to_i, :numeric, nil
#	end

	def handle_formula_answer question_data, result_data, value_mapper
		calculation_data = { :value => nil }
		formula = question_data[:formula]

		result_data[:question_data].each do |key, data|
			new_key = value_mapper.map key.upcase
			if new_key
				if data.to_i.to_s == data
					calculation_data[new_key] = data.to_i
				elsif data.to_f.to_s == data
					calculation_data[new_key] = data.to_f
				else
					calculation_data[new_key] = data
				end
			end
		end

		begin
			sustainability_score = formula.call calculation_data
		rescue StandardError => error
			puts "Error doing calculation: #{formula.to_string calculation_data} #{error}"
			raise
		end
		return if sustainability_score.nil? # no opinion / don't know
		comment = "#{sustainability_score} = #{formula.solve(calculation_data)}"

		value_type = case sustainability_score
			when Numeric then :numeric
			when String then :text
			else :unknown
		end

		add_scores result_data[:meta_data], question_data, sustainability_score, value_type, comment
	end

#	def handle_cloud_answer question_data, result_data, options = {}
#		value = result_data[:question_data][question_data[:question_id]]
#		return if value.nil? # question is not answered.
#
#		add_scores result_data[:meta_data], question_data, value, :string, nil
#	end

	def add_scores meta_data, question_data, question_score, score_type, comment
		@scores << {
			:participant => meta_data,
			:matrix_tile => question_data[:matrix_tile],
			:indicator => question_data[:indicator],
			:question => question_data[:question],
			:question_id => question_data[:question_id],
			:question_type => question_data[:question_type],

			:matrix_conversion => question_data[:matrix_conversion],
			:indicator_conversion => question_data[:indicator_conversion],

			:question_score => question_score,
			:score_type => score_type,
			:comment => comment
		}
		@score_tree = nil
	end

	def convert_score_text text
		return [nil, nil] if text.nil?
		return [nil, :na] if text == "X"
		if result = text.match(/^(-?\d+)%$/i)
			return [result[0].to_i / 100.0, :percentage]
		end
		if result = text.match(/^(-?\d+)$/i)
			return [result[0].to_i, :numeric]
		end
	end

	def as_s(*args)
		result = ""
		score_tree.each do |matrix, data|
			if args.include? matrix or args.empty?
				if data[:m_rule] == :na
					group_result = "" #"(#{"%.2f" % data[:score]})"
				else
					group_result = "(#{"%.2f" % (data[:score] * 100.0)}% / 100%)"
				end
				result += "#{matrix} #{group_result}\n"

				score_tree[matrix][:indicators].each do |indicator, ind_data|
					if ind_data[:i_rule] == :na  or ind_data[:conversion] == :na
						group_result = "" #"(#{"%.2f" % ind_data[:score]})"
					else
						group_result = "(#{"%.2f" % (ind_data[:score] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (ind_data[:conversion] * 100.0)}%)"
					end
					result += " - #{indicator} #{group_result}\n"
					score_tree[matrix][:indicators][indicator][:questions].each do |question, q_data|
						if q_data[:score_type] == :string
							cloud_line = []
							q_data[:cloud].each { |key, value| cloud_line << "#{key} (#{value})" }
							group_result = "(#{ cloud_line * ", " })"
						elsif q_data[:score_type] == :numeric
						  
							#elsif (q_data[:conversion] == :na or q_data[:score_type] == :numeric) and q_data[:score_type] != :percentage
							group_result = "(#{"%.2f" % q_data[:score]})"
						else
							factor = (q_data[:conversion] == :na ? 1.0 : q_data[:conversion]) *
								(ind_data[:conversion] == :na ? 1.0 : ind_data[:conversion]) * 100.0
							group_result = "(#{"%.2f" % (q_data[:score] * factor)}% / #{"%.2f" % factor}% uit #{q_data[:amount]})"
						end

						result += "   - #{question.gsub("\n", " ")} #{group_result}\n"

#						(q_data[:comments] || []).each do |comment|
#							result += "      - #{comment}\n"
#						end
					end
				end
			end
		end
		result
	end

	def as_html(*args)
		options = args.pop if args.last.is_a? Hash 
		result = <<-EOS
			<html>
			<head>
				<title>Enquete: #{options[:title] || "Resultaat"}</title>
		    <script src="javascripts/jquery.js" type="text/javascript"></script>
		    <script src="javascripts/application.js" type="text/javascript"></script>
    		<link href="stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />
			</head>
			<body>
			<h1>#{options[:title] || "Resultaat"}</h1>

			<ul class="matrix-tiles">
		EOS
		score_tree.each do |matrix, data|
			if args.include? matrix or args.empty?
				if data[:m_rule] == :na
					group_result = "" #"(#{"%.2f" % data[:score]})"
				else
					group_result = "(#{"%.2f" % (data[:score] * 100.0)}% / 100%)"
				end
				result += "<li><span class=\"matrix-tile\">#{matrix} #{group_result}</span>\n"

				result += "<ul class=\"indicators\">"
				score_tree[matrix][:indicators].each do |indicator, ind_data|
					if ind_data[:i_rule] == :na  or ind_data[:conversion] == :na
						group_result = "" #"(#{"%.2f" % ind_data[:score]})"
					else
						group_result = "(#{"%.2f" % (ind_data[:score] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (ind_data[:conversion] * 100.0)}%)"
					end
					result += "<li><span class=\"indicator\">#{indicator} #{group_result}</span>\n"

					result += "<ul class=\"questions\">"
					score_tree[matrix][:indicators][indicator][:questions].each do |question, q_data|
						if q_data[:score_type] == :string
							cloud_line = []
							q_data[:cloud].each { |key, value| cloud_line << "#{key} (#{value})" }
							group_result = "(#{ cloud_line * ", " } uit #{q_data[:amount]})"
						elsif q_data[:score_type] == :numeric
							group_result = "(#{"%.2f" % q_data[:score]} uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
						else
							factor = (q_data[:conversion] == :na ? 1.0 : q_data[:conversion]) *
								(ind_data[:conversion] == :na ? 1.0 : ind_data[:conversion]) * 100.0
							group_result = "(#{"%.2f" % (q_data[:score] * factor)}% / #{"%.2f" % factor}% uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
						end

						result += "<li><span class=\"question\">#{question.gsub("\n", " ")} (#{q_data[:question_type]}) #{group_result}</span>\n"

						result += "<ol class=\"scores\">"
						(q_data[:meta_data] || []).each_with_index do |meta_data, index|
							result += "<li>#{meta_data[:score]} (#{meta_data[:participant]})"
							result += "<p class=\"comment\">#{comment_to_html(meta_data[:comment])}</p>\n" if meta_data[:comment]

							result += "</li>\n"
						end
						result += "</ol>"

						result += "</li>"
					end
					result += "</ul>"
					result += "</li>"
				end
				result += "</ul>"
				result += "</li>"
			end
		end
		result += <<-EOS
			</ul>
			</body>
			</html>
		EOS

		result
	end

	def comment_to_html comment
		r = comment.gsub "(", "<span class=\"group\">(</span>"
		r = r.gsub ")", "<span class=\"group\">)</span>"
		r = r.gsub ",", ", "
		r = r.gsub /\[([^\]]+)\]/, "[<span class=\"value\">\\1</span>]"
		r
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
					:score_type => participant_question_score[:score_type],

					:scores => @scores.collect do |score_row|
						score_row[:question_score] if score_row[:question_id] == q_id
					end.compact,
					:meta_data => @scores.collect do |score_row|
						if score_row[:question_id] == q_id
							{
								:comment => score_row[:comment],
								:participant => score_row[:participant][:full_name],
								:score => score_row[:question_score]
							}
						end
					end.compact
				}
				question_scores[q_id][:amount] = question_scores[q_id][:scores].length
				if participant_question_score[:question_type] == "cloud"
					cloud = {}
					question_scores[q_id][:scores].each do |term|
						cloud_term = term.downcase
						cloud.has_key?(cloud_term) ? cloud[cloud_term] += 1 : cloud[cloud_term] = 1
					end
					question_scores[q_id][:cloud] = cloud
				else
					sum = 0.0
					question_scores[q_id][:scores].each { |score| sum += score  }
					question_scores[q_id][:sum] = sum 
					question_scores[q_id][:average] = sum / question_scores[q_id][:amount]
				end
			end
		end
		#puts question_scores.inspect
		tree = {}
		question_scores.each do |key, data|
			tree[data[:matrix_tile]] ||= { :indicators => {}, :score => 0.0, :m_rule => data[:matrix_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]] ||= { :score => 0.0, :questions => {}, :conversion => data[:matrix_conversion], :i_rule => data[:indicator_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]][:questions][data[:question]] = {
				:score => data[:average],
				:results => data[:scores],
				:cloud => data[:cloud],
				:meta_data => data[:meta_data],
				:conversion => data[:indicator_conversion],
				:question_type => data[:question_type],
				:score_type => data[:score_type],
				:amount => data[:amount],
				:sum => data[:sum],
				:average => data[:average]
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
					i_score += converted_score unless ["dummy", "cloud"].include? question_data[:question_type] 
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