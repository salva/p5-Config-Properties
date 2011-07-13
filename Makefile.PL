use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile( 'NAME'	      => 'Config::Properties',
	       'VERSION_FROM' => 'lib/Config/Properties.pm',
	       'PREREQ_PM'    => { 'Test::More' => 0,
				   'File::Temp' => 0,
				   'Text::Wrap' => 2001.0929 } );
