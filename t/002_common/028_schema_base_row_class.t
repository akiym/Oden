use strict;
use warnings;
use utf8;
use Test::More;
use Oden::Schema::Table;
use Oden::Schema::Declare;

{
    package My::Row;
    use parent qw/Oden::Row/;
}

subtest 'Oden::Schema::Table#new' => sub {
    subtest 'it uses "base_row_class"' => sub {
        my $table = Oden::Schema::Table->new(
            row_class      => 'My::Not::Existent',
            base_row_class => 'My::Row',
            columns        => []
        );
        isa_ok('My::Not::Existent', 'My::Row');
    };
};

subtest 'Oden::Schema::Declare' => sub {
    my $schema = schema {
        base_row_class 'My::Row';
        table {
            name 'boo';
            columns qw/
                id
                name
            /;
        };
    };
    isa_ok($schema->get_row_class('boo'), 'My::Row');
};

done_testing;

