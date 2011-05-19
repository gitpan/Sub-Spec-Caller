package Sub::Spec::Caller;
BEGIN {
  $Sub::Spec::Caller::VERSION = '0.01';
}
# ABSTRACT: Call subroutines

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(call_sub);


sub call_sub($$;$$) {
    my ($module, $func, $args, $opts) = @_;

    # XXX schema
    return [400, "Please specify module name"] unless $module;
    return [400, "Invalid module syntax"] unless $module =~ /\A\w+(::\w+)*\z/;
    return [400, "Please specify sub"] unless $func;
    return [400, "Invalid sub syntax"] unless $func =~ /\A\w+\z/;
    $args //= {};
    $opts //= {};

    # load module
    if ($opts->{load} // 1) {
        my $modulef = $module; $modulef =~ s!::!/!g; $modulef .= ".pm";
        eval { require $modulef };
        my $eval_err = $@;
        if ($eval_err) {
            delete $INC{$modulef};
            return [500, "Failed loading module: $eval_err"];
        }
    }

    # get fspec
    my $fqn    = $module . "::$func";
    my $fqspec = $module . '::' . 'SPEC';
    no strict 'refs';
    my $fspec;
    eval { $fspec = ${$fqspec}{$func} };
    return [500, "Sub has no spec"] unless $fspec;

    #use Data::Dump; dd $args;

    # call module
    my $fname  = $module . "::$func";
    my $fref   = \&$fname;
    my $res;
    eval { $res = $fref->(%$args) };
    my $eval_err = $@;

    # sometimes when a sub which drops privileges dies, it has not regained
    # privileges.
    if ($< == 0 && $>) { $> = 0; $) = $( }

    return [500, "Died when executing sub: $eval_err"] if $eval_err;

    $res = [200, "OK", $res] if $fspec->{result_naked};

    if ($opts->{convert_datetime_objects}) {
        eval { convert_datetime_objects($res) };
        return [500, "Died when converting DateTime objects: $@"] if $@;
    }
    $res;
}

sub convert_datetime_objects {
    require Data::Rmap;
    my ($obj) = @_;
    # convert DateTime object to epoch
    Data::Rmap::rmap_ref(
        sub {
            # trick to defeat circular-checking, so in case
            # of [$dt, $dt], both will be converted
            #$_[0]{seen} = {};
            $_ = $_->epoch if UNIVERSAL::isa($_, "DateTime")
        }, $obj
    );
}

1;


=pod

=head1 NAME

Sub::Spec::Caller - Call subroutines

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Sub::Spec::Caller qw(call_sub);
 my $res = call_sub(
     "My::Module",
     "my_func",
     {arg1=>1, arg2=>2},
     {convert_datetime_objects=>1}, # call options
 );

=head1 DESCRIPTION

This module provides one sub: B<call_sub>.

=head2 call_sub($module, $func, $args, \%opts) => $resp

This is basically just a shorthand for loading the module and calling the
subroutine, but with some options. It traps exceptions and return [500, ...]
instead.

Available options:

=over 4

=item * load => BOOL (default 1)

If set to 0, do not try to load the module. Thus, you need to load the module
manually beforehand.

=item * convert_datetime_objects => BOOL (default 0)

Convert datetime objects to Unix epoch time. This might be useful when passing
result to JSON/YAML for other languages.

=back

For minimum overhead, you should load modules and call functions directly.
call_sub() is mainly used by L<Sub::Spec::HTTP::Server> which passes the result
into JSON/YAML/etc for external purposes.

=head1 SEE ALSO

L<Sub::Spec::Runner>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

