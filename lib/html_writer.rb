
class HtmlWriter

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
							score_values = {}

							q_data[:cloud].each do |key, value|
								score_value, count = *value
								max = count if count > max
								score_values[score_value] = { :label => key, :count => count }
							end

							statistics += "<table><caption>Antwoordverdeling</caption>"

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

#						if q_data[:score]
#							group_result = "(#{"%.2f" % q_data[:score]} uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#						else
#							factor = (q_data[:conversion] == :na ? 1.0 : q_data[:conversion]) *
#								(ind_data[:conversion] == :na ? 1.0 : ind_data[:conversion]) * 100.0
#							group_result = "(#{"%.2f" % (q_data[:score] * factor)}% / #{"%.2f" % factor}% uit #{q_data[:amount]}) = (#{"%.4f" % q_data[:sum]} / #{q_data[:amount]})"
#						end

						result += "<li><span class=\"question\">#{(question || "(geen vraag)").gsub("\n", " ")} (#{q_data[:question_code]}) #{group_result}</span>\n"
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

end