class HtmlWriter

	def initialize options
		@options = options
		@parsed_tree = {}
	end

	def add_results * groups
		groups.each { |group| add_score_tree group }
	end

	def output
		abc = ('a'..'z').to_a;
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
			statistics = progress_chart(@parsed_tree[matrix_title][:group_results], "Matrixresultaat")
			result += "<div class=\"matrix-content\">"
			result += statistics
			result += "<ul class=\"indicators\">"
			@parsed_tree[matrix_title][:indicators].keys.sort { |a, b| a.upcase <=> b.upcase }.each do |indicator_title|
				i_data = @parsed_tree[matrix_title][:indicators][indicator_title][:indicator_results]
				result += "<li><h3 class=\"indicator-title\">#{indicator_title} #{i_data[0][:scale] == :na ? "" : "(#{(i_data[0][:scale] * 100.0)}%)"}</h3>"
				result += "<div class=\"indicator-content\">"
				result += progress_chart(i_data, "Indicatorresultaat")
				result += "<ul class=\"questions\">"
				@parsed_tree[matrix_title][:indicators][indicator_title][:questions].keys.sort { |a, b| a.upcase <=> b.upcase }.each do |question_title|
					q_data = @parsed_tree[matrix_title][:indicators][indicator_title][:questions][question_title]
					result += "<li><h3 class=\"question-title\">#{question_title} #{q_data[0][:scale] == :na ? "" : "(#{(q_data[0][:scale] * 100.0)}%)"}</h3>"
					result += "<div class=\"question-content\">"
					result += progress_chart(q_data, "vraagresultaat")
					result += "<ul class=\"tabbar\">"
					tabs = ""
					first_tab = true
					@parsed_tree[matrix_title][:indicators][indicator_title][:questions][question_title].each do |question_data|
						key = ""; 6.times { |i| key += abc[rand(abc.length)] }

						result += "<li class=\"tab #{first_tab ? "selected" : ""}\"><a href=\"##{key}\">#{question_data[:title]}</a></li>"
						tabs += "<div class=\"detail_tab\" style=\"#{first_tab ? "" : "display: none;"}\" id=\"#{key}\"><h3>#{question_data[:title]}</h3>#{question_data[:content]}</div>"
						first_tab = false
					end
					result += "</ul>"
					result += tabs
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
	end

	def add_score_tree group
		group.score_tree.each do |matrix, data|
			#puts matrix
			@parsed_tree[matrix] ||= { :group_results => [], :indicators => {} }

			@parsed_tree[matrix][:group_results] << { :title => group.title, :progress => data[:progress] }
			group.score_tree[matrix][:indicators].each do |indicator, ind_data|
				#puts "- #{indicator}"				
				@parsed_tree[matrix][:indicators][indicator] ||= { :indicator_results => [], :questions => {}}
				@parsed_tree[matrix][:indicators][indicator][:indicator_results] <<	{ :title => group.title, :progress => ind_data[:progress], :scale => ind_data[:conversion] }

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
						:title => group.title, :content => result, :progress => q_data[:progress], :scale => q_data[:conversion]
					}
				end
			end
		end
	end

	def progress_chart(data, title)
		result_rows = 0
		statistics = "<table class=\"division\"><caption>#{title}</caption>"
		data.each do |progress_row|
			statistics += "<tr><th>#{progress_row[:title] || "Naamloos"}</th>"
			if progress_row[:progress] == :na
				statistics += "<td colwidth=\"4\">Geen resultaat</td>"
			else
				begin
					result = "<td>#{progress_row[:progress][:min]}</td>"

					if (progress_row[:progress][:min] < 0)
						result += "<td class=\"barbox\">"
						if (progress_row[:progress][:progress] < 0)
							result += "(#{"%.2f" % progress_row[:progress][:progress]})"
							result += "<div class=\"bar\" style=\"width: #{((progress_row[:progress][:progress].to_f / progress_row[:progress][:min].to_f) * 300.0).round}px\"></div>"
						end
						result += "</td>"
					end
					if (progress_row[:progress][:max] > 0)
						result += "<td class=\"barbox\">"
						if (progress_row[:progress][:progress] >= 0)
							p = progress_row[:progress][:progress].to_f
							p = p - progress_row[:progress][:min] if progress_row[:progress][:min] > 0.0

							result += "<div class=\"bar\" style=\"width: #{((p / progress_row[:progress][:max].to_f) * 300.0).round}px\"></div>"
							result += "(#{"%.2f" % progress_row[:progress][:progress]})"
						end				
						result += "</td>"
					end

					result += "<td>#{progress_row[:progress][:max]}</td>"
					result_rows += 1
					statistics += result
				rescue
					statistics += "<td colwidth=\"4\">Geen resultaat</td>"
				end
			end
			statistics += "</tr>"
		end
		statistics += "</table>"

		return "" if result_rows == 0
		statistics
	end

end