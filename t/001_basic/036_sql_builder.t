use strict;
use warnings;
use Oden;
use Test::More;

use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;

subtest "default" => sub {
    my $oden = Mock::Basic->new({dbh => $dbh});
    isa_ok $oden->{sql_builder}, 'SQL::Maker';
};

subtest "sql_builder_class" => sub {
    my $oden = Mock::Basic->new({dbh => $dbh, sql_builder_class => 'My::SQL::Builder'});
    isa_ok $oden->{sql_builder}, 'My::SQL::Builder';
};

subtest "sql_builder_args" => sub {
    my $oden = Mock::Basic->new({dbh => $dbh, sql_builder_class => 'My::SQL::Builder', sql_builder_args => {strict => 1}});
    ok $oden->{sql_builder}->{strict};
};

done_testing;

package My::SQL::Builder;

sub new {
    my ($class, %args) = @_;
    bless {%args}, $class;
}
