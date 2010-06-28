require 'rubygems'
require 'fastercsv'

class ResultParser

	# 0 "E-mailadres";
	# 1 "Achternaam";
	# 2 "Voornaam";
	# 3 "Taal";
	# 4 "Optioneel veld 1";
	# 5 "Datum toegevoegd";
	# 6 "Datum uitgenodigd";
	# 7 "Datum e-mail bekeken";
	# 8 "Datum doorgeklikt";
	# 9 "Datum herinnerd (niet geantwoord)";
	# 10 "Datum herinnerd (gedeeltelijk geantwoord)";
	# 11 "Datum geantwoord";
	# 12 "Einde bereikt";
	# 13 "Invultijd (seconden)";
	# 14 "Distributiemethode";
	# 15 "Browser";
	# 16 "Besturingssysteem";
	# 17 "IP";
	# 18 "Geolocatie (via IP)";

	META_DATA_BOUNDARY = 18
	
	def initialize scoring_filename, mapping_filename
		@value_mapping = ValueMapping.new mapping_filename
		@scoring_configuration = ScoringConfiguration.new scoring_filename
		reset!
	end

	def reset!
		@results = []
		@merged_result = nil
	end

	# Go through the file row by row, and calculate the scores for each row
	def parse_results filename, label_filename, filter = {}
		@results = []
		data = []
		label_data = []
		begin
			FasterCSV.foreach(filename) { |row| data << row }			
		rescue FasterCSV::MalformedCSVError => e
			puts "#{e.message} for file: #{filename} on line #{data.length + 1}"
			raise
		end

		begin
			FasterCSV.foreach(label_filename) { |row| label_data << row }
		rescue FasterCSV::MalformedCSVError => e
			puts "#{e.message} for file: #{label_filename} on line #{label_data.length + 1}"
			raise
		end

		field_names = data.shift
		data.each_with_index do |row, row_index| # each row is a participants result set. handle colum for column

			data_hash = { :meta_data => {}, :question_data => {}, :label_data => {} }
			field_names.each_with_index do |name, column_index|
				key = column_index > META_DATA_BOUNDARY ? :question_data : :meta_data
				data_hash[key][name] = row[column_index]
				data_hash[:label_data][name] = { row[column_index] => label_data[row_index][column_index] }
			end
			data_hash[:meta_data][:full_name] = "#{data_hash[:meta_data]["Voornaam"]} " +
				"#{data_hash[:meta_data]["Optioneel veld 1"]} #{data_hash[:meta_data]["Achternaam"]}" 

			@results << @scoring_configuration.parse_results(data_hash, @value_mapping) if match_filter(data_hash, filter)
		end
		raise "Er komt niemand door het filter! #{filter.inspect}" if @results.empty?
		@results
	end

	def scoring_rules
		@scoring_configuration.scoring_rules
	end

	private

	def match_filter data_hash, filter
		return true if filter.empty?
		(filter[:meta_data] || {}).each do |key, values|
			values = [values] unless values.is_a? Array
			return false unless values.include? data_hash[:meta_data][key].to_s
		end
		(filter[:question_data] || {}).each do |key, values|
			values = [values] unless values.is_a? Array
			return false unless values.include? data_hash[:question_data][key].to_s
		end
		return true
	end

end