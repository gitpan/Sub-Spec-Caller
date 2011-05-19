#!perl -T

use 5.010;
use strict;
use warnings;

use DateTime;
use Test::More 0.96;
use Sub::Spec::Caller qw(call_sub);

our %SPEC;

#$SPEC{f1} = {};
#sub f1 { [412, "Needs dough"] }

my $now = time;

$SPEC{f2} = {};
sub f2 { [200, "OK", {date=>DateTime->from_epoch(epoch=>$now)}] }

test_call_sub(
    name       => 'module not yet loaded -> fail',
    sub_module => 'Array::Find', sub_name => 'find_in_array',
    sub_args   => {item=>"a", array=>[qw/a aa b ba c a cb/]},
    opts       => {load=>0},
    status     => 500,
);
test_call_sub(
    name       => 'autoload module, handle result_naked',
    sub_module => 'Array::Find', sub_name => 'find_in_array',
    sub_args   => {item=>"a", array=>[qw/a aa b ba c a cb/]},
    opts       => {},
    status     => 200,
    result     => [qw/a a/],
);

test_call_sub(
    name       => 'convert_datetime_objects=0',
    sub_module => 'main', sub_name => 'f2',
    sub_args   => {},
    opts       => {load=>0},
    status     => 200,
    result     => {date=>DateTime->from_epoch(epoch=>$now)},
);
test_call_sub(
    name       => 'convert_datetime_objects=1',
    sub_module => 'main', sub_name => 'f2',
    sub_args   => {},
    opts       => {load=>0, convert_datetime_objects=>1},
    status     => 200,
    result     => {date=>$now},
);

done_testing();

sub test_call_sub {
    my %args = @_;
    my $name = $args{name};

    subtest $name => sub {
        my $res = call_sub($args{sub_module}, $args{sub_name}, $args{sub_args},
                           $args{opts});
        if ($args{status}) {
            is($res->[0], $args{status}, "status")
                or diag(explain($res));
        }
        if ($args{result}) {
            is_deeply($res->[2], $args{result}, "result")
                or diag(explain($res->[2]));
        }
    };
}

