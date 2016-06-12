
require "parser/current"
require "pp"

# ruby [String] a ruby program
# @return a dot graph string
def call_graph(ruby)
  ast = Parser::CurrentRuby.parse(ruby)
  defs = defs_from_ast(ast)
  def_names = defs.map {|d| def_name(d) }

  defs_to_calls = {}
  defs.each do |d|
    calls = calls_from_def(d)
    call_names = calls.map {|c| send_name(c)}
    call_names = call_names.find_all{ |cn| def_names.include?(cn) }
    defs_to_calls[def_name(d)] = call_names
  end

  dot_from_hash(defs_to_calls)
end

def def_name(node)
  name, _args, _body = *node
  name
end

def send_name(node)
  _receiver, name, *_args = *node
  name
end

class Defs < Parser::AST::Processor
  def initialize
    @defs = []
    @sends = []
  end

  def defs_from_ast(ast)
    @defs = []
    process(ast)
    @defs
  end

  def sends_from_ast(ast)
    @sends = []
    process(ast)
    @sends
  end

  def on_def(node)
    @defs << node
    super
  end

  def on_send(node)
    @sends << node
    super
  end
end

def defs_from_ast(ast)
  Defs.new.defs_from_ast(ast)
end

def calls_from_def(ast)
  Defs.new.sends_from_ast(ast)
end

def dot_from_hash(graph)
  dot = ""
  dot << "digraph g {\n"
  dot << "rankdir=LR;\n"
  graph.keys.sort.each do |vertex|
    destinations = graph[vertex].sort
    dot << "\"#{vertex}\"[href=\"/#{vertex}\"];\n"
    destinations.each do |d|
      dot << "\"#{vertex}\" -> \"#{d}\";\n"
    end
  end
  dot << "}\n"
  dot
end

