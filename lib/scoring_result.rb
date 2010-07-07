class ScoringResult

	def initialize participant_data, value_mapper, title = "Naamloos"
		@scores = []
		@score_tree = nil
		@title = title
		@participant_data = participant_data
		@value_mapper = value_mapper
	end

	attr_reader :scores, :participant_data, :value_mapper, :title

	#	@scoring_map[question_id] = {
	#		:matrix_tile => mapped_row["matrixvak"],
	#		:matrix_conversion => convert_score_text(mapped_row["score in matrixvak"]),
	#
	#		:indicator => mapped_row["indicator"],
	#		:indicator_conversion => convert_score_text(mapped_row["score in indicator"]),
	#
	#		:question => mapped_row["vraag"],
	#		:question_id => row_index,
	#		:question_label_id => mapped_row["codering"],
	#
	#		:formula => Formula.new(answer_formula),
	#		:group_formula => Formula.new(group_formula),
	#
	#		:row_values => mapped_row
	#	}
	def plot_data question_data
		raise "No conversion rate given for \"score in matrixvak\"" if question_data[:matrix_conversion].nil?
		raise "No conversion rate given for \"score in indicator\"" if question_data[:indicator_conversion].nil? # no scoring known for this question
		#puts question_data[:question]

		calculation_data = question_data[:row_values].merge :value => nil
		formula = question_data[:formula]

		participant_data[:question_data].each do |key, data|
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

		begin
			sustainability_score = formula.call calculation_data
		rescue StandardError => error
			puts "Error doing calculation: #{formula.to_string calculation_data} #{error}"
			raise
		end
		#puts question_data[:question_label_id]

		field_text = nil
		unless sustainability_score.nil?
			str_value = case sustainability_score
				when Numeric: str_value = "%.2f" % sustainability_score
				when String: str_value = sustainability_score
			end
			field_text = str_value
			if fields = @value_mapper.reverse_map(question_data[:question_label_id])
				fields.each do |field|
					label = participant_data[:label_data][field.to_s]
					field_text = "#{label} (#{str_value})" if label
				end
			end
		end
		#puts field_text

		#return if sustainability_score.nil? # no opinion / don't know
		comment = "#{sustainability_score} = #{formula.solve(calculation_data)}"

		add_scores question_data, sustainability_score, comment, field_text
	end

	#	@scoring_map[question_id] = {
	#		:matrix_tile => mapped_row["matrixvak"],
	#		:matrix_conversion => convert_score_text(mapped_row["score in matrixvak"]),
	#
	#		:indicator => mapped_row["indicator"],
	#		:indicator_conversion => convert_score_text(mapped_row["score in indicator"]),
	#
	#		:question => mapped_row["vraag"],
	#
	#		:formula => Formula.new(answer_formula),
	#		:group_formula => Formula.new(group_formula),
	#
	#		:row_values => mapped_row
	#	}
	def add_scores question_data, question_score, comment, field_text
		@scores << {
			:participant => participant_data,
			:question_data => question_data.dup,

			:question_score => question_score,
			:comment => comment,
			:label => field_text
		}
		@score_tree = nil
	end

	def convert_score_text text
		return [nil, nil] if text.nil?
		return [nil, :na] if text == "X"
		if result = text.match(/^(-?\d+)%$/i)
			return [result[0].to_i / 100.0, :percentage]
		end
		if result = text.match(/^(-?\d+)$/i)
			return [result[0].to_i, :numeric]
		end
		return [nil, nil]
	end

	def merge other_result, filter = {}
		@scores += other_result.scores if match_filter(other_result.participant_data, filter)
		@score_tree = nil
	end

	def self.merge_with_filter result_list, filter = {}, title = "Naamloos"
		result = self.new nil, nil, title
		result_list.each { |single_result| result.merge single_result, filter }
		result
	end

	def score_tree
		@score_tree = parse_score_tree unless @score_tree
		@score_tree
	end

	private

	#	:participant => meta_data,
	#	:question_data => question_data,
	#
	#	:question_score => question_score,
	#	:score_type => score_type,
	#	:comment => comment
	def parse_score_tree
		question_scores = {}
		@scores.each do |participant_question_score|
