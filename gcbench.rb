# This is adapted from a benchmark written by John Ellis and Pete Kovac
# of Post Communications.
# It was modified by Hans Boehm of Silicon Graphics.
#
# This is no substitute for real applications.  No actual application
#	is likely to behave in exactly this way.  However, this benchmark was
#	designed to be more representative of real applications than other
#	Java GC benchmarks of which we are aware.
#	It attempts to model those properties of allocation requests that
#	are important to current GC techniques.
#	It is designed to be used either to obtain a single overall performance
#	number, or to give a more detailed estimate of how collector
#	performance varies with object lifetimes.  It prints the time
#	required to allocate and collect balanced binary trees of various
#	sizes.  Smaller trees result in shorter object lifetimes.  Each cycle
#	allocates roughly the same amount of memory.
#	Two data structures are kept around during the entire process, so
#	that the measured performance is representative of applications
#	that maintain some live in-memory data.  One of these is a tree
#	containing many pointers.  The other is a large array containing
#	double precision floating point numbers.  Both should be of comparable
#	size.
#
#	The results are only really meaningful together with a specification
#	of how much memory was used.  It is possible to trade memory for
#	better time performance.  This benchmark should be run in a 32 MB
#	heap, though we don't currently know how to enforce that uniformly.
#
#	Unlike the original Ellis and Kovac benchmark, we do not attempt
# measure pause times.  This facility should eventually be added back
#	in.  There are several reasons for omitting it for now.  The original
#	implementation depended on assumptions about the thread scheduler
#	that don't hold uniformly.  The results really measure both the
#	scheduler and GC.  Pause time measurements tend to not fit well with
#	current benchmark suites.  As far as we know, none of the current
#	commercial Java implementations seriously attempt to minimize GC pause
#	times.
#
#	Known deficiencies:
#		- No way to check on memory use
#		- No cyclic data structures
#		- No attempt to measure variation with object size
#		- Results are sensitive to locking cost, but we dont
#		  check for proper locking
#
# Translated to Ruby by Noel Padavan and Chris Seaton

# % git clone https://github.com/evanphx/benchmark-ips 
# % ruby/build/bin/ruby --mmtk -I benchmark-ips/lib gcbench.rb

require "benchmark/ips"

class Node
  attr_accessor :left, :right, :i, :j

  def initialize(left = nil, right = nil)
    @left = left
    @right = right
    @i = 0
    @j = 0
  end
end

STRETCH_TREE_DEPTH = 18
LONG_LIVED_TREE_DEPTH = 16
ARRAY_SIZE = 500_000
MIN_TREE_DEPTH = 4
MAX_TREE_DEPTH = 16

# Nodes used by a tree of a given size
def tree_size(i)
  (1 << (i + 1)) - 1
end

# Number of iterations to use for a given tree depth
def num_iters(i)
  2 * tree_size(STRETCH_TREE_DEPTH) / tree_size(i)
end

# Build tree top down, assigning to older objects.
def populate(i_depth, this_node)
  if i_depth <= 0
    nil
  else
    i_depth -= 1
    this_node.left = Node.new
    this_node.right = Node.new
    populate i_depth, this_node.left
    populate i_depth, this_node.right
  end
end

# Build tree bottom-up
def make_tree(i_depth)
  if i_depth <= 0
    Node.new
  else
    Node.new(make_tree(i_depth - 1), make_tree(i_depth - 1))
  end
end

# Construct two trees, one top-down the other bottom-up
def time_construction(depth)
  root = nil
  temp_tree = nil
  inum_iters = num_iters(depth)

  inum_iters.times do
    temp_tree = Node.new
    populate depth, temp_tree
    temp_tree = nil
  end

  inum_iters.times do
    temp_tree = make_tree(depth)
    temp_tree = nil
  end
end

# Stretch the memory space quickly
temp_tree = make_tree(STRETCH_TREE_DEPTH)
temp_tree = nil

# Create a long lived object
long_lived_tree = Node.new
populate LONG_LIVED_TREE_DEPTH, long_lived_tree

# Create long-lived array, filling half of it
long_lived_array = Array.new(ARRAY_SIZE)

(ARRAY_SIZE / 2).times do |i|
  i += 1
  long_lived_array[i] = 1.0 / i
end

puts RUBY_DESCRIPTION

Benchmark.ips do |x|
  x.warmup = 10
  x.time = 30

  x.report do
    MIN_TREE_DEPTH.step(MAX_TREE_DEPTH, 2) do |d|
      time_construction d
    end
  end
end
