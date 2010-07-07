
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

		max_length = 200.0

		build_axis(graph_data["axis"], {
				:middle_x => middle_x,
				:middle_y => middle_y,
				:axis_color => "000000",
				:axis_width => 1.0,
				:max_span => max_length		
			})
		graph_data["data"].each_with_index do |settings, index|
			y = middle_y - (max_length + 30.0 + (index * 20.0))
			@pdf.text_box(settings["name"],
						 :at => [20, y],
						 :size => 12,
						 :width => 200)
			@pdf.line_width = 0.5
			@pdf.fill_color = settings["color"]
			@pdf.fill_and_stroke_rectangle([4, y], 10, 10)
			@pdf.fill_color = "000000"

			settings["values"].each do |key, value|
				draw_line value, settings["color"], @axis[key.to_sym]
			end
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
		axis_keys = []
		axis_data.each do |key, data|
			axis_keys << key.to_sym
			data = { "name" => data, "min" => 0.0, "max" => 1.0 } if data.is_a? String
			@axis[key.to_sym] = {
					:name => data["name"],
					:min => data["min"],
					:max => data["max"],
				}
		end
		steps = axis_keys.length

		axis_keys.each_with_index do |key, index|
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

			write_axis @axis[key][:max], @axis[key]
			write_axis @axis[key][:min], @axis[key]
			write_axis 0, @axis[key] if @axis[key][:max] > 0 and @axis[key][:min] < 0
			label_axis @axis[key]

		end
	end

	def write_axis value, axis_info
		c = axis_info[:calculations]
		scale = (value.to_f - axis_info[:min]) / (axis_info[:max] - axis_info[:min])
		height = (scale * ((c[:max_span] - 5) - (c[:margin_bottom] + 10))) + (c[:margin_bottom] + 10)

		@pdf.text_box(value.to_s,
					 :at => [c[:middle][0] + (c[:left_side_angle][0] * height) + (c[:left_side_right_angle][0] * 2.0),
									 c[:middle][1] + (c[:left_side_angle][1] * height) + (c[:left_side_right_angle][1] * 2.0)],
					 :size => 8,
					 :width => 40,
					 :height => 20,
					 :rotate => c[:angle_deg] - 90.0,
					 :rotate_around => :upper_left)
	end

	def draw_line value, color, axis_info
		c = axis_info[:calculations]
		scale = (value.to_f - axis_info[:min]) / (axis_info[:max] - axis_info[:min])
		height = (scale * ((c[:max_span] - 5) - (c[:margin_bottom] + 10))) + (c[:margin_bottom] + 10)

		@pdf.stroke_color color
		@pdf.line_width = 1.0
		@pdf.move_to c[:middle][0] + (c[:left_side_angle][0] * height), c[:middle][1] + (c[:left_side_angle][1] * height)
		@pdf.line_to c[:middle][0] + (c[:right_side_angle][0] * height), c[:middle][1] + (c[:right_side_angle][1] * height)
		@pdf.stroke

	end

	def label_axis axis_info
		c = axis_info[:calculations]

		@pdf.text_box(axis_info[:name],
					 :at => [c[:middle][0] + (c[:left_side_angle][0] * (c[:max_span] + 5)),
									 c[:middle][1] + (c[:left_side_angle][1] * (c[:max_span] + 5))],
					 :size => 8,
					 :width => 80,
					 :height => 30,
					 :rotate => c[:angle_deg],
					 :rotate_around => :upper_left)
	end

	def angle_part steps, index
		rad_step = RAD_CIRCLE / steps

		start_angle = (Math::PI / 2.0)
		angle = start_angle + (rad_step * index)
		angle -= RAD_CIRCLE if angle > Math::PI
		angle
	end

end

GraphRunner << Spider