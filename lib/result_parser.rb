class ResultParser

	def initialize configuration
		@config = configuration
		@answer_structure = {}
	end

	def read filename
		@answer_structure = {}

		data = FasterCSV.read(filename)
		start_row = 1

		start_row.times do data.shift end
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
			



		end
	end

	class QuestionStatistic

		

	end

end