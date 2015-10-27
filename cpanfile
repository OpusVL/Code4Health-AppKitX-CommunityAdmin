requires "perl" => "5.014"; # FIXME: should be 5.20
requires "OpusVL::AppKit";

on 'build' => sub {
  requires "ExtUtils::MakeMaker" => "6.59";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
