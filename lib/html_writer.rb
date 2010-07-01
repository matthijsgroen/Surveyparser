class HtmlWriter

	def initialize options
		@options = options
		@parsed_tree = {}
	end

	def add_results * groups
		groups.each { |group| add_score_tree group }
	end

	def output
		result = <<-EOS
			<html>
			<head>
				<title>Enquete:  #{@options[:title] || "Resultaat"} </title>
		    <script src="javascripts/jquery.js" type="text/javascript"></script>
		    <script src="javascripts/application.js" type="text/javascript"></script>
    		<link href="stylesheets/application.css" media="screen" rel="stylesheet" type="text/css" />
			</head>
			<body>
			<h1> #{@options[:title] || "Resultaat"} </h1>

			<ul class="matrix-tiles">
		EOS
		@parsed_tree.keys.sort { |a, b| a.upcase <=> b.upcase }.each do |matrix_title|
			puts "Writing: #{matrix_title}"
			result += "<li><h3 class=\"matrix-title\">#{matrix_title}</h3>"

			statistics = "<table class=\"division\"><caption>Matrixresultaat</caption>"
			@parsed_tree[matrix_title][:group_results].each do |matrix_data|
  			statistics += "<tr><th>#{matrix_data[:title] || "Naamloos"}</th><td><div class=\"bar\" style=\"width: #{(matrix_data[:result] * 300.0).round}px\"></div>(#{"%.2f" % (matrix_data[:result] * 100.0)}%)</td></tr>"
			end
			statistics += "</table>"

			result += "<div class=\"matrix-content\">"
			result += statistics
			result += "<ul class=\"indicators\">"
			@parsed_tree[matrix_title][:indicators].keys.sort { |a, b| a.upcase <=> b.upcase }.each do |indicator_title|
				result += "<li><h3 class=\"indicator-title\">#{indicator_title}</h3>"

				statistics = "<table class=\"division\"><caption>Indicatorresultaat</caption>"
				@parsed_tree[matrix_title][:indicators][indicator_title][:indicator_results].each do |indicator_data|
					statistics += "<tr><th>#{indicator_data[:title] || "Naamloos"}</th><td><div class=\"bar\" style=\"width: #{(indicator_data[:result] * 300.0).round}px\"></div>(#{"%.2f" % (indicator_data[:result] * 100.0)}%)</td></tr>"
				end
				statistics += "</table>"

				result += "<div class=\"indicator-content\">"
				result += statistics
				result += "<ul class=\"questions\">"
				@parsed_tree[matrix_title][:indicators][indicator_title][:questions].keys.sort { |a, b| a.upcase <=> b.upcase }.each do |question_title|
					result += "<li><h3 class=\"question-title\">#{question_title}</h3>"
					result += "<div class=\"question-content\">"
					@parsed_tree[matrix_title][:indicators][indicator_title][:questions][question_title].each do |question_data|
						result += "<h3>#{question_data[:title]}</h3>#{question_data[:result]}"

					end
					result += "</div>"
					result += "</li>"
				end
				result += "</ul>"
				result += "</div>"
			end
			result += "</ul>"
			result += "</div>"
			result += "</li>"
		end
		result += <<-EOS
			</ul>
			</body>
			</html>
		EOS

		result
	end

	private

	def comment_to_html comment
		comment
#		comment.gsub("(", "<span class=\"group\">(</span>").
#			gsub(")", "<span class=\"group\">)</span>").
#			gsub(",", ", ").gsub(/\[([^\]]+)\]/, "[<span class=\"value\">\\1</span>]")
	end

	def add_score_tree group
		group.score_tree.each do |matrix, data|
			#puts matrix
			@parsed_tree[matrix] ||= { :group_results => [], :indicators => {} }
#				if data[:m_rule] == :na
			group_result = 0 #"(#{"%.2f" % data[:score]})"
#				else
#					group_result = "(#{"%.2f" % (data[:score] * 100.0)}% / 100%)"
#				end

			@parsed_tree[matrix][:group_results] << { :title => group.title, :result => group_result }
			group.score_tree[matrix][:indicators].each do |indicator, ind_data|
				#puts "- #{indicator}"				
				#if ind_data[:i_rule] == :na  or ind_data[:conversion] == :na
				group_result = 0 #"(#{"%.2f" % ind_data[:score]})"
#				else
#					group_result = "(#{"%.2f" % (ind_data[:score] * ind_data[:conversion] * 100.0)}% / #{"%.2f" % (ind_data[:conversion] * 100.0)}%)"
#				end

				@parsed_tree[matrix][:indicators][indicator] ||= { :indicator_results => [], :questions => {}}
				@parsed_tree[matrix][:indicators][indicator][:indicator_results] <<	{ :title => group.title, :result => group_result }

				group.score_tree[matrix][:indicators][indicator][:questions].each do |question, q_data|
					#puts "-- #{question}"

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
						score_values = {}

						q_data[:cloud].each do |key, value|
							score_value, count = * value
							max = count if count > max
							score_values[score_value] = {:label => key, :count => count}
						end

						statistics += "<table class=\"division\"><caption>Antwoordverdeling</caption>"

						score_values.keys.sort do |a, b|
							if (a.is_a? Numeric and b.is_a? String)
								1
							elsif (a.is_a? String and b.is_a? Numeric)
								-1
							elsif a.nil?
								-1
							elsif b.nil?
								1
							else
								a <=> b
							end
						end.each do |key|
							statistics += "<tr><th>#{score_values[key][:label] || "Geen mening / weet niet"}</th><td><div class=\"bar\" style=\"width: #{((score_values[key][:count] / max.to_f) * 300.0).round}px\"></div>#{score_values[key][:count]} (#{"%.2f" % ((score_values[key][:count] / q_data[:amount].to_f) * 100.0)}%)</td></tr>"
						end
						statistics += "</table>"
					end

					group_result = ""
#					if q_data[:score]
#						group_result = "(#{"%.2f" % q_data[:score]} uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#					else
#						factor = (q_data[:conversion] == :na ? 1.0 : q_data[:conversion]) *
#							(ind_data[:conversion] == :na ? 1.0 : ind_data[:conversion]) * 100.0
#						group_result = "(#{"%.2f" % (q_data[:score] * factor)}% / #{"%.2f" % factor}% uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#					end

					result = ""
					result += "<div class=\"statistics\">"
					result += statistics
					result += "<h4>toon individuele scores</h4>"
					result += "<div class=\"scores\">"
					result += "<ol>"
					(q_data[:meta_data] || []).each_with_index do |meta_data, index|
						result += "<li>#{meta_data[:score]} \"#{meta_data[:label]}\" (#{meta_data[:participant]})"
						result += "<p class=\"comment\">#{comment_to_html(meta_data[:comment])}</p>\n" if meta_data[:comment]
						result += "</li>\n"
					end
					result += "</ol></div>"
					result += "</div>"

					@parsed_tree[matrix][:indicators][indicator][:questions][question] ||= []
					@parsed_tree[matrix][:indicators][indicator][:questions][question] << {
						:title => group.title, :result => result
					}
				end
			end
		end
	end

end