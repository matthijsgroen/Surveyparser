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

		print "Pre calculating results"
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
		writer = HtmlWriter.new :title => @report_title
		writer.add_results *@target_groups

#		#puts merged_result.as_s
		File.open(@output_file, 'w') do |output_file|
			output_file.puts writer.output
		end
	end

	def write_tri_linear_output name, template_filename, formulas
		value_mapper = ValueMapping.new @value_mapping

		filename = convert_to_filename(name) + ".yaml"
		puts "Writing: #{filename} for trilinear diagram"

		File.open filename, "w" do |output|
			@target_groups.each do |target_group|
				output.puts " "
				output.puts "# Trilineair diagram voor #{target_group.title}"
				output.puts "#{convert_to_filename(target_group.title)}:"

				File.open template_filename, "r" do |template_input|
					template_input.each do |line|
						output.puts line
					end
				end

				participants = []
				target_group.scores.each do |score|
					next if participants.include? score[:participant]
					participants << score[:participant]

					calculation_data = score[:question_data][:row_values].merge :value => nil

					score[:participant][:question_data].each do |key, data|
						new_keys = value_mapper.map key.upcase
						if new_keys
							new_keys.each do |new_key|
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
					end


					results = {}
					sum = 0
					formulas.each do |key, formula_string|
						formula = Formula.new formula_string
						result = formula.call calculation_data
						sum += (result || 0)
						results[key] = result
					end

					if sum == 1
						output.puts "    -"
						results.each do |key, value|
							output.puts "      #{key}: #{value || 0}"
						end
					end
				end
			end
		end
	end

	private

	def convert_to_filename text
		text.downcase.
			gsub(/[éëèẽê]/i, 'e').
			gsub(/[íĩìï]/i, 'i').
			gsub(/[öóòõ]/i, 'o').
			gsub(/[ç]/i, 'c').
			gsub(/[üúùũ]/i, 'u').
			gsub(/[äáàã]/i, 'a').
			gsub(/[ß]/i, 'b').
			gsub(/[^a-z0-9()-]+/i, '_').
			gsub(/(.*)_$/, '\1')
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



