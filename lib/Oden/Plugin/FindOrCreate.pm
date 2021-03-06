package Oden::Plugin::FindOrCreate;
use strict;
use warnings;
use utf8;

our @EXPORT = qw/find_or_create/;

sub find_or_create {
    my ($self, $table, $args) = @_;
    my $row = $self->single($table, $args);
    return $row if $row;
    $self->insert_and_select($table, $args)->refetch;
}

1;

__END__

=head1 NAME

Oden::Plugin::FindOrCreate - provide find_or_create method for your Oden class.

=head1 NAME

    package MyDB;
    use parent qw/Oden/;
    __PACKAGE__->load_plugin('FindOrCreate');

    package main;
    my $db = MyDB->new(...);
    my $row = $db->find_or_create('user',{name => 'lestrrat'});

=head1 DESCRIPTION

This plugin provides find_or_create method.

=head1 METHODS

=over 4

=item $row = $db->find_or_create($table[, \%args]])

I<$table> table name for counting

I<\%args> : HashRef for row data.

=back