#			puts "#{participant_question_score[:participant][:full_name]}: " +
#				"#{participant_question_score[:question_data][:question]} #{participant_question_score[:question_score].inspect}"

			q_id = participant_question_score[:question_data][:question_id]
			unless question_scores[q_id]
				scores = []
				labels = []
				meta_data = []
				@scores.collect do |score_row|
					if score_row[:question_data][:question_id] == q_id
						scores << score_row[:question_score]
						labels << [score_row[:label], score_row[:question_score]] 
						meta_data << {
							:comment => score_row[:comment],
							:participant => score_row[:participant][:meta_data]["Datum doorgeklikt"], # :full_name
							:score => score_row[:question_score],
							:label => score_row[:label]
						}
					end
				end

				question_scores[q_id] = {
					:matrix_tile => participant_question_score[:question_data][:matrix_tile],
					:indicator => participant_question_score[:question_data][:indicator],
					:question => participant_question_score[:question_data][:question],
					:matrix_conversion => participant_question_score[:question_data][:matrix_conversion],
					:indicator_conversion => participant_question_score[:question_data][:indicator_conversion],
					:question_data => participant_question_score[:question_data],
					:question_code => participant_question_score[:question_data][:question_label_id], 
					:scores => scores,
					:labels => labels,
					:meta_data => meta_data,
					:total_amount => scores.length,
					:amount => scores.compact.length
				}

				begin
					sum = 0.0
					scores.each { |score| sum += score if score }
					question_scores[q_id][:sum] = sum
					question_scores[q_id][:average] = sum / question_scores[q_id][:amount]
				rescue TypeError
				end
				cloud = {}
				question_scores[q_id][:labels].each do |term|
					label, score = *term
					cloud_term = term.to_s
					cloud[label] ||= [score, 0]
					cloud[label][1] += 1
				end
				question_scores[q_id][:cloud] = cloud
			end
		end
		#puts question_scores.inspect
		tree = {}
		question_scores.each do |key, data|
			tree[data[:matrix_tile]] ||= { :indicators => {}, :score => 0.0, :m_rule => data[:matrix_conversion] }
			tree[data[:matrix_tile]][:indicators][data[:indicator]] ||= { :score => 0.0, :questions => {}, :conversion => data[:matrix_conversion], :i_rule => data[:indicator_conversion] }

			calculation_data = data[:question_data][:row_values].merge :value => data[:average]
			formula = data[:question_data][:group_formula]
			group_score = formula.call calculation_data
			group_score_comment = formula.solve calculation_data

			progress = calculate_progress(group_score, data)

			tree[data[:matrix_tile]][:indicators][data[:indicator]][:questions][data[:question]] = {
				:score => data[:average],
				:results => data[:scores],
				:cloud => data[:cloud],
				:meta_data => data[:meta_data],
				:conversion => data[:indicator_conversion],
				:question_code => data[:question_code],
				:question_type => data[:question_type],
				:amount => data[:amount],
				:total_amount => data[:total_amount],
				:sum => data[:sum],
				:average => data[:average],
				:group_score => group_score,
				:group_score_comment => group_score_comment,
				:progress => progress
			}
		end

		tree.each do |key, matrix_data|
			mp = nil
			m_score = 0
			matrix_data[:indicators].each do |indicator, indicator_data|
				ip = nil
				i_score = 0
				indicator_data[:questions].each do |q, question_data|
					if question_data[:progress].is_a? Hash and not question_data[:conversion] == :na
						ip = { :min => question_data[:progress][:min], :max => question_data[:progress][:max] } if ip.nil?

						#puts "#{@title} - #{q} #{question_data[:progress].inspect}" if key == "invloed"
						if ip[:min] == question_data[:progress][:min] and ip[:max] == question_data[:progress][:max]
							i_score += question_data[:progress][:progress] * question_data[:conversion] unless question_data[:progress][:progress].nan?
						end
					end
				end
				ip[:progress] = i_score unless ip.nil?
				tree[key][:indicators][indicator][:progress] = ip || :na

				if ip.is_a? Hash and not indicator_data[:conversion] == :na
					if mp.nil?
						mp = { :min => ip[:min], :max => ip[:max] }
					end
					if mp[:min] == ip[:min] and mp[:max] == ip[:max]
						m_score += ip[:progress] * indicator_data[:conversion]
					end
				end
			end
			mp[:progress] = m_score unless mp.nil?
			tree[key][:progress] = mp || :na
		end

		tree
	end

	def calculate_progress(score, info)
		#puts "min: #{info[:question_data][:question_scoring][:min]} max: #{info[:question_data][:question_scoring][:max]}"
		
		min = convert_score_text info[:question_data][:question_scoring][:min]
		max = convert_score_text info[:question_data][:question_scoring][:max]
		return :na unless min[1] == :numeric and max[1] == :numeric
		{ 
			:min => min[0],
			:max => max[0],
			:progress => score	
		}
	end

	def match_filter data_hash, filter
		return true if filter.empty?
		(filter[:meta_data] || {}).each do |key, values|
			values = [values] unless values.is_a? Array
			return false unless values.collect(&:to_s).include? data_hash[:meta_data][key].to_s
		end
		(filter[:question_data] || {}).each do |key, values|
			values = [values] unless values.is_a? Array
			return false unless values.collect(&:to_s).include? data_hash[:question_data][key].to_s
		end
		return true
	end
	
end