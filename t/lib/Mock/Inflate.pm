package Mock::Inflate;
use strict;
use parent qw/Oden/;

sub setup_test_db {
    my $oden = shift;

    my $dbd = $oden->{driver_name};
    if ($dbd eq 'SQLite') {
        $oden->do(q{
            CREATE TABLE mock_inflate (
                id   INT,
                name TEXT,
                foo  TEXT,
                bar  TEXT,
                hash TEXT,
                PRIMARY KEY  (id, bar)
            )
        });
    } elsif ($dbd eq 'mysql') {
        $oden->do(
            q{DROP TABLE IF EXISTS mock_inflate}
        );
        $oden->do(q{
            CREATE TABLE mock_inflate (
                id        INT auto_increment,
                name      TEXT,
                foo       TEXT,
                bar       VARCHAR(32),
                hash      TEXT,
                PRIMARY KEY  (id, bar)
            ) ENGINE=InnoDB
        });
    } else {
        die 'unknown DBD';
    }
}

1;

