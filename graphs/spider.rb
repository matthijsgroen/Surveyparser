
class Spider

	def initialize pdf_writer
		@pdf = pdf_writer
	end

	def create_graph graph_data
		raise "Can't render graph type: #{graph_data["type"]}" unless self.class.supports? graph_data["type"]

		middle_x = (@pdf.margin_box.right - @pdf.margin_box.left) / 2.0
		middle_y = (@pdf.margin_box.top - @pdf.margin_box.bottom) / 2.0
		middle_y += 50.0

		max_length = 150.0

		build_axis(graph_data["axis"], {
				:middle_x => middle_x,
				:middle_y => middle_y,
				:axis_color => "ff4040",
				:axis_width => 2.0,
				:max_span => 150		
			})
	end

	def self.supports? type
		["spider"].include? type
	end

	private

	def build_axis(axis_data, options )
		@axis = {}
		axis_keys = []
		axis_data.each do |key, data|
			axis_keys << key.to_sym
			data = { "name" => data, "min" => 0.0, "max" => 1.0 } if data.is_a? String
			@axis[key.to_sym] = {
					:name => data["name"],
					:min => data["min"],
					:max => data["max"]				
				}
		end
		angle_step = 360.0 / axis_keys.length

		@pdf.stroke_color options[:axis_color]
		@pdf.line_width = options[:axis_width]
		@pdf.move_to options[:middle_x], options[:middle_y]
		@pdf.line_to options[:middle_x], options[:middle_y] + options[:max_span]
		@pdf.stroke


	end

end

GraphRunner << Spider