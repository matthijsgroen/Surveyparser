require 'lib/formula.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/value_mapping.rb'
require 'lib/result_parser.rb'
require 'lib/html_writer.rb'
require 'pp'

class Runner

	def initialize(options)
		@scoring_definition = options[:scoring_definition]
		@value_mapping = options[:value_mapping]
		@panel_document = options[:panel_document]
		@panel_label_document = options[:label_document]
		@output_file = options[:output_file] || "resultaat.html"
		@report_title = options[:report_title] || "Analyse rapport"

		puts "Pre calculating results..."
		@parser = ResultParser.new @scoring_definition, @value_mapping
		@results = @parser.parse_results @panel_document, @panel_label_document

		@target_groups = []
	end

	def run_with_filter(title, &block)
		puts "Gegevens filteren voor: #{title}"
		filter = FilterReader.new
		yield filter
		@target_groups << ScoringResult.merge_with_filter(@results, filter.map, title)
	end

	def write_output filename = nil
		@output_file = filename if filename
		puts "Writing output file: #{@output_file}"
		

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



