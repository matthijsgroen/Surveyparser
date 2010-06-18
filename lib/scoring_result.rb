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
		#puts question_data[:question]

		calculation_data = question_data[:row_values].merge :value => nil
		formula = question_data[:formula]

		result_row[:question_data].each do |key, data|
			new_key = value_mapper.map key.upcase
			if new_key
				if data.to_i.to_s == data
					calculation_data[new_key] = data.to_i
				elsif data.to_f.to_s == data
					calculation_data[new_key] = data.to_f
				elsif "%.2f" % data.to_f == data
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
		#return if sustainability_score.nil? # no opinion / don't know
		comment = "#{sustainability_score} = #{formula.solve(calculation_data)}"

		add_scores result_row[:meta_data], question_data, sustainability_score, comment
	end

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
	def add_scores meta_data, question_data, question_score, comment
		@scores << {
			:participant => meta_data,
			:question_data => question_data.dup,

			:question_score => question_score,
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
#				if data[:m_rule] == :na
					group_result = "" #"(#{"%.2f" % data[:score]})"
#				else
#					group_result = "(#{"%.2f" % (data[:score] * 100.0)}% / 100%)"
#				end
				result += "<li><span class=\"matrix-tile\">#{matrix} #{group_result}</span>\n"

				result += "<ul class=\"indicators\">"
				score_tree[matrix][:indicators].each do |indicator, ind_data|
#					if ind_data[:i_rule] == :na  or ind_data[:conversion] == :na
						group_result = "" #"(#{"%.2f" % ind_data[:score]})"
#					else
#						group_result = "(#{"%.2f" % (ind_data[:score] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (ind_data[:conversion] * 100.0)}%)"
#					end
					result += "<li><span class=\"indicator\">#{indicator} #{group_result}</span>\n"

					result += "<ul class=\"questions\">"
					score_tree[matrix][:indicators][indicator][:questions].each do |question, q_data|

						statistics = ""
						statistics += "<h3>Statistieken</h3>"
						statistics += "<dl>"
						statistics += "<dt>Antwoorden:</dt><dd>#{q_data[:total_amount]}</dd>"
						statistics += "<dt>Antwoorden voor berekening:</dt><dd>#{q_data[:amount]}</dd>"
						statistics += "<dt>Geen mening/weet niet:</dt><dd>#{q_data[:total_amount] - q_data[:amount]}</dd>"
						statistics += "<dt>Gemiddeld antwoord:</dt><dd>#{"%.2f" % q_data[:average]}</dd>" if q_data[:average]
						statistics += "<dt>Groeps antwoord:</dt><dd>#{q_data[:group_score]}<p class=\"comment\">#{q_data[:group_score_comment]}</p></dd>" if q_data[:group_score]
						statistics += "</dl>"


						if q_data[:cloud]
							cloud_line = []
							max = 0
							q_data[:cloud].each { |key, value| max = value if value > max }
							statistics += "<table><caption>Antwoordverdeling</caption>"
							q_data[:cloud].keys.sort.each do |key|
								statistics += "<tr><th>#{key == "" ? "Geen mening / weet niet" : key}</th><td><div class=\"bar\" style=\"width: #{((q_data[:cloud][key] / max.to_f) * 300.0).round}px\"></div>#{q_data[:cloud][key]} (#{"%.2f" % ((q_data[:cloud][key] / q_data[:amount].to_f) * 100.0)}%)</td></tr>"
							end
							statistics += "</table>"
						end

						group_result = ""

#						if q_data[:score]
#							group_result = "(#{"%.2f" % q_data[:score]} uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#						else
#							factor = (q_data[:conversion] == :na ? 1.0 : q_data[:conversion]) *
#								(ind_data[:conversion] == :na ? 1.0 : ind_data[:conversion]) * 100.0
#							group_result = "(#{"%.2f" % (q_data[:score] * factor)}% / #{"%.2f" % factor}% uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#						end

						result += "<li><span class=\"question\">#{(question || "(geen vraag)").gsub("\n", " ")} #{group_result}</span>\n"
						result += "<div class=\"statistics\">"
						result += statistics

						result += "<h4>toon individuele scores</h4>"
						result += "<div class=\"scores\">"
						result += "<ol>"
						(q_data[:meta_data] || []).each_with_index do |meta_data, index|
							result += "<li>#{meta_data[:score]} (#{meta_data[:participant]})"
							result += "<p class=\"comment\">#{comment_to_html(meta_data[:comment])}</p>\n" if meta_data[:comment]
							result += "</li>\n"
						end
						result += "</ol></div>"
						result += "</div>"

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

	#	:participant => meta_data,
	#	:question_data => question_data,
	#
	#	:question_score => question_score,
	#	:score_type => score_type,
	#	:comment => comment
	def parse_score_tree
		question_scores = {}
		@scores.each do |participant_question_score|
#			puts "#{participant_question_score[:participant][:full_name]}: " +
#				"#{participant_question_score[:question_data][:question]} #{participant_question_score[:question_score].inspect}"

			q_id = participant_question_score[:question_data][:question_id]
			unless question_scores[q_id]
				scores = []
				meta_data = []
				@scores.collect do |score_row|
					if score_row[:question_data][:question_id] == q_id
						scores << score_row[:question_score]
						meta_data << {
							:comment => score_row[:comment],
							:participant => score_row[:participant][:full_name],
							:score => score_row[:question_score]
						}
					end
				end

				question_scores[q_id] = {
					:matrix_tile => participant_question_score[:question_data][:matrix_tile],
					:indicator => participant_question_score[:question_data][:indicator],
					:question => participant_question_score[:question_data][:question],
					:matrix_conversion => participant_question_score[:question_data][:matrix_conversion],
					:indicator_conversion => participant_question_score[:question_data][:indicator_conversion],
					:question_data => participant_question_score[:question_data],

					:scores => scores,
					:meta_data => meta_data,
					:total_amount => scores.length,
					:amount => scores.compact.length
				}

				begin
					sum = 0.0
					scores.each { |score| sum += score if score }
					question_scores[q_id][:sum] = sum
					question_scores[q_id][:average] = sum / question_scores[q_id][:amount]
				rescue TypeError
				end
				cloud = {}
				question_scores[q_id][:scores].each do |term|
					cloud_term = term.to_s.downcase
					cloud.has_key?(cloud_term) ? cloud[cloud_term] += 1 : cloud[cloud_term] = 1
				end
				question_scores[q_id][:cloud] = cloud

			end
		end
		#puts question_scores.inspect
		tree = {}
		question_scores.each do |key, data|
			tree[data[:matrix_tile]] ||= { :indicators => {}, :score => 0.0, :m_rule => data[:matrix_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]] ||= { :score => 0.0, :questions => {}, :conversion => data[:matrix_conversion], :i_rule => data[:indicator_conversion] }

			calculation_data = data[:question_data][:row_values].merge :value => data[:average]
			formula = data[:question_data][:group_formula]
			group_score = formula.call calculation_data
			group_score_comment = formula.solve calculation_data

			tree[data[:matrix_tile]][:indicators][data[:indicator]][:questions][data[:question]] = {
				:score => data[:average],
				:results => data[:scores],
				:cloud => data[:cloud],
				:meta_data => data[:meta_data],
				:conversion => data[:indicator_conversion],
				:question_type => data[:question_type],
				:amount => data[:amount],
				:total_amount => data[:total_amount],
				:sum => data[:sum],
				:average => data[:average],
				:group_score => group_score,
				:group_score_comment => group_score_comment
			}
		end

		tree.each do |key, matrix_data|
			m_score = 0
			matrix_data[:indicators].each do |indicator, indicator_data|
				i_score = 0
				indicator_data[:questions].each do |q, question_data|
					if question_data[:score]
						converted_score = case question_data[:conversion]
							when :na then question_data[:score]
							when Float then question_data[:score] * question_data[:conversion]
						end
						i_score += converted_score
					end
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