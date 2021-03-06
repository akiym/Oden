use strict;
use warnings;
use Test::More;
use DBI;
use Oden;
use Oden::Schema::Loader;

unlink 'loader.db' if -f 'loader.db';

# initialize
my $dbh = DBI->connect('dbi:SQLite:./loader.db', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(
    q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});

{

    package Mock::DB;
    use parent 'Oden';
}

subtest 'use $dbh' => sub {
    my $db = Oden::Schema::Loader->load(
        dbh       => $dbh,
        namespace => 'Mock::DB',
    );

    isa_ok $db, 'Mock::DB';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}),      'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Mock::DB::Row::User';

    ok $db->insert_and_select('user', {user_id => 1, name => 'inserted'});
    is $db->single('user', {user_id => 1})->name, 'inserted';
};

subtest 'use connect_info' => sub {
    my $db = Oden::Schema::Loader->load(
        connect_info => ['dbi:SQLite:./loader.db', '', ''],
        namespace    => 'Mock::DB',
    );

    isa_ok $db, 'Mock::DB';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}),      'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Mock::DB::Row::User';

    ok $db->insert_and_select('user', {user_id => 2, name => 'inserted 2'});
    is $db->single('user', {user_id => 2})->name, 'inserted 2';
};

subtest 'auto create oden class' => sub {
    my $db = Oden::Schema::Loader->load(
        connect_info => ['dbi:SQLite:./loader.db', '', ''],
        namespace    => 'Proj::DB',
    );

    isa_ok $db, 'Proj::DB';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}),      'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Proj::DB::Row::User';

    ok $db->insert_and_select('user', {user_id => 3, name => 'inserted 3'});
    is $db->single('user', {user_id => 3})->name, 'inserted 3';
};

{

    package Mock::DB2;
    use parent 'Oden';

    sub new {
        shift->SUPER::new(@_);
    }
}

subtest 'constructor is overrided' => sub {
    local $@;

    my $db = eval {
        Oden::Schema::Loader->load(
            dbh       => $dbh,
            namespace => 'Mock::DB2',
        );
    };
    ok !$@;
    isa_ok $db, 'Mock::DB2';

    my $user = $db->schema->get_table('user');
    is($user->name, 'user');
    is(join(',', @{$user->primary_keys}), 'user_id');
    is(join(',', @{$user->columns}),      'user_id,name,email,created_on');

    my $row = $db->schema->get_row_class('user');
    is $row, 'Mock::DB2::Row::User';
};

unlink './loader.db';
done_testing;

