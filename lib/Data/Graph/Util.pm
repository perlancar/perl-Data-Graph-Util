package Data::Graph::Util;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(toposort is_cyclic is_acyclic);

sub _toposort {
    #no warnings 'uninitialized';

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
        return (0, \@L);
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

 my @sorted = toposort(
     { a=>["b"], b=>["c", "d"], c=>[], d=>["c"] }, # graph
 ); # => ("a", "b", "d", "c")

 say is_cyclic ({a=>["b"]}); # => 0
 say is_acyclic({a=>["b"]}); # => 1

 say is_cyclic ({a=>["b"], b=>["c"], c=>["a"]}); # => 1
 say is_acyclic({a=>["b"], b=>["c"], c=>["a"]}); # => 0


=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 toposort(\%graph) => sorted list

=head2 is_cyclic(\%graph) => bool

Return true if graph contains at least one cycle.

=head2 is_acyclic(\%graph) => bool

Return true if graph is acyclic, i.e. contains no cycles.


=head1 SEE ALSO

L<Sort::Topological> can also sort a DAG, but cannot handle cyclical graph.
