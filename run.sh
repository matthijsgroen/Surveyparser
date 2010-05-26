#!/usr/bin/ruby1.8

require 'lib/formula.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/result_parser.rb'
require 'pp'

def run_results(checkmarket_set, result_parser, filter, output_file, title)
  puts "Gegevens verwerken voor: #{output_file}"
  result_parser.reset!
  results = result_parser.parse_results checkmarket_set, filter
  merged_result = ScoringResult.merge results

  #puts merged_result.as_s
  File.open(output_file, 'w') do |output_file|
    output_file.puts merged_result.as_html(:title => title)
  end
end

scoring_definition = "config/test4-vragen.csv"
result_parser = ResultParser.new scoring_definition

# Q1 - Plaats: (1) amsterdam (2) arnhem (3) breda (4) den haag (5) diemen (6) eindhoven (7) eindhoven (campus) (8) groningen (9) hengelo (10) leeuwarden (11) maastricht (12) rotterdam (13) utrecht (14) voorburg (15) zwolle
# Q2 - KP/IP: (1) interim professional (2) kantoorprofessional
# Q3 - (1) bouw (2) civiel (3) ruimtelijke ontwikkeling (4) finance (5) hrm (6) ict (7) interim-management (8) legal (9) logistics & procurement (10) marketing & communicatie (11) technology

# - Eindhoven - KP + IP - BCRO+Legal - iedereen (totaal ingevuld + niet totaal ingevuld)
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => ["1", "2"], # IP + KP
      "q3" => [nil, "1", "2", "3", "8"] # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
  } }, "iedereen.html", "Eindhoven - KP + IP - BCRO+Legal - iedereen"

# - Eindhoven - KP + IP - BCRO+Legal - totaal ingevuld
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => ["1", "2"], # IP + KP
      "q3" => [nil, "1", "2", "3", "8"] # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
    },
    :meta_data => { "Einde bereikt" => "1" }
  }, "ingevult.html", "Eindhoven - KP + IP - BCRO+Legal - totaal ingevuld"

# - Eindhoven - IP - BCRO+Legal - totaal ingevuld
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => "1", # IP
      "q3" => ["1", "2", "3", "8"] # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
    },
    :meta_data => { "Einde bereikt" => "1" }
  }, "ip-bcro-legal.html", "Eindhoven - IP - BCRO+Legal - totaal ingevuld"

# - Eindhoven - IP - Bouw - totaal ingevuld
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => "1", # IP
      "q3" => "1" # Bouw
    },
    :meta_data => { "Einde bereikt" => "1" }
  }, "ip-bouw.html", "Eindhoven - IP - Bouw - totaal ingevuld"

# - Eindhoven - IP - Civiel - totaal ingevuld
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => "1", # IP
      "q3" => "2" # Civiel
    },
    :meta_data => { "Einde bereikt" => "1" }
  }, "ip-civiel.html", "Eindhoven - IP - Civiel - totaal ingevuld"

# - Eindhoven - IP - RO+Legal - totaal ingevuld
run_results "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010526102232.csv", result_parser,
  { :question_data => {
      "q1" => "6", # Eindhoven
      "q2" => "1", # IP
      "q3" => ["3", "8"] # RO + Legal
    },
    :meta_data => { "Einde bereikt" => "1" }
  }, "ip-ro-legal.html", "Eindhoven - IP - RO+Legal - totaal ingevuld"
