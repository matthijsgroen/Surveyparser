require 'lib/formula.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/value_mapping.rb'
require 'lib/result_parser.rb'
require 'pp'

class Runner

	def initialize(options)
		@scoring_definition = options[:scoring_definition]
		@value_mapping = options[:value_mapping]
		@panel_document = options[:panel_document]

		@parser = ResultParser.new @scoring_definition, @value_mapping
	end

	def run_with_filter(filename, title, &block)
		puts "Gegevens verwerken voor: #{filename}"
		
		filter = FilterReader.new
		yield filter

		@parser.reset!
		#pp @parser.scoring_rules

		results = @parser.parse_results @panel_document, filter.map
		merged_result = ScoringResult.merge results
		#pp merged_result

		#puts merged_result.as_s
		File.open(filename, 'w') do |output_file|
			output_file.puts merged_result.as_html(:title => title)
		end
	end

	class FilterReader

		def initialize
			@map = {
				:question_data => {},
				:meta_data => {}
			}
		end

		def map
			@map
		end

		def question(question, *answers)
			@map[:question_data][question] = answers
		end

		def meta_data(question, *answers)
			@map[:meta_data][question] = answers
		end
	end


end



