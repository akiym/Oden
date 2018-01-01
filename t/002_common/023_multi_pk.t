use t::Utils;
use Test::More;
use MyGuard;

{
    package Mock::MultiPK;
    use parent 'Oden';

    __PACKAGE__->load_plugin('FindOrCreate');

    sub setup_test_db {
        my $self = shift;

        for my $table ( qw( a_multi_pk_table c_multi_pk_table ) ) {
            $self->do(qq{
                DROP TABLE IF EXISTS $table
            });
        }

        {
            $self->do(q{
                CREATE TABLE a_multi_pk_table (
                    id_a  integer,
                    id_b  integer,
                    memo  integer default 'foobar',
                    primary key( id_a, id_b )
                )
            });
            $self->do(q{
                CREATE TABLE c_multi_pk_table (
                    id_c  integer,
                    id_d  integer,
                    memo  integer default 'foobar',
                    primary key( id_c, id_d )
                )
            });
        }
    }

    package Mock::MultiPK::Schema;
    use utf8;
    use Oden::Schema::Declare;

    table {
        name 'a_multi_pk_table';
        pk qw( id_a id_b );
        columns qw( id_a id_b memo );
    };

    table {
        name 'c_multi_pk_table';
        pk qw( id_c id_d );
        columns qw( id_c id_d memo );
    };
}

my $db_file = __FILE__;
$db_file =~ s/\.t$/.db/;
unlink $db_file if -f $db_file;
my $oden = Mock::MultiPK->new({
    connect_info => [ "dbi:SQLite:$db_file" ]
});
my $guard = MyGuard->new(sub { unlink $db_file });

{
    subtest 'init data' => sub {
        $oden->setup_test_db;

        $oden->insert( 'a_multi_pk_table', { id_a => 1, id_b => 1 } );
        $oden->insert( 'a_multi_pk_table', { id_a => 1, id_b => 2 } );
        $oden->insert( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        my $data = $oden->insert( 'a_multi_pk_table', { id_a => 2, id_b => 1 } );
        $oden->insert( 'a_multi_pk_table', { id_a => 2, id_b => 2 } );

        is( $data->id_a, 2 );
        is( $data->id_b, 1 );

        $oden->insert( 'a_multi_pk_table', { id_a => 3, id_b => 10 } );
        $oden->insert( 'a_multi_pk_table', { id_a => 3, id_b => 20 } );
        $oden->insert( 'a_multi_pk_table', { id_a => 3, id_b => 30 } );
    };

    my ( $itr, $a_multi_pk_table );

    subtest 'multi pk search' => sub {
        my @rows = $oden->search( 'a_multi_pk_table', { id_a => 1 } );
        is( scalar(@rows), 3, 'first - user has 3 books' );

        $a_multi_pk_table = $oden->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        ok( $a_multi_pk_table );
        is( $a_multi_pk_table->memo, 'foobar' );
        $a_multi_pk_table->update( { memo => 'hoge' } );

        $a_multi_pk_table = $oden->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } );
        is( $a_multi_pk_table->memo, 'hoge', 'update' );

        is($a_multi_pk_table->delete, 1);

        {
            my @rows = $oden->search( 'a_multi_pk_table', { id_a => 1 } );
            is( scalar(@rows), 2, 'delete and user has 2 books' );
            ok ( not $oden->single( 'a_multi_pk_table', { id_a => 1, id_b => 3 } ) );
        }

        $a_multi_pk_table = $oden->search( 'a_multi_pk_table', { id_a => 1 } )->next;
        ok( $a_multi_pk_table );

        my ( $id_a, $id_b ) = ( $a_multi_pk_table->id_a, $a_multi_pk_table->id_b );

        is($a_multi_pk_table->delete, 1);

        ok ( not $oden->single( 'a_multi_pk_table', { id_a => $id_a, id_b => $id_b } ) );
    };

    subtest 'multi pk search_by_sql' => sub {
        my ( $itr, $row );

        my @rows = $oden->search_by_sql(q{SELECT * FROM a_multi_pk_table WHERE id_a = ? AND id_b = ?}, [3, 10], 'a_multi_pk_table');

        is( 0+@rows, 1 );

        $row = shift @rows;
        is( $row->memo, 'foobar' );
        $row->update( { memo => 'hoge' } );

        $row = $oden->search_by_sql(q{SELECT * FROM a_multi_pk_table WHERE id_a = ? AND id_b = ?}, [3, 10])->next;

        is( $row->memo, 'hoge' );
    };

    subtest 'multi pk row insert' => sub {
        my ( $rs, @rows, $row );

        $row = $oden->insert( 'a_multi_pk_table', { id_a => 3, id_b => 40 } );

        is_deeply( $row->get_columns, { id_a => 3, id_b => 40, memo => 'foobar' } );

        @rows = $oden->search( 'a_multi_pk_table', { id_a => 3 } );
        is( 0+@rows, 4 );

        is($row->delete(), 1);

        @rows = $oden->search( 'a_multi_pk_table', { id_a => 3 } );
        is( 0+@rows, 3 );
    };
}

