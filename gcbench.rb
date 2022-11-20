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

# % ruby/build/bin/gem install benchmark-ips
# % ruby/build/bin/gem install RubyInline
# % ruby/build/bin/ruby --mmtk -I benchmark-ips/lib gcbench.rb
# % ruby/build/bin/ruby --mmtk -I benchmark-ips/lib gcbench.rb --cext

require 'benchmark/ips'

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
  if i_depth > 0
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
  # root = nil     what's the point of this?
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

use_cext = ARGV.delete('--cext')
raise unless ARGV.empty?

puts RUBY_DESCRIPTION

if use_cext
  require 'inline'

  module CExt
    inline do |builder|
      builder.prefix <<~C
        #define STRETCH_TREE_DEPTH #{STRETCH_TREE_DEPTH}

        static ID id_left;
        static ID id_right;
        static ID id_i;
        static ID id_j;
        static VALUE cNode;
        static VALUE zero;

        static int tree_size(int i) {
          return (1 << (i + 1)) - 1;
        }

        static int num_iters(int i) {
          return 2 * tree_size(STRETCH_TREE_DEPTH) / tree_size(i);
        }

        static VALUE new_node(VALUE left, VALUE right) {
          VALUE node = rb_obj_alloc(cNode);
          rb_ivar_set(node, id_left, left);
          rb_ivar_set(node, id_right, right);
          rb_ivar_set(node, id_i, zero);
          rb_ivar_set(node, id_j, zero);
          return node;
        }

        static void populate(int i_depth, VALUE this_node) {
          if (i_depth > 0) {
            i_depth -= 1;
            VALUE left = new_node(Qnil, Qnil);
            VALUE right = new_node(Qnil, Qnil);
            rb_ivar_set(this_node, id_left, left);
            rb_ivar_set(this_node, id_right, right);
            populate(i_depth, left);
            populate(i_depth, right);
          }
        }

        static VALUE make_tree(int i_depth) {
          if (i_depth <= 0) {
            return new_node(Qnil, Qnil);
          } else {
            return new_node(make_tree(i_depth - 1), make_tree(i_depth - 1));
          }
        }
      C

      builder.c <<~C
        void setup_cext(void) {
          id_left = rb_intern("@left");
          id_right = rb_intern("@right");
          id_i = rb_intern("@i");
          id_j = rb_intern("@j");
          cNode = rb_const_get(rb_cObject, rb_intern("Node"));
          zero = INT2FIX(0);
        }
      C

      builder.c <<~C
        void time_construction(int depth) {
          // VALUE root = Qnil;   what's the point of this?
          VALUE temp_tree = Qnil;
          int inum_iters = num_iters(depth);

          for (int i = 0; i < inum_iters; i++) {
            temp_tree = new_node(Qnil, Qnil);
            populate(depth, temp_tree);
            temp_tree = Qnil;
          }

          for (int i = 0; i < inum_iters; i++) {
            temp_tree = make_tree(depth);
            temp_tree = Qnil;
          }
        }
      C
    end
  end

  puts 'Using C extension'

  class Object
    prepend CExt
  end

  setup_cext
end

Benchmark.ips do |x|
  x.warmup = 10
  x.time = 30

  x.report do
    MIN_TREE_DEPTH.step(MAX_TREE_DEPTH, 2) do |d|
      time_construction d
    end
  end
end

pp GC.stat
