#!/usr/bin/ruby1.8

require 'lib/formula.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/result_parser.rb'
require 'pp'

result_parser = ResultParser.new \
  "config/test3-vragen.csv",
  "config/paneltest2.csv"

result_parser.parse_results

