#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use JSON;

# --- start of config section ---
my $output_format="json"; 
my $hide_password=1; # 0 = Password item will be printed; 1 = Password item will be hidden
# --- end of config section ---

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

if ($output_format eq "json") {
    print JSON->new->pretty->encode(\%conf);
} else {
    &print_conf( \%conf, '');
}

sub print_conf {
    my $hash = shift;
    my $level = shift;

    foreach my $key ( sort(keys %$hash) ) {

        if (ref $$hash{ $key } eq ref {}) { # value is hash
            print $level . $key . "\n";
            print_conf( $$hash{ $key }, $level . '    ' );
            next;
        } 

        if (ref $$hash{ $key } eq ref []) { # value is array
            print $level . $key . "\n";
            foreach my $val ( @{ $$hash{ $key } } ) {
                print $level . '    ' . $val . "\n";
            }
            next;
        } 

        # value is string
        print $level . $key . ' = ' . $$hash{ $key } . "\n";
    }
}

sub recurse_parsing {
    my $fh = shift; #file handle
    my $level = shift;  #recursing level. 0 = root
    my %conf;
    my @subfiles = ( "$ARGV[0]" );
    my $next_file = 0;
        
    while ($#subfiles > -1) {

        if ($next_file eq 1) {
            close($fh);
            open($fh, $subfiles[0]) or die "Could not open file '$subfiles[0]' $!";
            $next_file = 0;
        }

        if (my $line = <$fh>) {
                $line = &clean_line($line);
                if ( length($line) == 0 ) { next; }

                # opening curly bracket with name, go in recursive sub
                if ( $line =~ /^(\w+)\s*\{/ ) {
                    my $key = $1;

                    # special case for root level: ressources identified by their name
                    if ( $level == 0 ) { 
                        my %temp = &recurse_parsing( $fh, $level + 1);
                        $conf{ $key }{ $temp{ 'Name' } } = \%temp;

                    # else, it is a hash, no variables to overwrite
                    } else {
                        $conf{ $key } = { &recurse_parsing( $fh, $level + 1) };
                    }
                }

                # assigne data => value in current hash
                if ( $line =~ /([\w ]+?)\s*\=\s*("?[^"]+"?)/) {
                    my $key = $1;
                    my $value = $2;
                    
                    if ( exists($conf{ $key }) ) { # Already one?
                        if (ref $conf{ $key } eq ref []) { # like an array (case of 'File', 'Run', ...)?
                            push @{ $conf{ $key } }, $value ;
                        } else {
                            $conf{ $key } =  [ $conf{ $key }, $value ];
                        }
                    } else {
                        $conf{ $key } = $value;
                    }
                }

                # closing curly bracket, go back from recursive sub
                if ( $line =~ /^}/) { 
                    return %conf;
                }

                # including config - TODO: sanitize inputs
                if ( $line =~ /^@(.*)/) {
                    push @subfiles, "$1";
                }

            } else {
                shift @subfiles; # remove finished file, open another
                $next_file = 1;
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
    $line =~ s/^(\s*Password\s*=\s*).*$/$1"__password_is_hidden__"/ if $hide_password; # remove passwords
    $line =~ s/"//g;

    return $line;
}
