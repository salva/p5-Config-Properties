use ExtUtils::MakeMaker;

WriteMakefile( 'NAME'	      => 'Config::Properties',
	       'VERSION_FROM' => 'Properties.pm',
	       'PREREQ_PM'    => { 'Test::More' => 0 } );
