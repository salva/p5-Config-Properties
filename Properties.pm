package Config::Properties;

use strict;
use warnings;

our $VERSION = '0.44';

use IO::Handle;
use Carp;

#   new() - Constructor
#
#   The constructor can take one optional argument "$defaultProperties"
#   which is an instance of Config::Properties to be used as defaults
#   for this object.
sub new {
    my $proto = shift;
    my $defaultProperties = shift;
    my $perlMode = shift;

    ref($proto)
	and carp "creating new Config::Properties objects from prototypes is deprecated";

    my $class = ref($proto) || $proto;
    my $self = {
		'PERL_MODE' => $perlMode ? 1 : 0,
		'defaults' => $defaultProperties,
		'format' => '%s=%s',
		'properties' => {} };
    bless $self, $class;

    $self->{PERL_MODE}
	and carp "use of PerlMode flag is deprecated";

    return $self;
}


#	setProperty() - Set the value for a specific property
sub setProperty {
    my ($self, $key, $value)=@_;

    defined($key) && length($key) && defined($value)
	or croak "Config::Properties::setProperty( key, value )";

    my $oldValue = $self->{properties}{ $key };
    $self->{properties}{ $key } = $value;
    return $oldValue;
}


#	getProperties() - Return a hashref of all of the properties
sub getProperties { return { %{shift->{properties}} } }


#	getFormat() - Return the output format for the properties
sub getFormat { shift->{format} }


#	setFormat() - Set the output format for the properties
sub setFormat {
    my ($self, $format) = @_;

    $self->{format} = defined($format) ? $format : '%s=%s';
}


#	format() - Alias for get/setFormat();
sub format {
    my $self = shift;
    if (@_) {
	return $self->setFormat(@_)
    }
    $self->getFormat();
}


#       setValidator(\&validator) - Set sub to be called to validate
#                property/value pairs.
#                It is called &validator($property, $value, $config)
#                being $config the Config::Properties object.
sub setValidator {
    my ($self, $validator) = @_;

    unless ( !defined($validator) or
	     UNIVERSAL::isa($validator, 'CODE') ) {
	croak "Config::Properties::setValidator( \&validator )"
    }

    $self->{validator} = $validator;
}


#       getValidator() - Return the current validator sub
sub getValidator { shift->{validator} }


#       validator() - Alias for get/setValidator();
sub validator {
    my $self=shift;
    if (@_) {
	return $self->setValidator(@_)
    }
    $self->getValidator
}


#	load() - Load the properties from a filehandle
sub load {
    my ($self, $file) = @_;

    defined($file)
	or croak "Config::Properties::load( file )";

    while (<$file>) {
	$self->{line_number}=$file->input_line_number;
	$self->process_line($_, $file);
    }
}


#        escape_key(string), escape_value(string), unescape(string) -
#               subroutines to convert escaped characters to their
#               real counterparts back and forward.

my %esc = ( "\n" => 'n',
	    "\r" => 'r',
	    "\t" => 't' );
my %unesc = reverse %esc;

