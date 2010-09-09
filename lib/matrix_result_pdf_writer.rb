require 'prawn'

class MatrixResultPdfWriter

  def initialize output_filename, options, &block
    Prawn::Document.generate(output_filename, :page_size => 'A4', :skip_page_creation => true) do |pdf|

      fonts_folder = File.expand_path(File.dirname(__FILE__) + "/../fonts")
      pdf.font_families.update "Tahoma" => {
        :bold => "#{fonts_folder}/tahomabd.ttf",
        :normal => "#{fonts_folder}/tahoma.ttf"
      }

      helper = WriteTools.new pdf, options
      yield helper
    end
  end

  private

  class WriteTools

    def initialize writer, options
      @pdf = writer
      @options = {
              :font => "Tahoma",
              :font_size => 12,
              :text_width => 200,
              :font_color => "000000",
              :bar_color => "808080",
							:negative_bar_color => "303030",
              :main_bar_width => 100,
              :indent => 30,
              :sub_bar_width => 30,
							:dividers => 4
      }.merge options
    end
    attr_reader :pdf

    def write_group group
      group.score_tree.each do |matrix_title, matrix_data|
        next if matrix_data[:progress] == :na
        pdf.start_new_page
        pdf.font @options[:font]
        pdf.text group.title
        pdf.move_down 40

        bars = []
				parts = @options[:dividers]
				box_top = pdf.y - pdf.page.margins[:top]
        pdf.bounding_box([0, box_top], :width => @options[:text_width]) do
					pdf.move_down @options[:font_size] * 1.3
					bars << create_bar(matrix_data, :width => @options[:main_bar_width], :indicators_width => @options[:main_bar_width])
          pdf.text matrix_title, :style => :bold, :size => @options[:font_size]
          pdf.move_down 4

          pdf.indent(@options[:indent]) do
            matrix_data[:indicators].each do |indicator_title, indicator_data|
              next if indicator_data[:progress] == :na
              next if indicator_data[:conversion] == :na 
							bar_width = @options[:main_bar_width] * indicator_data[:conversion]
							puts bar_width
							bars << create_bar(indicator_data, :width => bar_width, :indicators_width => @options[:main_bar_width])
              pdf.text indicator_title, :style => :normal, :size => @options[:font_size]
              pdf.move_down 4
            end
          end
        end
				write_percentages parts, :y => box_top if parts > 0
        bars.each { |bar| generate_bar bar, parts }
      end
    end

		def write_percentages(amount = 4, options = {})
			y_pos = pdf.y
			part = 1.0 / amount

			y_pos = options[:y]
			left = @options[:text_width] #+ 4
			width = @options[:main_bar_width]
			(amount + 1).times do |index|

				pdf.stroke_color @options[:font_color]
				pdf.fill_color @options[:font_color]

				pdf.text_box "#{(part * index * 100.0).round}%",
					:width => @options[:font_size] * "100%".length * 0.8,
					:at => [left + (width * part * index), y_pos],
					:align => :left,
					:size => @options[:font_size]
			end
		end

    def generate_bar(bar, parts = 4)
      p = bar[:data][:progress]

      total_width = bar[:options][:width]
			bar_start = @options[:text_width] + 4

			pdf.fill_color @options[:bar_color]
			pdf.stroke_color @options[:bar_color]
			bar_top = bar[:y_pos] - pdf.page.margins[:top]

			(parts + 1).times do |index|
				x = bar_start + ((bar[:options][:indicators_width] / parts) * index)
				pdf.stroke_line x, bar_top + 2, x, bar_top - @options[:font_size] - 2
			end if parts > 0

			if total_width < 0
				total_width *= -1
				p[:min] *= -1
				p[:max] *= -1
				p[:progress] *= -1
				pdf.fill_color @options[:negative_bar_color]
				pdf.stroke_color @options[:negative_bar_color]
				#bar_start += bar[:options][:indicators_width]
				#text_start = bar_start
			end
			text_start = @options[:text_width] + 4 + total_width

			percentage = (p[:progress] - p[:min]) / (p[:max] - p[:min])
      bar_width = percentage * total_width
      pdf.fill_rectangle [bar_start, bar_top], bar_width, @options[:font_size]
      pdf.stroke_color @options[:font_color]
      pdf.stroke_rectangle [bar_start, bar_top], total_width, @options[:font_size]
      pdf.fill_color @options[:font_color]
      pdf.text_box "#{(percentage * 100.0).round}%", 
        :width => @options[:font_size] * "100%".length * 0.8,
        :at => [text_start, bar_top],
        :align => :right,
        :size => @options[:font_size]

    end

    def create_bar(data, options)
      {
        :data => data,
        :options => options,
        :y_pos => pdf.y 
      }
    end

  end

end