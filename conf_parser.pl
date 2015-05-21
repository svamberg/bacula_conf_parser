#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

# open bacula conf file
my $filename = $ARGV[0];
open(my $fh, $filename)
  or die "Could not open file '$filename' $!";

# parse the file
my %conf;
my $type;
my $name;

%conf = &recurse_parsing($fh, 0);

# print Dumper \%conf;

&print_conf( \%conf, '');


sub print_conf {
    my $hash = shift;
    my $level = shift;

    foreach my $key ( sort(keys %$hash) ) {
        if (ref $$hash{ $key } eq ref {}) {
            print $level . $key . "\n";
            print_conf( $$hash{ $key }, $level . '    ' );
        } else {
            print $level . $key . ' = ' . $$hash{ $key } . "\n";
        }
    }
}

sub recurse_parsing {
    my $fh = shift; #file handle
    my $level = shift;  #recursing level. 0 = root
    my %conf;

    while (my $line = <$fh>) {
        $line = &clean_line($line);
        if ( length($line) == 0 ) { next }

        # opening curly bracket with name, go in recursive sub
        if ( $line =~ /^(\w+)\s*\{/ ) { 

            # special case for root level: ressources identified by their name
            if ( $level == 0 ) { 
                my %temp = &recurse_parsing( $fh, $level + 1);
                $conf{ $1 }{ $temp{ 'Name' } } = \%temp;

            # else, it is a hash, no variables to overwrite
            } else {
                $conf{ $1 } = { &recurse_parsing( $fh, $level + 1) };
            }
        }

        # assigne data => value in current hash
        if ( $line =~ /([\w ]+?)\s*\=\s*("?[^"]+"?)/) {
            # if the values are like an array (case of 'File', 'Run', ...)
            if ( exists($conf{ $1 }) ) {
                if (ref $conf{ $1 } eq ref []) {
                    push @{ $conf{ $1 } }, $2 ;
                } else {
                    $conf{ $1 } = [ $2 ];
                }
            } else {
                $conf{ $1 } = $2;
            }
        }

        # closing curly bracket, go back from recursive sub
        if ( $line =~ /^}/) { 
            return %conf;
        }
    }

    # last round.
    return %conf;
}

sub clean_line {
    my $line = shift;

    chomp $line; # remove new line
    $line =~ s/^\s+//; # remove starting blanks
    $line =~ s/#.*$//; # remove comments

    return $line;
}