sub escape_key {
    $_[0]=~s{([\t\n\r\\"' =:])}{
	"\\".($esc{$1}||$1) }ge;
    $_[0]=~s{([^\x20-\x7e])}{sprintf "\\u%04x", ord $1}ge;
}

sub escape_value {
    $_[0]=~s{([\t\n\r\\])}{
	"\\".($esc{$1}||$1) }ge;
    $_[0]=~s{([^\x20-\x7e])}{sprintf "\\u%04x", ord $1}ge;
}

sub unescape {
    $_[0]=~s/\\([tnr\\"' =:])|u([\da-fA-F]{4})/
	defined $1 ? $unesc{$1}||$1 : chr hex $2 /ge;
}


#	process_line() - Recursive function used to parse a line from the
#					properties file.
sub process_line {
    my ($self, $line, $file) = @_;

    # unless(defined($line) && defined($file)) {
    # croak "Config::Properties::process_line( line, file )";
    # }

    chomp $line;
    return if $line =~ /^\s*(\#|\!|$)/;

    # handle continuation lines
    my @lines;
    while ($line =~ /(\\+)$/ and length($1) & 1) {
	$line =~ s/\\$//;
	push @lines, $line;
	chomp($line = <$file>);
	$line =~ s/^\s+//;
    }
    $line=join('', @lines, $line) if @lines;

    my ($key, $value) = $line =~ /^
				  \s*
				  ((?:[^\s:=\\]|\\.)+)
				  \s*
				  [:=\s]
				  \s*
				  (.*)
				  $
				  /x
       or $self->fail("invalid property line '$line'");
	
    unescape $key;
    unescape $value;
    $self->{properties}{$key} =
	$self->validate($key, $value);
}

#       validate(key, value) - check if the property is valid.
#               calls the validator if it has been set.
sub validate {
    my ($self, $key, $value)=@_;
    my $validator = $self->validator;
    if ($validator) {
	return &{$validator}($key, $value, $self)
    }
    $value;
}


#       line_number() - number for the last line read from the configuration file
sub line_number { shift->{line_number} }


#       fail(error) - report errors in the configuration file while reading.
sub fail {
    my ($self, $error) = @_;
    die "$error at line ".$self->line_number()."\n";
}

#	reallySave() - Utility function that performs the actual saving of
#		the properties file to a filehandle.
sub reallySave {
    my ($self, $file) = @_;

    defined($file)
	or croak "Config::Properties::reallySave( file )";

    foreach (sort keys %{$self->{properties}}) {
	my $key=$_;
	my $value=$self->{properties}{$key};
	escape_key $key;
	escape_value $value;
	printf $file $self->{'format'} . "\n", $key, $value;
    }
}


#	save() - Save the properties to a filehandle with the given header.
sub save {
    my ($self, $file, $header)=@_;

    defined $file
	or croak "Config::Properties::save( file, header )";

    if (defined $header) {
	$header=~s/\n/# \n/sg;
	print $file "# $header\n#\n";
    }
    print $file '# ' . localtime() . "\n\n";
    $self->reallySave( $file );
}


#	store() - Synonym for save()
sub store { shift->save(@_) }


#	getProperty() - Return the value of a property key. Returns the default
#		for that key (if there is one) if no value exists for that key.
sub getProperty {
    my ($self, $key, $default)=@_;

    defined($key) or
	croak "Config::Properties::getProperty( key )";

    if (exists $self->{properties}{$key}) {
	return $self->{properties}{$key}
    }
    elsif (defined $self->{defaults}) {
	return $self->{defaults}->getProperty($key, $default);
    }
    $default;
}


#	propertyName() - Returns an array of the keys of the Properties
sub propertyNames { keys %{shift->{properties}};
}


#	list() - Same as store() except that it doesn't include a header.
#		Meant for debugging use.
sub list {
    my ($self, $file) = @_;

    defined $file
	or croak "Config::Properties::list( file )";

    print $file "# -- listing properties --";
    $self->reallySave( $file );
}

#	setPerlMode() - Sets the value (true/false) of the PERL_MODE parameter.
sub setPerlMode {
    my ($self, $mode) = @_;
    carp "use of PerlMode flag is deprecated";
    return $self->{'PERL_MODE'} = (defined($mode) && $mode) ? 1 : 0;
}

#	perlMode() - Returns the current PERL_MODE setting (Default is false)
sub perlMode {
    my $self = shift;
    carp "use of PerlMode flag is deprecated";
    return $self->{'PERL_MODE'};
}

1;
__END__

=head1 NAME

Config::Properties - read Java-style properties files

=head1 SYNOPSIS

use Config::Properties;

my $properties = new Config::Properties();
$properties->load( $fileHandle );

$value = $properties->getProperty( $key );
$properties->setProperty( $key, $value );

$properties->format( '%s => %s' );
$properties->store( $fileHandle, $header );

=head1 DESCRIPTION

Config::Properties is an near implementation of the java.util.Properties API.
It is designed to allow easy reading, writing and manipulation of Java-style
property files.

The format of a Java-style property file is that of a key-value pair seperated
by either whitespace, the colon (:) character, or the equals (=) character.
Whitespace before the key and on either side of the seperator is ignored.

Lines that begin with either a hash (#) or a bang (!) are considered comment
lines and ignored.

A backslash (\) at the end of a line signifies a continuation and the next
line is counted as part of the current line (minus the backslash, any whitespace
after the backslash, the line break, and any whitespace at the beginning of the next line).

The official references used to determine this format can be found in the Java API docs
for java.util.Properties at L<http://java.sun.com/j2se/1.3/docs/api/index.html>.

When a property file is saved it is in the format "key=value" for each line. This can
be changed by setting the format attribute using either $object->format( $format_string ) or
$object->setFormat( $format_string ) (they do the same thing). The format string is fed to
printf and must contain exactly two %s format characters. The first will be replaced with
the key of the property and the second with the value. The string can contain no other
printf control characters, but can be anything else. A newline will be automatically added
to the end of the string. You an get the current format string either by using
$object->format() (with no arguments) or $object->getFormat().

=over 4

*** DEPRECATED ***

If a true third parameter is passed to the constructor, the Config::Properties object
be created in PERL_MODE. This can be set at any time by passing a true or false value
into the setPerlMode() instance method. If in PERL_MODE, the behavior of the object
may be expanded, enhanced and/or just plain different than the Java API spec.

The following is a list of the current behavior changed under PERL_MODE:

* Ummm... nothing yet.

The current (true/false) value of PERL_MODE can be retrieved with the perlMode instance
variable.

--- As PERL_MODE has not ever done anything its usage has been deprecated ---

*** DEPRECATED ***

=back

=head1 AUTHORS

C<Config::Properties> was originally developed by Randy Jay Yarger. It
was mantained for some time by Craig Manley and recently it has passed
hands to Salvador Fandiño <sfandino@yahoo.com>.

=cut
