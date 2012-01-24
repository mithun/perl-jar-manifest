package Jar::Manifest;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '0.02';

#######################
# EXPORT
#######################
use base qw(Exporter);
our (@EXPORT_OK);
@EXPORT_OK = qw(Dump Load);

#######################
# LOAD CPAN MODULES
#######################
use Encode qw();
use Text::Wrap qw();

#######################
# READ MANIFEST
#######################
sub Load {
    my $manifest = {
        main    => {},  # Main Attributes
        entries => [],  # Manifest entries
    };
    foreach my $para ( _split_to_paras(@_) ) {
        my $isa_entry = 0;
        my %h;
        foreach my $line ( split( /\n+/, $para ) ) {
            next unless ( $line =~ m{.+:.+} );
            my ( $k, $v ) = map { _trim($_) } split( /\s*:\s+/, $line );
            $h{$k} = $v;
            $isa_entry = 1 if ( lc($k) eq 'name' );
        } ## end foreach my $line ( split( /\n+/...))
        if ($isa_entry) {
            push @{ $manifest->{entries} }, \%h;
        }
        else {
            $manifest->{main} = { %{ $manifest->{main} }, %h };
        }
    } ## end foreach my $para ( _split_to_paras...)
    return $manifest;
} ## end sub Load

#######################
# WRITE MANIFEST
#######################
sub Dump {
    my ($in) = @_;
    croak "Hash ref expected" unless ( ref $in eq 'HASH' );

    my $manifest = {
        main    => $in->{main}    || {},
        entries => $in->{entries} || [],
    };

    my $str = q();

    # Process Main
    foreach my $main_attr ( sort _sort_attr keys %{ $manifest->{main} } ) {
        _validate_attr($main_attr);
        $str
            .= _wrap_line(
            "${main_attr}: " . _clean_val( $manifest->{main}->{$main_attr} ) )
            . "\n";
    } ## end foreach my $main_attr ( sort...)

    # Process entries
    foreach my $entry ( @{ $manifest->{entries} } ) {

        # Get Name
        my ($name_attr) = grep { /^name$/xi } keys %{$entry};
        $name_attr || croak "Missing 'Name' attribute in entry";
        _validate_attr($name_attr);
        $str
            .= "\n"
            . _wrap_line(
            "${name_attr}: " . _clean_val( $entry->{$name_attr} ) )
            . "\n";

        # Process others
        foreach my $entry_attr (
            sort _sort_attr grep { !/$name_attr/ }
            keys %{$entry}
            )
        {
            _validate_attr($entry_attr);
            $str
                .= _wrap_line(
                "${entry_attr}: " . _clean_val( $entry->{$entry_attr} ) )
                . "\n";
        } ## end foreach my $entry_attr ( sort...)
    } ## end foreach my $entry ( @{ $manifest...})

    # Done
    return $str;
} ## end sub Dump

#######################
# INTERNAL HELPERS
#######################

# Split to paragraphs
sub _split_to_paras {
    return map {
        $_ =~ s{(?:\r\n|\n|\r)+}{\n}gx;  # Consolidate new lines
        $_ =~ s{\n\s}{}gx;               # Join multiline values
        $_;                              # Return line
        }
        split(
        /(?:\r\n\s*|\n\s*|\r\s*){2,}/,   # Two or more new lines
        join( '', @_ )
        );
} ## end sub _split_to_paras

# Trim
sub _trim {
    s{^\s+}{}xi;
    s{\s+$}{}xi;
    $_;
}

# Validate Attribute
sub _validate_attr {
    my ($attr) = @_;

    croak
        "Attributes can contain only alphanumeric, '-' or '_' characters : $attr"
        unless ( $attr =~ m{^[-0-9a-zA-Z_]+$} );

    croak "Attribute must contain at least one alphanumeric character : $attr"
        unless ( $attr =~ m{[a-zA-Z0-9]+} );

    croak "Attribute length exceeds allowed value of 70 : $attr"
        if ( length($attr) > 70 );

    return 1;
} ## end sub _validate_attr

# Clean Value
sub _clean_val {
    my ($val) = @_;

    # Get rid of line breaks
    $val =~ s{(?:\r\n|\n|\r)+}{}gix;

    # Trim left space
    $val =~ s{^\s+}{}xi;

    # Return encoded
    return Encode::encode_utf8($val);
} ## end sub _clean_val

# Sort Attributes
sub _sort_attr {
    ( grep { /-/ } $a ) <=> ( grep { /-/ } $b )
        || lc($a) cmp lc($b);
}

# Wrap Line
sub _wrap_line {

    # Wrap settings
    $Text::Wrap::columns = 72;
    $Text::Wrap::break   = '';
    $Text::Wrap::huge    = 'wrap';

    # Wrap
    return Text::Wrap::wrap( "", " ", @_ );
} ## end sub _wrap_line

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

Jar::Manifest - Read and Write Java Jar Manifests

=head1 SYNOPSIS

    use Jar::Manifest qw(Dump Load);

    # Read a Manifest
    my $manifest_str = <<"MANIFEST";
    Manifest-Version: 1.0
    Created-By: 1.5.0_11-b03 (Sun Microsystems Inc.)
    Built-By: JAPH

    Name: org/myapp/foo/
    Implementation-Title: Test Java JAR
    Implementation-Version: 1.9
    Implementation-Vendor: JAPH

    MANIFEST

    my $manifest = Load($manifest_str);
    printf( "Jar built by -> %s\n", $manifest->{main}->{'Built-By'} );
    printf("Name: %s\nVersion: %s\n") for @{ $manifest->{entries} };

    # Write a manifest
    my $manifest = {

        # Main attributes
        main => {
            'Manifest-Version' => '1.0',
            'Created-By'       => '1.5.0_11-b03 (Sun Microsystems Inc.)',
            'Built-By'         => 'JAPH',
        },

        # Entries
        entries => [
            {
                'Name'                   => 'org/myapp/foo/',
                'Implementation-Title'   => 'Test Java JAR',
                'Implementation-Version' => '1.9',
                'Implementation-Vendor'  => 'JAPH',
            }
        ],
    };
    my $manifest_string = Dump($manifest);

=head1 DESCRIPTION

C<Jar::Manifest> provides a perl interface to read and write Manifest files
found within Java archives - typically C<META-INF/MANIFEST.MF> within a <.jar>
file.

The Jar Manifest specification can be found here
L<http://docs.oracle.com/javase/7/docs/technotes/guides/jar/jar.html#JAR_Manifest>

=head1 METHODS

=over

=item Load($string)

    use Jar::Manifest qw(Load);
    use Data::Dumper;

    my $manifest = Load($string);
    print Dumper $manifest;

Read the manifest contents in C<$string>. Returns a I<hash-reference>
containing two keys. The I<main> key is another hash-reference to the main
attributes and corresponding values. The I<entries> key is an array-ref of
hashes containing per-entry attributes and the corresponding values

=item Dump($manifest)

    print Dump($manifest);

Turns the C<$manifest> data structure into a string that can be printed to a
C<MANIFEST.MF> file. The C<$manifest> structure is expected to be in the same
format as the C<Load()> output.

=back

=head1 DEPENDENCIES

L<Encode>

L<Text::Wrap>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-jar-manifest@rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Jar-Manifest>

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut
