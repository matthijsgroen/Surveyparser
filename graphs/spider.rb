
class Spider

	def initialize pdf_writer
		@pdf = pdf_writer
		@axis = {}
	end

	def create_graph graph_data
		raise "Can't render graph type: #{graph_data["type"]}" unless self.class.supports? graph_data["type"]

		max_x = (@pdf.margin_box.right - @pdf.margin_box.left)
		max_y = (@pdf.margin_box.top - @pdf.margin_box.bottom)
		middle_x = max_x / 2.0
		middle_y = max_y / 2.0
		middle_y += 100.0

		axis_layout = graph_data["axis_layout"] || { }
		max_length = (axis_layout["max_span"] || 200.0).to_f
		build_axis(graph_data["axis"], {
				:middle_x => middle_x,
				:middle_y => middle_y,
				:axis_color => axis_layout["color"] || "000000",
				:axis_width => (axis_layout["width"] || 1.0).to_f,
				:scale_length => (axis_layout["scale_length"] || 3.0).to_f,
				:scale_width => (axis_layout["scale_width"] || 1.0).to_f,
				:label_font_size => (axis_layout["label_font_size"] || 8.0).to_f,
				:value_font_size => (axis_layout["value_font_size"] || 8.0).to_f,
				:max_span => max_length
			})
		legend = graph_data["legend"] || {}
		font_size = (legend["font_size"] || 20.0).to_f
		graph_data["data"].each_with_index do |settings, index|

			y = middle_y - (max_length + 30.0 + (index * (font_size * 1.67)))
			@pdf.fill_color = "000000"
			@pdf.text_box(settings["name"],
						 :at => [(font_size * 1.67), y - (font_size / 6.0)],
						 :size => font_size,
						 :width => 200)
			@pdf.line_width = 0.5
			@pdf.fill_color = settings["color"]
			@pdf.fill_and_stroke_rectangle([4, y], font_size, font_size)

			draw_values settings["values"], settings["color"]
		end
	end

	def self.supports? type
		["spider"].include? type
	end

	private

	DEG_RAD = (180.0 / Math::PI)
	RAD_CIRCLE = 2.0 * Math::PI
	QUARTER_CIRCLE = Math::PI / 2.0

	def build_axis(axis_data, options )
		@axis = {}
		@axis_keys = []
		axis_data.each do |data|
			@axis_keys << data["key"].to_sym

			data["min"] ||= 0.0
			data["max"] ||= 1.0
			data["step"] ||= 0.2

			@axis[data["key"].to_sym] = {
					:name => data["name"],
					:min => data["min"],
					:max => data["max"],
					:step => data["step"],
					:label_font_size => options[:label_font_size],
					:value_font_size => options[:value_font_size],
					:color => options[:axis_color],
					:width => options[:axis_width],
					:scale_width => options[:scale_width],
					:scale_length => options[:scale_length]
				}
		end
		steps = @axis_keys.length

		@axis_keys.each_with_index do |key, index|
			angle = angle_part(steps, index)
			angle_deg = angle * DEG_RAD

			x_angle = Math.cos angle
			y_angle = Math.sin angle

			label_x_angle = Math.cos(angle - QUARTER_CIRCLE)
			label_y_angle = Math.sin(angle - QUARTER_CIRCLE)

			x_angle2 = Math.cos angle_part(steps, index + 1)
			y_angle2 = Math.sin angle_part(steps, index + 1)
			margin_bottom = 20
			@axis[key][:calculations] = {
				:angle_rad => angle,
				:angle_deg => angle_deg,
				:left_side_angle => [x_angle, y_angle],
				:right_side_angle => [x_angle2, y_angle2],
				:left_side_right_angle => [label_x_angle, label_y_angle],
				:middle => [options[:middle_x], options[:middle_y]],
				:margin_bottom => margin_bottom,
				:max_span => options[:max_span]
			}

			@pdf.stroke_color options[:axis_color]
			@pdf.line_width = options[:axis_width]
			@pdf.move_to options[:middle_x] + (x_angle * options[:max_span]), options[:middle_y] + (y_angle * options[:max_span])
			@pdf.line_to options[:middle_x] + (x_angle * margin_bottom), options[:middle_y] + (y_angle * margin_bottom)
			@pdf.line_to options[:middle_x] + (x_angle2 * margin_bottom), options[:middle_y] + (y_angle2 * margin_bottom)
			@pdf.stroke

			write_scale @axis[key]

			write_axis @axis[key][:max], @axis[key]
			write_axis @axis[key][:min], @axis[key]
			write_axis 0, @axis[key] if @axis[key][:max] > 0 and @axis[key][:min] < 0
			label_axis @axis[key]
		end
	end

	def write_axis value, axis_info
		c = axis_info[:calculations]
		scale = (value.to_f - axis_info[:min]) / (axis_info[:max] - axis_info[:min])
		height = (scale * ((c[:max_span] - 5) - (c[:margin_bottom] + 10))) + (c[:margin_bottom] + 10) + (axis_info[:value_font_size] / 2.0)

		@pdf.text_box(value.to_s,
					 :at => [c[:middle][0] + (c[:left_side_angle][0] * height) + (c[:left_side_right_angle][0] * (axis_info[:scale_length] + 0.5)),
									 c[:middle][1] + (c[:left_side_angle][1] * height) + (c[:left_side_right_angle][1] * (axis_info[:scale_length] + 0.5))],
					 :size => axis_info[:value_font_size],
					 :width => 40,
					 :height => 20,
					 :rotate => c[:angle_deg] - 90.0,
					 :rotate_around => :upper_left)
	end

	def write_scale axis_info
		c = axis_info[:calculations]
		return unless axis_info[:step] and axis_info[:step] > 0
		strokes = (axis_info[:max] - axis_info[:min]) / axis_info[:step].to_f

		(strokes.ceil + 1.0).to_i.times do |stroke|
			scale = (stroke * axis_info[:step].to_f) / (axis_info[:max].to_f - axis_info[:min].to_f)
			height = (scale * ((c[:max_span] - 5.0) - (c[:margin_bottom] + 10))) + (c[:margin_bottom] + 10)

			#puts "#{axis_info[:max]} #{scale}"

			@pdf.stroke_color axis_info[:color]
			@pdf.line_width = axis_info[:scale_width]
			
			@pdf.move_to c[:middle][0] + (c[:left_side_angle][0] * height) + (c[:left_side_right_angle][0] * axis_info[:scale_length]),
									 c[:middle][1] + (c[:left_side_angle][1] * height) + (c[:left_side_right_angle][1] * axis_info[:scale_length])
			@pdf.line_to c[:middle][0] + (c[:left_side_angle][0] * height) - (c[:left_side_right_angle][0] * axis_info[:scale_length]),
									 c[:middle][1] + (c[:left_side_angle][1] * height) - (c[:left_side_right_angle][1] * axis_info[:scale_length])
			@pdf.stroke

		end
	end

	def draw_values values, color
		first = nil
		last = nil
		@axis_keys.reverse.each do |key|
			c = @axis[key][:calculations]
			value = values[key.to_s].to_f
			scale = (value - @axis[key][:min]) / (@axis[key][:max] - @axis[key][:min])
			height = (scale * ((c[:max_span] - 5) - (c[:margin_bottom] + 10))) + (c[:margin_bottom] + 10)

			first = height if first.nil?

			@pdf.fill_color color
			write_axis value, @axis[key]

			unless last.nil?
				@pdf.stroke_color color
				@pdf.line_width = 1.0
				@pdf.move_to c[:middle][0] + (c[:left_side_angle][0] * height), c[:middle][1] + (c[:left_side_angle][1] * height)
				@pdf.line_to c[:middle][0] + (c[:right_side_angle][0] * last), c[:middle][1] + (c[:right_side_angle][1] * last)
				@pdf.stroke
			end
			last = height
		end

		if last and first
			c = @axis[@axis_keys.reverse[0]][:calculations]
			@pdf.stroke_color color
			@pdf.line_width = 1.0
			@pdf.move_to c[:middle][0] + (c[:left_side_angle][0] * first), c[:middle][1] + (c[:left_side_angle][1] * first)
			@pdf.line_to c[:middle][0] + (c[:right_side_angle][0] * last), c[:middle][1] + (c[:right_side_angle][1] * last)
			@pdf.stroke
		end
	end

	def label_axis axis_info
		c = axis_info[:calculations]

		@pdf.text_box(axis_info[:name],
					 :at => [c[:middle][0] + (c[:left_side_angle][0] * (c[:max_span] + 5)),
									 c[:middle][1] + (c[:left_side_angle][1] * (c[:max_span] + 5))],
					 :size => axis_info[:label_font_size],
					 :width => 80,
					 :height => 30,
					 :rotate => c[:angle_deg],
					 :rotate_around => :upper_left)
	end

	def angle_part steps, index
		rad_step = RAD_CIRCLE / steps

		start_angle = (Math::PI / 2.0)
		angle = start_angle - (rad_step * index)
		angle += RAD_CIRCLE if angle < -Math::PI
		angle
	end

end

GraphRunner << Spider