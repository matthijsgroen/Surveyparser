require 'rubygems'
require 'fastercsv'

class ValueMapping

	def initialize filename
		data = FasterCSV.read filename
		data.shift

		# Kolom lijst:
		#	matrixvak
		#	score in matrixvak
		#	indicator
		#	score in indicator
		#	vraag
		#	groepsformule
		#	antwoordformule
		@mapping = {}
		@reverse_mapping = {}
		data.each do |csv_row|
			@mapping[csv_row[1].upcase] = csv_row[0].downcase.to_sym
			@reverse_mapping[csv_row[0].upcase] = csv_row[1].downcase.to_sym  
		end
	end

	def map var_name
		return nil unless @mapping.has_key? var_name
		@mapping[var_name]
	end

	def reverse_map var_name
		return nil unless @reverse_mapping.has_key? var_name
		@reverse_mapping[var_name]
	end

end