package Mock::Inflate::Schema;
use strict;
use warnings;
use Oden::Schema::Declare;
use Mock::Inflate::Name;

table {
    name 'mock_inflate';
    pk qw/ id bar /;
    columns qw/ id name foo bar hash /;
    inflate 'name' => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate 'name' => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
    inflate qr/.+oo/ => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate qr/.+oo/ => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
    inflate 'bar' => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate 'bar' => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
    inflate 'hash' => sub {
        my ($col_value) = @_;
        return { x => $col_value };
    };
    deflate 'hash' => sub {
        my ($col_value) = @_;
        return $col_value->{x};
    };
};

1;

