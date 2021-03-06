#!/usr/bin/ruby1.8

require 'lib/runner.rb'

parser = Runner.new \
	:scoring_definition => "config/analysis.csv",
	:value_mapping => "config/mapping.csv",
	:panel_document => "config/checkmarket_results.csv",
	:label_document => "config/checkmarket_results_label.csv",
	:report_title => "Yacht test rapportage"

# Q1 - Plaats: (1) amsterdam (2) arnhem (3) breda (4) den haag (5) diemen (6) eindhoven (7) eindhoven (campus) (8) groningen (9) hengelo (10) leeuwarden (11) maastricht (12) rotterdam (13) utrecht (14) voorburg (15) zwolle
# Q2 - KP/IP: (1) interim professional (2) kantoorprofessional
# Q3 - (1) bouw (2) civiel (3) ruimtelijke ontwikkeling (4) finance (5) hrm (6) ict (7) interim-management (8) legal (9) logistics & procurement (10) marketing & communicatie (11) technology

# - Eindhoven - KP + IP - BCRO+Legal - iedereen (totaal ingevuld + niet totaal ingevuld)
parser.run_with_filter "iedereen" do |filter|
	filter.question "q1", 6 # Eindhoven
	filter.question "q2", 1, 2 # IP + KP
	filter.question "q3", nil, 1, 2, 3, 8 # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
end

# - Eindhoven - KP + IP - BCRO+Legal - totaal ingevuld
parser.run_with_filter "totaal ingevuld" do |filter|
	filter.question "q1", 6 # Eindhoven
	filter.question "q2", 1, 2 # IP + KP
	filter.question "q3", nil, 1, 2, 3, 8 # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
	filter.meta_data "Einde bereikt", 1
end

# - Eindhoven - IP - BCRO+Legal - totaal ingevuld
parser.run_with_filter "IP - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", nil, "1", "2", "3", "8" # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - Bouw - totaal ingevuld
parser.run_with_filter "IP - Bouw - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "1" # Bouw
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - Civiel - totaal ingevuld
parser.run_with_filter "IP - Civiel - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "2" # Civiel
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - RO+Legal - totaal ingevuld
parser.run_with_filter "IP - RO+Legal - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "3", "8" # RO + Legal
	filter.meta_data "Einde bereikt", "1"
end

#parser.write_output

parser.write_output_pdf "matrix_facetten.pdf",
        :font => "Tahoma",
        :font_size => 9,
        :text_width => 100,
        :font_color => "000000",
        :bar_color => "FAC090",
        :negative_bar_color => "303030", # new!
				:dividers => 4, # new!
				:main_bar_width => 100,
        :sub_bar_width => 30,
        :indent => 10,
        :filter => "totaal ingevuld"

#parser.write_tri_linear_output "groep.yaml", "config/auto-graph-top.yaml", {
#		:social => "BESLG_1 / 15.0",
#		:economy => "BESLG_2 / 15.0",
#		:ecology => "BESLG_3 / 15.0"
#	}
#
#parser.write_tri_linear_output "ik.yaml", "config/auto-graph-top.yaml", {
#		:social => "BESLI_1 / 15.0",
#		:economy => "BESLI_2 / 15.0",
#		:ecology => "BESLI_3 / 15.0"
#	}
#
