#! /usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use JSON;

my $json = do { local $/; <STDIN> };
my $data = decode_json($json);

my %jobs = ();
my %filesets = ();
my %job_file = ();
my %addr_file = ();
my %clients = ();

foreach my $client (keys %{$data->{'Client'}}) {
        $clients{$client}{'addr'} = $$data{'Client'}{$client}{'Address'};
}

foreach my $job (keys %{$data->{'Job'}}) {
        push @{$jobs{ $$data{'Job'}{$job}{'Client'} }}, $$data{'Job'}{$job}{'FileSet'};
} 

foreach my $fileset (keys %{$data->{'FileSet'}}) {
        $filesets{$fileset} =  $$data{'FileSet'}{$fileset}{'Include'}{File};
}

###########

foreach my $job (keys %jobs) {
        foreach my $fileset (@{$jobs{$job}}) {
#                print "JOB: $job \t FILESET: $fileset\n";
#                print Dumper($filesets{$fileset});

                if (ref $filesets{$fileset} eq ref []) { # like an array (case of 'File', 'Run', ...)?
                        push @{$job_file{$job}}, @{$filesets{$fileset}};
                } else {
                        $job_file{$job} =  [ $filesets{$fileset} ];
                }
        }
}

############
foreach my $client (keys %job_file) {
        $addr_file{ $clients{$client}{'addr'} } = $job_file{$client};
}


#print Dumper(\%addrs);
#print "======================================= JOBS\n";
#print Dumper(\%jobs);
#print "======================================= FILESETS\n";
#print Dumper(\%filesets);
#print "======================================= JOB_FILE\n";
#print Dumper(\%job_file);
#print "======================================= CLIENTS\n";
#print Dumper(\%clients);
#print "======================================= ADDR_FILE\n";
#print Dumper(\%addr_file);

#print "======================================= DATA\n";
#print Dumper($data);

print JSON->new->pretty->encode(\%addr_file);




