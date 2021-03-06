[![Build Status](https://travis-ci.org/akiym/Oden.svg?branch=master)](https://travis-ci.org/akiym/Oden)
# NAME

Oden - pretty simple DBI wrapper/ORMapper

# SYNOPSIS

    my $db = MyDB->new({ connect_info => [ 'dbi:SQLite:' ] });
    my $row = $db->insert_and_select( 'table' => {
        col1 => $value
    } );

# DESCRIPTION

Oden is pretty simple DBI wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

# BASIC USAGE

create your db model base class.

    package Your::Model;
    use parent 'Oden';
    1;
    

create your db schema class.
See Oden::Schema for docs on defining schema class.

    package Your::Model::Schema;
    use Oden::Schema::Declare;
    table {
        name 'user';
        pk 'id';
        columns qw( foo bar baz );
    };
    1;
    

in your script.

    use Your::Model;
    
    my $oden = Your::Model->new(\%args);
    # insert new record.
    my $row = $oden->insert_and_select('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'}); # same do { $row->name('nekokak'); $row->update; }

    $row = $oden->single_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete();

# ARCHITECTURE

Oden classes are comprised of three distinct components:

## MODEL

The `model` is where you say 

    package MyApp::Model;
    use parent 'Oden';

This is the entry point to using Oden. You connect, insert, update, delete, select stuff using this object.

## SCHEMA

The `schema` is a simple class that describes your table definitions. Note that this is different from DBIx::Class terms.
DBIC's schema is equivalent to Oden's model + schema, where the actual schema information is scattered across the result classes.

In Oden, you simply use Oden::Schema's domain specific language to define a set of tables

    package MyApp::Model::Schema;
    use Oden::Schema::Declare;

    table {
        name $table_name;
        pk $primary_key_column;
        columns qw(
            column1
            column2
            column3
        );
    }

    ... and other tables ...

## ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms).
In Oden, the row objects are blessed into anonymous classes that inherit from Oden::Row,
so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

    package MyApp::Model::Row::Camelizedtable_name;
    use parent qw(Oden::Row);

Note that your table name will be camelized.

# METHODS

Oden provides a number of methods to all your classes, 

- $oden = Oden->new(\\%args)

    Creates a new Oden instance.

        # connect new database connection.
        my $db = Your::Model->new(
            connect_info => [ $dsn, $username, $password, \%connect_options ]
        );

    Arguments can be:

    - `connect_info`

        Specifies the information required to connect to the database.
        The argument should be a reference to a array in the form:

            [ $dsn, $user, $password, \%options ]

        You must pass `connect_info` or `dbh` to the constructor.

    - `dbh`

        Specifies the database handle to use.

    - `no_ping`

        By default, ping before each executing query.
        If it affect performance then you can set to true for ping stopping.

    - `fields_case`

        specific DBI.pm's FetchHashKeyName.

    - `schema`

        Specifies the Oden::Schema instance to use.
        If not specified, the value specified in `schema_class` is loaded and
        instantiated for you.

    - `schema_class`

        Specifies the schema class to use.
        By default {YOUR\_MODEL\_CLASS}::Schema is used.

    - `txn_manager_class`

        Specifies the transaction manager class.
        By default DBIx::TransactionManager is used.

    - `suppress_row_objects`

        Specifies the row object creation mode. By default this value is `false`.
        If you specifies this to a `true` value, no row object will be created when
        a `SELECT` statement is issued..

    - `force_deflate_set_column`

        Specifies `set_column`, `set_columns` and column name method behaviour. By default this value is `false`.
        If you specifies this to a `true` value, `set_column` or column name method will deflate argument.

    - `sql_builder`

        Speficies the SQL builder object. By default SQL::Maker is used, and as such,
        if you provide your own SQL builder the interface needs to be compatible
        with SQL::Maker.

    - `sql_builder_class` : Str

        Speficies the SQL builder class name. By default SQL::Maker is used, and as such,
        if you provide your own SQL builder the interface needs to be compatible
        with SQL::Maker.

        Specified `sql_builder_class` is instantiated with following:

            $sql_builder_class->new(
                driver => $oden->{driver_name},
                %{ $oden->{sql_builder_args}  }
            )

        This is not used when `sql_builder` is specified.

    - `sql_builder_args` : HashRef

        Speficies the arguments for constructor of `sql_builder_class`. This is not used when `sql_builder` is specified.

- `$row = $oden->insert_and_select($table_name, \%row_data)`

    Inserts a new record. Returns the inserted row object.

        my $row = $oden->insert_and_select('user',{
            id   => 1,
            name => 'nekokak',
        });

    If a primary key is available, it will be fetched after the insert -- so
    an INSERT followed by SELECT is performed. If you do not want this, use
    `insert`.

- `$last_insert_id = $oden->insert($table_name, \%row_data);`

    insert new record and get last\_insert\_id.

    no creation row object.

- `$oden->do_insert`

    Internal method called from `insert` and `insert`. You can hook it on your responsibility.

- `$oden->bulk_insert($table_name, \@rows_data, \%opt)`

    Accepts either an arrayref of hashrefs.
    each hashref should be a structure suitable
    for submitting to a Your::Model->insert(...) method.
    The second argument is an arrayref of hashrefs. All of the keys in these hashrefs must be exactly the same.

    insert many record by bulk.

    example:

        Your::Model->bulk_insert('user',[
            {
                id   => 1,
                name => 'nekokak',
            },
            {
                id   => 2,
                name => 'yappo',
            },
            {
                id   => 3,
                name => 'walf443',
            },
        ]);

    You can specify `$opt` like `{ prefix => 'INSERT IGNORE INTO' }` or `{ update => { name => 'updated' } }` optionally, which will be passed to query builder.

- `$update_row_count = $oden->update($table_name, \%update_row_data, [\%update_condition])`

    Calls UPDATE on `$table_name`, with values specified in `%update_ro_data`, and returns the number of rows updated. You may optionally specify `%update_condition` to create a conditional update query.

        my $update_row_count = $oden->update('user',
            {
                name => 'nomaneko',
            },
            {
                id => 1
            }
        );
        # Executes UPDATE user SET name = 'nomaneko' WHERE id = 1

    You can also call update on a row object:

        my $row = $oden->single('user',{id => 1});
        $row->update({name => 'nomaneko'});

    You can use the set\_column method:

        my $row = $oden->single('user', {id => 1});
        $row->set_column( name => 'yappo' );
        $row->update;

    you can column update by using column method:

        my $row = $oden->single('user', {id => 1});
        $row->name('yappo');
        $row->update;

- `$updated_row_count = $oden->do_update($table_name, \%set, \%where)`

    This is low level API for UPDATE. Normally, you should use update method instead of this.

    This method does not deflate \\%args.

- `$delete_row_count = $oden->delete($table, \%delete_condition)`

    Deletes the specified record(s) from `$table` and returns the number of rows deleted. You may optionally specify `%delete_condition` to create a conditional delete query.

        my $rows_deleted = $oden->delete( 'user', {
            id => 1
        } );
        # Executes DELETE FROM user WHERE id = 1

    You can also call delete on a row object:

        my $row = $oden->single('user', {id => 1});
        $row->delete

- `$rows = $oden->search($table_name, [\%search_condition, [\%search_attr]])`

    simple search method.
    search method get arrayref of Oden::Row's instance object.

        my $rows = $oden->search('user',{id => 1},{order_by => 'id'});

- `$row = $oden->single($table_name, \%search_condition)`

    get one record.
    give back one case of the beginning when it is acquired plural records by single method.

        my $row = $oden->single('user',{id =>1});

- `$row = $oden->new_row_from_hash($table_name, \%row_data, [$sql])`

    create row object from data. (not fetch from db.)
    It's useful in such as testing.

        my $row = $oden->new_row_from_hash('user', { id => 1, foo => "bar" });
        say $row->foo; # say bar

- `$rows = $oden->search_named($sql, [\%bind_values, [$table_name]])`

    execute named query

        my $rows = $oden->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

    If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
    It's useful in case use IN statement.

        # SELECT * FROM user WHERE id IN (?,?,?);
        # bind [1,2,3]
        my $rows = $oden->search_named(q{SELECT * FROM user WHERE id IN :ids}, {ids => [1, 2, 3]});

    If you give table\_name. It is assumed the hint that makes Oden::Row's Object.

- `$rows = $oden->search_by_sql($sql, [\@bind_values, [$table_name]])`

    execute your SQL

        my $rows = $oden->search_by_sql(q{
            SELECT
                id, name
            FROM
                user
            WHERE
                id = ?
        },[ 1 ]);

    If $table is specified, it set table information to result rows.
    So, you can use table row class to search\_by\_sql result.

- `$row = $oden->single_by_sql($sql, [\@bind_values, [$table_name]])`

    get one record from your SQL.

        my $row = $oden->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

    This is a shortcut for

        my $row = $oden->search_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user')->next;

    But optimized implementation.

- `$row = $oden->single_named($sql, [\%bind_values, [$table_name]])`

    get one record from execute named query

        my $row = $oden->single_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user');

    This is a shortcut for

        my $row = $oden->search_named(q{SELECT id,name FROM user WHERE id = :id LIMIT 1}, {id => 1}, 'user')->next;

    But optimized implementation.

- `$sth = $oden->execute($sql, [\@bind_values])`

    execute query and get statement handler.
    and will be inserted caller's file and line as a comment in the SQL if $ENV{ODEN\_SQL\_COMMENT} or sql\_comment is true value.

- `$oden->txn_scope`

    Creates a new transaction scope guard object.

        do {
            my $txn = $oden->txn_scope;

            $row->update({foo => 'bar'});

            $txn->commit;
        }

    If an exception occurs, or the guard object otherwise leaves the scope
    before `$txn->commit` is called, the transaction will be rolled
    back by an explicit ["txn\_rollback"](#txn_rollback) call. In essence this is akin to
    using a ["txn\_begin"](#txn_begin)/["txn\_commit"](#txn_commit) pair, without having to worry
    about calling ["txn\_rollback"](#txn_rollback) at the right places. Note that since there
    is no defined code closure, there will be no retries and other magic upon
    database disconnection.

- `$txn_manager = $oden->txn_manager`

    Create the transaction manager instance with specified `txn_manager_class`.

- `$oden->txn_begin`

    start new transaction.

- `$oden->txn_commit`

    commit transaction.

- `$oden->txn_rollback`

    rollback transaction.

- `$oden->txn_end`

    finish transaction.

- `$oden->do($sql, [\%option, @bind_values])`

    Execute the query specified by `$sql`, using `%option` and `@bind_values` as necessary. This pretty much a wrapper around [http://search.cpan.org/dist/DBI/DBI.pm#do](http://search.cpan.org/dist/DBI/DBI.pm#do)

- `$oden->dbh`

    get database handle.

- `$oden->connect(\@connect_info)`

    connect database handle.

    connect\_info is \[$dsn, $user, $password, $options\].

    If you give \\@connect\_info, create new database connection.

- `$oden->disconnect()`

    Disconnects from the currently connected database.

- `$oden->suppress_row_objects($flag)`

    set row object creation mode.

- `$oden->load_plugin();`

        $oden->load_plugin($plugin_class, $options);

    This imports plugin class's methods to `$oden` class
    and it calls $plugin\_class's init method if it has.

        $plugin_class->init($oden, $options);

    If you want to change imported method name, use `alias` option.
    for example:

        YourDB->load_plugin('BulkInsert', { alias => { bulk_insert => 'isnert_bulk' } });

    BulkInsert's "bulk\_insert" method is imported as "insert\_bulk".

- `$oden->handle_error`

    handling error method.

- `$oden->connected`

    check connected or not.

- `$oden->reconnect`

    reconnect database

- How do you use display the profiling result?

    use [Devel::KYTProf](https://metacpan.org/pod/Devel::KYTProf).

# TRIGGERS

Oden does not support triggers (NOTE: do not confuse it with SQL triggers - we're talking about Perl level triggers). If you really want to hook into the various methods, use something like [Moose](https://metacpan.org/pod/Moose), [Mouse](https://metacpan.org/pod/Mouse), and [Class::Method::Modifiers](https://metacpan.org/pod/Class::Method::Modifiers).

# SEE ALSO

## Fork

This module was forked from [DBIx::Skinny](https://metacpan.org/pod/DBIx::Skinny), around version 0.0732.
many incompatible changes have been made.

# BUGS AND LIMITATIONS

No bugs have been reported.

# AUTHORS

Takumi Akiyama <t.akiym@gmail.com>

Atsushi Kobayashi  `<nekokak __at__ gmail.com>`

Tokuhiro Matsuno <tokuhirom@gmail.com>

Daisuke Maki `<daisuke@endeworks.jp>`

# LICENCE AND COPYRIGHT

Copyright (c) 2017, the Oden ["AUTHORS"](#authors). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
