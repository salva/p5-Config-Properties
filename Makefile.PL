use ExtUtils::MakeMaker;

WriteMakefile( 'NAME'	      => 'Config::Properties',
	       'VERSION_FROM' => 'Properties.pm',
	       'PREREQ_PM'    => { 'Test::More' => 0,
				   'File::Temp' => 0,
				   'Text::Wrap' => 0} );
