require 'graphs/graph_runner.rb'
require 'graphs/spider.rb'

runner = GraphRunner.new "config/graphs.yaml"
runner.create_graphs "graphs.pdf"