
class TriLinear

	def initialize pdf_writer
		@pdf = pdf_writer
	end

	BIG_ANGLE = Math::PI / 3.0

	def create_graph graph_data
		puts "Creating trilinear diagram: #{graph_data["title"]}"
		raise "Can't render graph type: #{graph_data["type"]}" unless self.class.supports? graph_data["type"]

		max_x = (@pdf.margin_box.right - @pdf.margin_box.left)
		max_y = (@pdf.margin_box.top - @pdf.margin_box.bottom)
		middle_x = max_x / 2.0
		middle_y = (max_y / 2.0) - 30

		# reset colors
		@pdf.stroke_color "000000"
		@pdf.fill_color "000000"
		@pdf.text_box(graph_data["title"] || "", {
			:at => [0, max_y - 20],
			:width => max_x,
			:align => :center,
			:size => 10
		})

		@axis_names = {
			:left_axis => graph_data["left-axis"]["alias"],
			:bottom_axis => graph_data["bottom-axis"]["alias"],
			:right_axis => graph_data["right-axis"]["alias"]
		}

		@layout = graph_data["layout"] || {}

		setup_triangle middle_x, middle_y, (@layout["size"] || 300).to_i
	 	draw_axis :left_axis, graph_data["left-axis"]["name"]
	 	draw_axis :bottom_axis, graph_data["bottom-axis"]["name"]
	 	draw_axis :right_axis, graph_data["right-axis"]["name"]
		draw_triangle

		dots = { }
		graph_data["data"].each_with_index do |data_point, index|
			points = [data_point[@axis_names[:left_axis]].to_f,
								data_point[@axis_names[:bottom_axis]].to_f,
								data_point[@axis_names[:right_axis]].to_f]

			points_sum = ((points[0] + points[1] + points[2]) * 1000.0).round
			raise "points in entry #{index + 1} (#{points * ", "}) are not 1.0" unless points_sum == 1000
			dots[points] ||= 0
			dots[points] += 1
		end
		puts "plotting #{graph_data["data"].length} dots, #{dots.length} unique locations."

		dots.each do |coord, amount|
			res = coord + [amount]
			draw_point(*res)
		end

	end
	
	def self.supports? type
		["trilinear"].include? type
	end

	private

	def setup_triangle x, y, size
		@metric_data = {
			:middle => [x, y],
			:size => size,
			:point_a => [x, y + size],
			:point_b => [x - (Math.sin(BIG_ANGLE * 2.0) * size), y + (Math.cos(BIG_ANGLE * 2.0) * size)],
			:point_c => [x + (Math.sin(BIG_ANGLE * 2.0) * size), y + (Math.cos(BIG_ANGLE * 2.0) * size)],
		}
		@axis = {
			:left_axis => {
				:start => @metric_data[:point_a],
				:end => @metric_data[:point_b],
			},
			:bottom_axis => {
				:start => @metric_data[:point_b],
				:end => @metric_data[:point_c]
			},
			:right_axis => {
				:start => @metric_data[:point_c],
				:end => @metric_data[:point_a]
			}
		}
		[:left_axis, :bottom_axis, :right_axis].each do |axis|
			@axis[axis][:length] = Math.sqrt(((@axis[axis][:end][0] - @axis[axis][:start][0]) ** 2) +
				((@axis[axis][:end][1] - @axis[axis][:start][1]) ** 2))
		end

	end

	def draw_triangle
		@layout["border"] ||= {}

		@pdf.stroke_color(@layout["border"]["color"] || "000000")
		@pdf.line_width = (@layout["border"]["width"] || 2.0).to_f

		@pdf.move_to *@metric_data[:point_a]
		@pdf.line_to *@metric_data[:point_b]
		@pdf.line_to *@metric_data[:point_c]
		@pdf.line_to *@metric_data[:point_a]
		@pdf.stroke

		@pdf.stroke_color "000000"
		@pdf.line_width = 0.5
		@pdf.move_to *@metric_data[:middle]
		@pdf.line_to *percentage_on_axis(:left_axis, 0.5)
		@pdf.stroke

		@pdf.move_to *@metric_data[:middle]
		@pdf.line_to *percentage_on_axis(:bottom_axis, 0.5)
		@pdf.stroke

		@pdf.move_to *@metric_data[:middle]
		@pdf.line_to *percentage_on_axis(:right_axis, 0.5)
		@pdf.stroke
	end

	def percentage_on_axis axis, percentage
		scale = @axis[axis]
		[scale_line(scale[:start][0], scale[:end][0], percentage),
		 scale_line(scale[:start][1], scale[:end][1], percentage)]
	end

	def scale_line scale_min, scale_max, percentage
		scale_min + ((scale_max - scale_min) * percentage)
	end

	AXIS_ROTATION = {
		:bottom_axis => 0,
		:right_axis => -60,
		:left_axis => 60
	}

	def draw_axis axis, label
		@layout["label"] ||= {}
		label_font_size = (@layout["label"]["font-size"] || 18).to_f
		@layout["scale"] ||= {}
		scale_font_size = (@layout["scale"]["font-size"] || 12).to_f
		line_width = (@layout["scale"]["width"] || 0.5).to_f
		line_color = @layout["scale"]["color"] || "dddddd"
		alignment = (@layout["label"]["align"] || "right")

		rotation = AXIS_ROTATION[axis]

		correction = text_rotation_correction(rotation, 2, scale_font_size)
		amount = @layout["scale"]["steps"] || 5
		step = 1.0 / amount

		(amount + 1).times do |index|
			line_on_axis axis, index * step, line_width, line_color

			percentage = ((index * step) - (0.05 * (index * step)))
			percentage = 1 - percentage if axis != :bottom_axis

			value = (index * step)
			value = 1 - value if axis != :bottom_axis

			point = percentage_on_axis(axis, percentage)

			@pdf.text_box("#{(value * 100.0).round}%" , {
				:at => [point[0] + correction[0], point[1] + correction[1]],
				:size => scale_font_size,
				:width => 80,
				:height => 30,
				:align => :left,
				:rotate => rotation,
				:rotate_around => :bottom_left
			})
		end

		label_correction = text_rotation_correction(rotation, scale_font_size + 2, label_font_size)
		at = if rotation == 0
			[@axis[axis][:start][0] + label_correction[0], @axis[axis][:start][1] + label_correction[1]]
		else
			[@axis[axis][:end][0] + label_correction[0], @axis[axis][:end][1] + label_correction[1]]
		end

		align = alignment == "left" ? rotation == 0 ? :left : :right : rotation == 0 ? :right : :left
		align = :center if alignment == "center"

		@pdf.text_box(label, {
			:at => at,
			:size => label_font_size,
			:width => @axis[axis][:length],
			:height => label_font_size * 1.5,
			:align => align,
			:rotate => rotation,
			:rotate_around => :bottom_left
		})
	end

	def text_rotation_correction(rotation, size, font_size)
		if rotation == 0
			[0, - (size + 2)]
		else
			angle = rotation < 0 ? Math::PI / 3.0 : - (Math::PI / 3.0)
			[(Math.sin(angle) * (size + font_size)), (Math.cos(angle) * (size + font_size))]
		end		
	end

	RENDER_AXIS = {
		:bottom_axis => [:bottom_axis, :right_axis],
		:right_axis => [:right_axis, :left_axis],
		:left_axis => [:left_axis, :bottom_axis]
	}

	def line_on_axis axis, percentage, width, color
		point_a = percentage_on_axis RENDER_AXIS[axis][0], percentage
		point_b = percentage_on_axis RENDER_AXIS[axis][1], (1.0 - percentage)

		@pdf.stroke_color color
		@pdf.line_width = width
		@pdf.move_to *point_a
		@pdf.line_to *point_b
		@pdf.stroke
	end

	def draw_point(left, bottom, right, weight)
		@layout["point"] ||= {}
		color = @layout["point"]["color"] || "FF0000"
		width = (@layout["point"]["width"] || 2.0).to_f
		width = width * (1.1 * weight)

		point_a = percentage_on_axis RENDER_AXIS[:bottom_axis][0], bottom
		point_b = percentage_on_axis RENDER_AXIS[:bottom_axis][1], (1.0 - bottom)
		point_c = percentage_on_axis RENDER_AXIS[:bottom_axis][1], right

		max_y = @metric_data[:point_a][1] - @metric_data[:point_c][1]
	  value = point_c[1] - @metric_data[:point_c][1]
		percentage = (value / max_y)
		#puts "#{percentage} = #{value} / #{max_y}"

		linear_function = ((point_b[0] - point_a[0]) / (point_b[1] - point_a[1])) * (point_c[1] - point_a[1])

		end_point = [point_a[0] + linear_function, point_c[1]]


		@pdf.fill_color color
		@pdf.fill_circle_at end_point, :radius => width

	end


end

GraphRunner << TriLinear