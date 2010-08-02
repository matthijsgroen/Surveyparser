require 'graphs/graph_runner.rb'
require 'graphs/spider.rb'
require 'graphs/tri_linear.rb'

runner = GraphRunner.new "ik.yaml"
runner.create_graphs "graphs.pdf"