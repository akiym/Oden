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

subtest search_by_sql_with_escaped_query => sub {
    my $sql = 'SELECT id, name FROM "mock_basic" WHERE id = ?';
    my $row = $db->search_by_sql($sql, [1])->[0];

    is $row->id,   1;
    is $row->name, 'perl';
};

subtest search_by_sql_with_escaped_query => sub {
    my $sql = 'SELECT id, name FROM `mock_basic` WHERE id = ?';
    my $row = $db->search_by_sql($sql, [1])->[0];

    is $row->id,   1;
    is $row->name, 'perl';
};

done_testing;
