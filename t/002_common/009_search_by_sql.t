use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;
$db->insert_and_select(
    'mock_basic', {
        id   => 1,
        name => 'perl',
    });

subtest 'search_by_sql' => sub {
    my $rows = $db->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, [1]);

    my $row = $rows->[0];
    isa_ok $row, 'Oden::Row';
    is $row->id,   1;
    is $row->name, 'perl';
};

subtest 'suppress_row_objects' => sub {
    $db->suppress_row_objects(1);
    my $rows = $db->search_by_sql(q{SELECT * FROM mock_basic WHERE id = ?}, [1]);

    my $row = $rows->[0];
    is_deeply $row, {
        id        => 1,
        name      => 'perl',
        delete_fg => 0,
    };
};

done_testing;

