package Oden::Plugin::SingleBySQL;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/single_by_sql/;

warn "IMPORTANT: Oden::Plugin::SingleBySQL is DEPRECATED AND *WILL* BE REMOVED. Because into the Oden core. DO NOT USE.\n";

sub single_by_sql {
    my ($self, $sql, $bind, $table_name) = @_;

    $table_name ||= $self->_guess_table_name($sql);
    my $table = $self->{schema}->get_table($table_name);
    Carp::croak("No such table $table_name") unless $table;

    my $sth = $self->execute($sql, $bind);
    my $row = $sth->fetchrow_hashref($self->{fields_case});

    return unless $row;
    return $row if $self->{suppress_row_objects};

    $table->{row_class}->new({
        sql        => $sql,
        row_data   => $row,
        oden       => $self,
        table      => $table,
        table_name => $table_name,
    });
}

1;
__END__

=head1 NAME

Oden::Plugin::SingleBySQL - (DEPRECATED) Single by SQL

=head1 PROVIDED METHODS

=over 4

=item C<< $row = $oden->single_by_sql($sql, [\%bind_values, [$table_name]]) >>

get one record from your SQL.

    my $row = $oden->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

=back

