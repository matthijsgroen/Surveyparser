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
              :main_bar_width => 100,
              :indent => 30,
              :sub_bar_width => 30
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

        pdf.bounding_box([0, pdf.y - pdf.page.margins[:top]], :width => @options[:text_width]) do
          bars << create_bar(matrix_data, :width => @options[:main_bar_width])
          pdf.text matrix_title, :style => :bold, :size => @options[:font_size]
          pdf.move_down 4

          pdf.indent(@options[:indent]) do
            matrix_data[:indicators].each do |indicator_title, indicator_data|
              next if indicator_data[:progress] == :na
              bars << create_bar(indicator_data, :width => @options[:sub_bar_width])          
              pdf.text indicator_title, :style => :normal, :size => @options[:font_size]
              pdf.move_down 4
            end
          end
        end
        bars.each { |bar| generate_bar bar }
      end
    end

    def generate_bar(bar)
      p = bar[:data][:progress]

      total_width = bar[:options][:width]

      pdf.fill_color @options[:bar_color]

      percentage = (p[:progress] - p[:min]) / (p[:max] - p[:min])
      bar_width = percentage * total_width
      pdf.fill_rectangle [@options[:text_width] + 4, bar[:y_pos] - pdf.page.margins[:top]], bar_width, @options[:font_size]
      pdf.stroke_color @options[:font_color]
      pdf.stroke_rectangle [@options[:text_width] + 4, bar[:y_pos] - pdf.page.margins[:top]], total_width, @options[:font_size]
      pdf.fill_color @options[:font_color]
      pdf.text_box "#{(percentage * 100.0).round}%", 
        :width => @options[:font_size] * "100%".length * 0.8,
        :at => [@options[:text_width] + 4 + total_width, bar[:y_pos] - pdf.page.margins[:top]],
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