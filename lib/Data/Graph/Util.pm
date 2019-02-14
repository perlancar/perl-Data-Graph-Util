package Data::Graph::Util;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(toposort is_cyclic is_acyclic);

sub _toposort {
    my $graph = shift;

    # this is the Kahn algorithm, ref:
    # https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm

    my %in_degree;
    for my $k (keys %$graph) {
        $in_degree{$k} //= 0;
        for (@{ $graph->{$k} }) { $in_degree{$_}++ }
    }

    # collect nodes with no incoming edges (in_degree = 0)
    my @S;
    for (keys %in_degree) { unshift @S, $_ if $in_degree{$_} == 0 }

    my @L;
    while (@S) {
        my $n = pop @S;
        push @L, $n;
        for my $m (@{ $graph->{$n} }) {
            if (--$in_degree{$m} == 0) {
                unshift @S, $m;
            }
        }
    }

    if (@L == keys(%$graph)) {
        if (@_) {
            no warnings 'uninitialized';
            # user specifies a list to be sorted according to @L. this is like
            # Sort::ByExample but we implement it ourselves to avoid dependency.
            my %pos;
            for (0..$#L) { $pos{$L[$_]} = $_+1 }
            return (0, [
                sort { ($pos{$a} || @L+1) <=> ($pos{$b} || @L+1) } @{$_[0]}
            ]);
        } else {
            return (0, \@L);
        }
    } else {
        # there is a cycle
        return (1, \@L);
    }
}

sub toposort {
    my ($err, $res) = _toposort(@_);
    die "Can't toposort(), graph is cyclic" if $err;
    @$res;
}

sub is_cyclic {
    my ($err, $res) = _toposort(@_);
    $err;
}

sub is_acyclic {
    my ($err, $res) = _toposort(@_);
    !$err;
}

1;
# ABSTRACT: Utilities related to graph data structure

=head1 SYNOPSIS

 use Data::Graph::Util qw(toposort is_cyclic is_acyclic);

 # return nodes that satisfy the following graph: a must come before b, b must
 # come before c & d, and d must come before c.

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
 ); # => ("a", "b", "d", "c")

 # sort specified nodes (2nd argument) using the graph. nodes not mentioned in
 # the graph will be put at the end. duplicates are not removed.

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], d=>["c"] },
     ["e", "a", "b", "a"]
 ); # => ("a", "a", "b", "e")

 # check if a graph is cyclic

 say is_cyclic ({a=>["b"]}); # => 0
 say is_acyclic({a=>["b"]}); # => 1

 # check if a graph is acyclic (not cyclic)

 say is_cyclic ({a=>["b"], b=>["c"], c=>["a"]}); # => 1
 say is_acyclic({a=>["b"], b=>["c"], c=>["a"]}); # => 0


=head1 DESCRIPTION

Early release. More functions will be added later.


=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 toposort(\%graph[ , \@nodes ]) => sorted list

Perform a topological sort on graph (currently using the Kahn algorithm). Will
return the nodes of the graph sorted topologically. Will die if graph cannot be
sorted, e.g. when graph is cyclic.

If C<\@nodes> is specified, will instead return C<@nodes> sorted according to
the topological order. Duplicates are allowed and not removed. Nodes not
mentioned in graph are also allowed and will be put at the end.

=head2 is_cyclic(\%graph) => bool

Return true if graph contains at least one cycle. Currently implemented by
attempting a topological sort on the graph. If it can't be performed, this means
the graph contains cycle(s).

=head2 is_acyclic(\%graph) => bool

Return true if graph is acyclic, i.e. contains no cycles. The opposite of
C<is_cyclic()>.


=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Graph_(abstract_data_type)>

L<https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm>

L<Sort::Topological> can also sort a DAG, but cannot handle cyclical graph.
