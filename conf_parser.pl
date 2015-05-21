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

print Dumper \%conf;

if (0) {
    while (my $row = <$fh>) {
        # cleaning
        if ($row =~ m/^\s*#/) { next } # remove comments
        if ($row =~ m/^\s*\n$/) { next } # remove blank lines
        chomp $row;

        # parsing
        # get instructions type
        if ($row =~ /^(\w+)\s*\{/) { # caracteres suivi de espace
            $type = $1;
            print "type = $type\n";
        } else {
            # get name
            if ($row =~ /Name\s*\=\s*("?[^"]+"?)/) { # get Name
                $name = $1;
            print "name = $name\n";
            } else {
                if ($row =~ /(\w+)\s*\=\s*("?[^"]+"?)/) { # get data
                    print "data = $1\n";
                    $conf{ $type } { $name } = $1;
                } else {
                    print "Error: $row\n";
                }
            }
        }
    }
}


sub recurse_parsing {
    my $fh = shift;
    my $level = shift;
    my %conf;

    while (my $line = <$fh>) {
        $line = &clean_line($line);
        if ( length($line) == 0 ) { next }

        if ( $line =~ /^(\w+)\s*\{/ ) { # opening curly bracket with name
            print "$level OC $1 {\n";
            if ( $level == 0 ) {
                my %temp = &recurse_parsing( $fh, $level + 1);
                $conf{ $1 }{ $temp{ 'Name' } } = \%temp;
            } else {
                $conf{ $1 } = { &recurse_parsing( $fh, $level + 1) };
            }
        }

        if ( $line =~ /(\w+)\s*\=\s*("?[^"]+"?)/) { # data = value
            print "$level D  $1 = $2\n";
            $conf{ $1 } = $2;
        }

        if ( $line =~ /^}/) { # closing curly bracket
            print "$level CC }\n";
            return %conf;
        }
    }

    return %conf;
}

sub clean_line {
    my $line = shift;

    $line =~ s/^\s+//; # remove starting blanks

    if ($line =~ m/^#/) { return '' } # remove comments
    if ($line =~ m/^\n$/) { return '' } # remove blank lines

    chomp $line;

    return $line;
}