package Config::Properties;

use strict;
use warnings;

our $VERSION = '0.02';

our (%properties, $defaults);

#   new() - Constructor
#
#   The constructor can take one optional argument "$defaultProperties"
#   which is an instance of Config::Properties to be used as defaults
#   for this object.
sub new {
	my $proto = shift;
	my $defaultProperties = shift;
	
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);

	if ($defaultProperties) {
		$defaults = $defaultProperties;
	}
	return $self;
}

#	setProperty() - Set the value for a specific property
sub setProperty {
	my $self = shift;
	my $key = shift or die "Config::Properties.setProperty( key, value )";
	my $value = shift or die "Config::Properties.setProperty( key, value )";

	my $oldValue = $properties{ $key };
	$properties{ $key } = $value;
	return $oldValue;
}

#	getProperties() - Return a hashref of all of the properties
sub getProperties {
	return \%properties;
}

#	load() - Load the properties from a filehandle
sub load {
	my $self = shift;
	my $file = shift or die "Config::Properties.load( file )";
	while (<$file>) {
		$self->process_line($_, $file)
	}
}

#	process_line() - Recursive function used to parse a line from the
#					properties file.
sub process_line {
	#print "XXX" . join("::", @_) . "XXX\n";
	my $self = shift;
	my $line = shift or die "Config::Properties.process_line( line, file )";;
	my $file = shift or die "Config::Properties.process_line( line, file )";
	$line =~ s/\015?\012$//;
	$line =~ s/\\\\(?!$)/\\/g;
	return if $line =~ /^\s*(\#|\!)/;
	
	if ($line =~ /\\\s*$/ and not $line =~ s/\\\\$/\\/g) { 
		#print "Found match...";
		$line =~ s/\\\s*$//;
		my $newline = <$file>;
		$newline =~ s/^\s*//;
		$self->process_line($line . $newline, $file);
		return;
	}
	
	#print "XXX: " . $line . "\n";
	$line =~ /^\s*([^\s:=]+)(\s*|\s*(\:|\=|\s)\s*(.*?))$/;
	#print "1: $1 2: $2 3: $3 4: $4\n";
	die "Config::Properties.process_line: invalid property line" if not $1;

	$properties{ $1 } = ($4 || "");
}

#	reallySave() - Utility function that performs the actual saving of
#		the properties file to a filehandle.
sub reallySave {
	#print "XXX" . join("::", @_) . "XXX\n"; 
	my $self = shift;
	my $file = shift or die "Config::Properties.reallySave( file )";
	foreach (keys %properties) {
		print $file $_ . "=" . $properties{$_} . "\n";
	}
}

#	save() - Save the properties to a filehandle with the given header.
sub save {
	#print "XXX" . join("::", @_) . "XXX\n"; 
	my $self = shift;
	my $file = shift or die "Config::Properties.save( file, header )";
	my $header = shift or die "Config::Properties.save( file, header )";

	print $file "#" . $header . "\n" if $header;
	print $file "#" . localtime() . "\n";

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
	my $key = shift or die "Config::Properties.getProperty( key )";
	my $default = shift;
	my $value = $properties{ $key };
	if ($default and not $value) {
		return $default;
	}
	return $properties{ $key };
}

#	propertyName() - Returns an array of the keys of the Properties
sub propertyNames {
	return keys %properties;
}

#	list() - Same as store() except that it doesn't include a header.
#		Meant for debugging use.
sub list {
	my $self = shift;
	my $file = shift or die "Config::Properties.list( file )";
	print $file "-- listing properties --";
	$self->reallySave( $file );
}

1;
__END__

=head1 NAME

Config::Properties - read Java-style properties files

=head1 SYNOPSIS

use Config::Properties;

my $properties = new Properties();
$properties->load( $fileHandle );

$value = $properties->getProperty( $key );
$properties->setProperty( $key, $value );

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

When a property file is saved it is in the format "key=value" for each line.

=head1 AUTHOR

C<Config::Properties> was developed by Randy Jay Yarger.

=cut
