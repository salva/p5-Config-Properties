package Config::Properties;

use strict;
use warnings;

our $VERSION = '0.41';

#   new() - Constructor
#
#   The constructor can take one optional argument "$defaultProperties"
#   which is an instance of Config::Properties to be used as defaults
#   for this object.
sub new {
	my $proto = shift;
	my $defaultProperties = shift;
	my $perlMode = shift;

	my $class = ref($proto) || $proto;
	my $self = {
		'PERL_MODE' => (defined($perlMode) && $perlMode) ? 1 : 0,
		'defaults' => $defaultProperties,
		'format' => '%s=%s',
		'properties' => {}
	};
	bless($self, $class);

	return $self;
}

#	setProperty() - Set the value for a specific property
sub setProperty {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	unless(defined($key) && length($key) && defined($value)) {
	 die "Config::Properties.setProperty( key, value )";
	}
	my $oldValue = $self->{'properties'}{ $key };
	$self->{'properties'}{ $key } = $value;
	return $oldValue;
}

#	getProperties() - Return a hashref of all of the properties
sub getProperties {
	my $self =  shift;
	return $self->{'properties'};
}

#	setFormat() - Set the output format for the properties
sub setFormat {
	my $self = shift;
	my $format = shift;
	unless(defined($format) && length($format)) {
		die "Config::Properties.format( string )";
	}
	$self->{'format'} = $format;
}

#	format() - Alias for get/setFormat();
sub format {
	my $self = shift;
	my $format = shift;
	if (defined($format) && length($format)) {
	 return $self->setFormat($format);
	}
	else {
	 return $self->getFormat();
	}
}

#	getFormat() - Return the output format for the properties
sub getFormat {
	my $self = shift;
	return $self->{'format'};
}

#	load() - Load the properties from a filehandle
sub load {
	my $self = shift;
	my $file = shift;
	unless(defined($file)) {
		die "Config::Properties.load( file )";
	}
	while (<$file>) {
		$self->process_line($_, $file);
	}
}

#	process_line() - Recursive function used to parse a line from the
#					properties file.
sub process_line {
	my $self =  shift;
	#print "XXX" . join("::", @_) . "XXX\n";
	my $line = shift;
	my $file = shift;
	unless(defined($line) && defined($file)) {
		die "Config::Properties.process_line( line, file )";
	}
	$line =~ s/\015?\012$//;
	if ($line =~ /^\s*(\#|\!|$)/) {
	 	return;
	}
	if ($line =~ /(\\+)$/ and length($1) % 2) {
		$line =~ s/\\$//;
		my $newline = <$file>;
		$newline =~ s/^\s*//;
		return $self->process_line($line . $newline, $file);
	}

	#print "XXX: " . $line . "\n";
	$line =~ /^\s*([^\s:=]+)(\s*|\s*(\:|\=|\s)\s*(.*?))$/;
	#print "1: $1 2: $2 3: $3 4: $4\n";
	unless(defined($1) && length($1)) {
		die "Config::Properties.process_line: invalid property line";
	}

	#$properties{ $1 } = ($4 || "");
	#the javadoc for Properties states that both the name and value
	#can be escaped. The regex above will break though if ':','=', or
	#whitespace are included.
	$self->{'properties'}{ unescape($1) } = (defined($4) && length($4)) ? unescape($4) : ''; # Value ($4) may be '0' !
}

#	unescape() - converts escaped characters to their real counterparts.
sub unescape {
	my $value = shift;

	while ($value =~ m/\\(.)/g) {
		my $result = $1;

		if ($result eq 't') {
	 	    $result = "\t";
	 	} elsif ($result eq 'n') {
	 	    $result = "\n";
	 	} elsif ($result eq 'r') {
	 	    $result = "\r";
	 	} elsif ($result eq 's') {
	 	    $result = ' ';
	 	}

	 	my $start = (pos $value) - 2;
	 	pos $value = $start;
	 	$value =~ s/\\./$result/;
	 	pos $value = ($start + 1);
	}

	return $value;
}

#	reallySave() - Utility function that performs the actual saving of
#		the properties file to a filehandle.
sub reallySave {
	#print "XXX" . join("::", @_) . "XXX\n";
	my $self = shift;
	my $file = shift;
	unless(defined($file)) {
		die "Config::Properties.reallySave( file )";
	}
	foreach (keys %{$self->{properties}}) {
		printf $file $self->{'format'} . "\n", $_, $self->{properties}{$_};
	}
}

#	save() - Save the properties to a filehandle with the given header.
sub save {
	#print "XXX" . join("::", @_) . "XXX\n";
	my $self = shift;
	my $file = shift;
	my $header = shift;
	unless(defined($file) && defined($header) && length($header)) {
	 die "Config::Properties.save( file, header )";
	}
	print $file "#$header\n";
	print $file '#' . localtime() . "\n";
	$self->reallySave( $file );
}

#	store() - Synonym for save()
sub store {
	my $self = shift;
	$self->save(@_);
}

#	getProperty() - Return the value of a property key. Returns the default
#		for that key (if there is one) if no value exists for that key.
sub getProperty {
	my $self = shift;
	my $key = shift;
	my $default = shift;
	unless(defined($key) && length($key)) { # Key can be '0'!
		die "Config::Properties.getProperty( key )";
	}
	my $value = $self->{properties}{ $key };
	if ($self->{defaults} && !defined($value)) { # Value can be '0' or empty string!
	           $value = $self->{defaults}->getProperty($key);
	}
	return defined($value) ? $value : $default; # $value can be 0 or empty string if key exists!
}

#	propertyName() - Returns an array of the keys of the Properties
sub propertyNames {
	my $self = shift;
	return keys %{$self->{properties}};
}

#	list() - Same as store() except that it doesn't include a header.
#		Meant for debugging use.
sub list {
	my $self = shift;
	my $file = shift or die "Config::Properties.list( file )";
	print $file "-- listing properties --";
	$self->reallySave( $file );
}

#	setPerlMode() - Sets the value (true/false) of the PERL_MODE parameter.
sub setPerlMode {
	my $self = shift;	
	my $mode = shift;
	return $self->{'PERL_MODE'} = (defined($mode) && $mode) ? 1 : 0;
}

#	perlMode() - Returns the current PERL_MODE setting (Default is false)
sub perlMode {
	my $self = shift;
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
for java.util.Properties at http://java.sun.com/j2se/1.3/docs/api/index.html.

When a property file is saved it is in the format "key=value" for each line. This can
be changed by setting the format attribute using either $object->format( $format_string ) or
$object->setFormat( $format_string ) (they do the same thing). The format string is fed to
printf and must contain exactly two %s format characters. The first will be replaced with
the key of the property and the second with the value. The string can contain no other
printf control characters, but can be anything else. A newline will be automatically added
to the end of the string. You an get the current format string either by using
$object->format() (with no arguments) or $object->getFormat().

If a true third parameter is passed to the constructor, the Config::Properties object
be created in PERL_MODE. This can be set at any time by passing a true or false value
into the setPerlMode() instance method. If in PERL_MODE, the behavior of the object
may be expanded, enhanced and/or just plain different than the Java API spec.

The following is a list of the current behavior changed under PERL_MODE:

* Ummm... nothing yet.

The current (true/false) value of PERL_MODE can be retrieved with the perlMode instance
variable.

=head1 AUTHOR

C<Config::Properties> was developed by Randy Jay Yarger.

=cut
