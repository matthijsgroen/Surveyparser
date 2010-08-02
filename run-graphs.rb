require 'graphs/graph_runner.rb'
require 'graphs/spider.rb'
require 'graphs/tri_linear.rb'

runner = GraphRunner.new "config/graph-example.yaml"
runner.create_graphs "graphs.pdf"

if File.exist? "ik.yaml"
	runner = GraphRunner.new "ik.yaml"
	runner.create_graphs "ik.pdf"
end

if File.exists? "groep.yaml"
	runner = GraphRunner.new "groep.yaml"
	runner.create_graphs "groep.pdf"
end
