require 'rubygems'
require 'fastercsv'

class ResultParser

	def initialize scoring_filename, results_filename
		@scoring_configuration = ScoringConfiguration.new scoring_filename
		@results_filename = results_filename
		@results = []
		@merged_result = nil
	end

	# Go through the file row by row, and calculate the scores for each row
	def parse_results
		@results = []
		data = []
		begin
			FasterCSV.foreach(@results_filename) { |row| data << row }			
		rescue FasterCSV::MalformedCSVError => e
			puts "#{e.message} for file: #{@results_filename} on line #{data.length + 1}"
			return
		end

		field_names = data.shift
		data.each_with_index do |row, index| # each row is a participants result set. handle colum for column
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
			data_hash = { :meta_data => {}, :question_data => {} }
			field_names.each_with_index do |name, index|
				key = index > 18 ? :question_data : :meta_data
				data_hash[key][name] = row[index]
			end
			data_hash[:meta_data][:full_name] = "#{data_hash[:meta_data]["Voornaam"]} " +
				"#{data_hash[:meta_data]["Optioneel veld 1"]} #{data_hash[:meta_data]["Achternaam"]}" 

			@results << @scoring_configuration.parse_results(data_hash)
		end

		@merged_result = ScoringResult.merge @results
		@merged_result.present_results
	end

end