#!/usr/bin/ruby1.8

require 'lib/enquire_result.rb'
require 'lib/scoring_configuration.rb'
require 'lib/scoring_result.rb'
require 'lib/result_parser.rb'

result_parser = ResultParser.new \
  "config/test1-vragen.csv",
  "config/Panelleden-Onbewerkte-gegevens-10187-13865-2010422141342.csv"



