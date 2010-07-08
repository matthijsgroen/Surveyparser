require 'rubygems'
require 'yaml'
require 'prawn'

class GraphRunner

	def initialize filename
		@configuration = YAML::load_file filename
	end

	def create_graphs output_filename
		puts "Generating graphs: #{output_filename}"
		Prawn::Document.generate(output_filename, :page_size => 'A4', :skip_page_creation => true) do |pdf|
			@configuration.each do |key, settings|
				graph_type = settings["type"]
				self.class.graph_writers.each do |writer|
					if writer.supports? graph_type
						pdf.start_new_page :page_size => 'A4'
						output_writer = writer.new pdf
						output_writer.create_graph settings
					end
				end
			end
		end		
	end

	def self.<< writer
		@graph_writers ||= []
		@graph_writers << writer 
	end

	def self.graph_writers
		@graph_writers || []
	end

end