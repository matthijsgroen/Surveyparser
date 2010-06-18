#!/usr/bin/ruby1.8

require 'lib/runner.rb'

parser = Runner.new \
	:scoring_definition => "config/analysis.csv",
	:value_mapping => "config/mapping.csv",
	:panel_document => "config/checkmarket_results.csv"

# Q1 - Plaats: (1) amsterdam (2) arnhem (3) breda (4) den haag (5) diemen (6) eindhoven (7) eindhoven (campus) (8) groningen (9) hengelo (10) leeuwarden (11) maastricht (12) rotterdam (13) utrecht (14) voorburg (15) zwolle
# Q2 - KP/IP: (1) interim professional (2) kantoorprofessional
# Q3 - (1) bouw (2) civiel (3) ruimtelijke ontwikkeling (4) finance (5) hrm (6) ict (7) interim-management (8) legal (9) logistics & procurement (10) marketing & communicatie (11) technology

# - Eindhoven - KP + IP - BCRO+Legal - iedereen (totaal ingevuld + niet totaal ingevuld)
parser.run_with_filter "iedereen.html", "Eindhoven - KP + IP - BCRO+Legal - iedereen" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1", "2" # IP + KP
	filter.question "q3", nil, "1", "2", "3", "8" # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
end

# - Eindhoven - KP + IP - BCRO+Legal - totaal ingevuld
parser.run_with_filter "ingevult.html", "Eindhoven - KP + IP - BCRO+Legal - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1", "2" # IP + KP
	filter.question "q3", nil, "1", "2", "3", "8" # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - BCRO+Legal - totaal ingevuld
parser.run_with_filter "ip-bcro-legal.html", "Eindhoven - IP - BCRO+Legal - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", nil, "1", "2", "3", "8" # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - Bouw - totaal ingevuld
parser.run_with_filter "ip-bouw.html", "Eindhoven - IP - Bouw - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "1" # Bouw
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - Civiel - totaal ingevuld
parser.run_with_filter "ip-civiel.html", "Eindhoven - IP - Civiel - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "2" # Civiel
	filter.meta_data "Einde bereikt", "1"
end

# - Eindhoven - IP - RO+Legal - totaal ingevuld
parser.run_with_filter "ip-ro-legal.html", "Eindhoven - IP - RO+Legal - totaal ingevuld" do |filter|
	filter.question "q1", "6" # Eindhoven
	filter.question "q2", "1" # IP
	filter.question "q3", "3", "8" # RO + Legal
	filter.meta_data "Einde bereikt", "1"
end
