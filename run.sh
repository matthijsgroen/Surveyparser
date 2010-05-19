#!/usr/bin/ruby1.8

require 'lib/formula.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/result_parser.rb'
require 'pp'

result_parser = ResultParser.new \
  "config/test4-vragen.csv",
  "config/paneltest2-ingevult.csv"

results = result_parser.parse_results
merged_result = ScoringResult.merge results

File.open("result.html", 'w') do |output_file|
  output_file.puts merged_result.as_html
end