{
    subtest 'init data' => sub {
        $oden->setup_test_db;

        $oden->insert( 'c_multi_pk_table', { id_c => 1, id_d => 1 } );
        $oden->insert( 'c_multi_pk_table', { id_c => 1, id_d => 2 } );
        $oden->insert( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        my $data = $oden->insert( 'c_multi_pk_table', { id_c => 2, id_d => 1 } );
        $oden->insert( 'c_multi_pk_table', { id_c => 2, id_d => 2 } );

        is( $data->id_c, 2 );
        is( $data->id_d, 1 );

        $oden->insert( 'c_multi_pk_table', { id_c => 3, id_d => 10 } );
        $oden->insert( 'c_multi_pk_table', { id_c => 3, id_d => 20 } );
        $oden->insert( 'c_multi_pk_table', { id_c => 3, id_d => 30 } );
    };

    my ( @rows, $a_multi_pk_table );

    subtest 'multi pk search' => sub {
        @rows = $oden->search( 'c_multi_pk_table', { id_c => 1 } );
        is( 0+@rows, 3, 'first - user has 3 books' );

        $a_multi_pk_table = $oden->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        ok( $a_multi_pk_table );
        is( $a_multi_pk_table->memo, 'foobar' );
        $a_multi_pk_table->update( { memo => 'hoge' } );

        $a_multi_pk_table = $oden->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } );
        is( $a_multi_pk_table->memo, 'hoge', 'update' );

        is($a_multi_pk_table->delete, 1);

        @rows = $oden->search( 'c_multi_pk_table', { id_c => 1 } );
        is( 0+@rows, 2, 'delete and user has 2 books' );
        ok ( not $oden->single( 'c_multi_pk_table', { id_c => 1, id_d => 3 } ) );

        $a_multi_pk_table = $oden->search( 'c_multi_pk_table', { id_c => 1 } )->next;
        ok( $a_multi_pk_table );

        my ( $id_c, $id_d ) = ( $a_multi_pk_table->id_c, $a_multi_pk_table->id_d );

        is($a_multi_pk_table->delete, 1);

        ok ( not $oden->single( 'c_multi_pk_table', { id_c => $id_c, id_d => $id_d } ) );
    };

    subtest 'multi pk search_by_sql' => sub {
        my ( @rows, $row );

        @rows = $oden->search_by_sql(q{SELECT * FROM c_multi_pk_table WHERE id_c = ? AND id_d = ?}, [3, 10], 'c_multi_pk_table');

        is( 0+@rows, 1 );

        $row = shift @rows;
        is( $row->memo, 'foobar' );
        $row->update( { memo => 'hoge' } );

        $row = $oden->search_by_sql(q{SELECT * FROM c_multi_pk_table WHERE id_c = ? AND id_d = ?}, [3, 10])->next;

        is( $row->memo, 'hoge' );
    };

    subtest 'multi pk row insert' => sub {
        my ( $rs, @rows, $row );

        $row = $oden->insert( 'c_multi_pk_table', { id_c => 3, id_d => 40 } );

        is_deeply( $row->get_columns, { id_c => 3, id_d => 40, memo => 'foobar' } );

        @rows = $oden->search( 'c_multi_pk_table', { id_c => 3 } );
        is( 0+@rows, 4 );

        is($row->delete(), 1);

        @rows = $oden->search( 'c_multi_pk_table', { id_c => 3 } );
        is( 0+@rows, 3 );
    };

    subtest 'multi pk find_or_create' => sub {
        my ( $rs, $itr, $row );

        {
            my $row = $oden->find_or_create('c_multi_pk_table' => {id_c => 50, id_d => 90});
            $row->update({memo => 'yay'});
            is_deeply( $row->get_columns, { id_c => 50, id_d => 90, memo => 'yay' } );
        }

        {
            my $row = $oden->find_or_create('c_multi_pk_table' => {id_c => 50, id_d => 90});
            is_deeply( $row->get_columns, { id_c => 50, id_d => 90, memo => 'yay' } );
        }
    };

    subtest 'multi pk delete' => sub {
        is($oden->search_by_sql('SELECT COUNT(*) AS cnt FROM c_multi_pk_table')->next->get_column('cnt'), 7);
        my $row = $oden->insert('c_multi_pk_table' => {id_c => 50, id_d => 44});
        is($oden->search_by_sql('SELECT COUNT(*) AS cnt FROM c_multi_pk_table')->next->get_column('cnt'), 8);
        is($row->delete(), 1);
        is($oden->search_by_sql('SELECT COUNT(*) AS cnt FROM c_multi_pk_table')->next->get_column('cnt'), 7);
    };
}

done_testing;
